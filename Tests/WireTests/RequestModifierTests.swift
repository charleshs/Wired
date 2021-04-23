import XCTest
@testable import Wire

final class RequestModifierTests: XCTestCase {
    func testInit() {
        let requestModifier = RequestModifier { req -> Result<URLRequest, Error> in
            var req = req
            req.httpMethod = HTTP.Method.post.rawValue
            return .success(req)
        }
        let origRequest = URLRequest(url: .demo)
        let newRequest = try? requestModifier.modify(origRequest).get()
        XCTAssertEqual(origRequest.url, newRequest?.url)
        XCTAssertEqual(origRequest.httpMethod, "GET")
        XCTAssertEqual(newRequest?.httpMethod, "POST")
    }

    func testFailure() {
        let requestModifier = RequestModifier(StubModifier())
        XCTAssertThrowsError(try requestModifier.modify(URLRequest(url: .demo)).get(), "") { error in
            XCTAssertEqual(error as? TestError, .failure)
        }
    }
}

private struct StubModifier: RequestModifiable {
    func modify(_ request: URLRequest) -> Result<URLRequest, Error> {
        return .failure(TestError.failure)
    }
}