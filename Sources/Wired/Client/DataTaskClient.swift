import Foundation

public final class DataTaskClient {
    public typealias Completion<T> = (Result<T, Error>) -> Void

    /// The shared object of `DataTaskClient`.
    public static let shared: DataTaskClient = DataTaskClient(configuration: .default)

    private let configuration: URLSessionConfiguration

    private lazy var session: URLSession = URLSession(configuration: configuration)

    public init(configuration: URLSessionConfiguration) {
        self.configuration = configuration
    }

    /// Retrieves the contents of a request, transforms the obtained data into a specific object, and calls a handler upon completion.
    /// - Parameters:
    ///   - request: An object that addresses both the generation of `URLRequest` and conversion from `Data` into an `Output` value.
    ///   - completion: A completion handler.
    @discardableResult
    public func retrieveResponse<T>(request: T, completion: @escaping Completion<T.Output>) -> URLSessionDataTask?
    where T: RequestBuildable & ResponseConvertible
    {
        return retrieveResponse(request: request, dataConverter: request, completion: completion)
    }

    /// Retrieves the contents of a request, transforms the obtained data into a specific object, and calls a handler upon completion.
    /// - Parameters:
    ///   - request: An object that addresses the generation of `URLRequest`.
    ///   - dataConverter: An object that transforms `Data` into an `Output` value.
    ///   - completion: A completion handler.
    @discardableResult
    public func retrieveResponse<T, U>(request: T, dataConverter: U, completion: @escaping Completion<U.Output>) -> URLSessionDataTask?
    where T: RequestBuildable,
          U: ResponseConvertible
    {
        return retrieveData(request: request) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                switch dataConverter.convert(data: data) {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let output):
                    completion(.success(output))
                }
            }
        }
    }

    /// Retrieves the contents of a request and calls a handler upon completion.
    /// - Parameters:
    ///   - request: An object that addresses the generation of `URLRequest`.
    ///   - completion: A completion handler.
    @discardableResult
    public func retrieveData<T>(request: T, completion: @escaping Completion<Data>) -> URLSessionDataTask?
    where T: RequestBuildable
    {
        switch request.buildRequest() {
        case .failure(let error):
            completion(.failure(error))
            return nil
        case .success(let urlRequest):
            let dataTask = session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    return completion(.failure(LocalError.sessionError(error)))
                }
                guard let response = response else {
                    return completion(.failure(LocalError.noResponse))
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    return completion(.failure(LocalError.notHttpResponse))
                }
                guard httpResponse.statusCode == 200 else {
                    return completion(.failure(LocalError.httpStatus(code: httpResponse.statusCode)))
                }
                guard let data = data else {
                    return completion(.failure(LocalError.noData))
                }
                return completion(.success(data))
            }

            dataTask.resume()
            return dataTask
        }
    }
}
