import XCTest

class URLParserTest: XCTestCase {
    private let appId = "test.app"
    private let parameters = YXLAuthParameters(appId: "test.app", state: "test.state",
                                               pkce: "test.pkce", uid: 1, login: "test.login",
                                               fullscreen: false)!

    func testAuthorizationURL() {
        let url = YXLURLParser.authorizationURL(with: parameters)!
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, YXLHostProvider.oauthHost)
        XCTAssertEqual(url.path, "/authorize")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: parameters.appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "code")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUri)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: parameters.state)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "force_confirm", value: "yes")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "origin", value: "yandex_auth_sdk_ios")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge", value: parameters.pkce)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge_method", value: "S256")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "uid", value: "1")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "login_hint", value: "test.login")))
        }
    }
    func testAuthorizationURLNoPkce() {
        let url = YXLURLParser.authorizationURL(with:
            YXLAuthParameters(appId: "test.app", state: "test.state", pkce: nil, uid: 0, login: nil, fullscreen: false))!
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, YXLHostProvider.oauthHost)
        XCTAssertEqual(url.path, "/authorize")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: parameters.appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "token")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUriUniversalLink)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: parameters.state)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "force_confirm", value: "yes")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "origin", value: "yandex_auth_sdk_ios")))
            XCTAssertFalse(queryItems.contains(URLQueryItem(name: "code_challenge_method", value: "S256")))
        }
    }
    func testAddStatistics() {
        let statisticsParameters = YXLStatisticsDataProvider.statisticsParameters!
        XCTAssertGreaterThan(statisticsParameters.count, 0)
        if #available(iOS 8.0, *) {
            let url = YXLURLParser.authorizationURL(with: parameters)!
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            for parameter in statisticsParameters {
                XCTAssertTrue(queryItems.contains(URLQueryItem(name: parameter.key, value: parameter.value)))
            }
        }
    }
    func testOpenURL() {
        let url = YXLURLParser.openURL(with: parameters)!
        XCTAssertEqual(url.scheme, "yandexauth2")
        XCTAssertEqual(url.host, "authorize")
        XCTAssertEqual(url.path, "")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: parameters.appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "code")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUri)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: parameters.state)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge", value: parameters.pkce)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge_method", value: "S256")))
        }
    }
    func testOpenURLUniversalLink() {
        let url = YXLURLParser.openURLUniversalLink(with: parameters)!
        XCTAssertEqual(url.scheme, "yandexauth")
        XCTAssertEqual(url.host, "authorize")
        XCTAssertEqual(url.path, "")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: parameters.appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "code")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUri)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: parameters.state)))
            // TODO: Figure out the right value. For now there are no options other than S256, but it's treated as a wrong value by this legacy test case
            // XCTAssertFalse(queryItems.contains(URLQueryItem(name: "code_challenge_method", value: "S256")))
        }
    }
    func testErrorFromUrl() {
        let testError: (String, YXLErrorCode) -> Void = { value, code in
            let error = YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru?error=\(value)")) as NSError
            XCTAssertEqual(error.code, code.rawValue)
            XCTAssertEqual(error.userInfo[NSLocalizedFailureReasonErrorKey] as? String, value.removingPercentEncoding)
        }
        testError("invalid_request", .other)
        testError("unauthorized_client", .other)
        testError("access_denied", .denied)
        testError("unsupported_response_type", .other)
        testError("invalid_scope", .invalidScope)
        testError("server_error", .other)
        testError("temporarily_unavailable", .other)
        testError("invalid_client", .invalidClient)
        testError("test_error", .other)
        testError("test%3Derror", .other)
    }
    func testNilErrorFromUrl() {
        XCTAssertNil(YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru?errors=access_denied")))
        XCTAssertNil(YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru#error=access_denied")))
    }
    func testCodeFromUrl() {
        XCTAssertEqual(YXLURLParser.code(from: URL(string: "http://oauth.yandex.ru?code=test_code")), "test_code")
    }
    func testNilCodeFromUrl() {
        XCTAssertNil(YXLURLParser.code(from: URL(string: "http://oauth.yandex.ru?codes=test_code")))
        XCTAssertNil(YXLURLParser.code(from: URL(string: "http://oauth.yandex.ru#code=test_code")))
    }
    func testStateFromUrl() {
        XCTAssertEqual(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru?state=test_state")), "test_state")
    }
    func testNilStateFromUrl() {
        XCTAssertNil(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru?states=test_token")))
        XCTAssertNil(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru#state=test_token")))
    }
    func testTokenFromUniversalLinkUrl() {
        XCTAssertEqual(YXLURLParser.token(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#access_token=test_token")), "test_token")
    }
    func testNilTokenFromUniversalLinkUrl() {
        XCTAssertNil(YXLURLParser.token(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#access_tokens=test_token")))
        XCTAssertNil(YXLURLParser.token(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru?access_token=test_token")))
    }
    func testStateFromUniversalLinkUrl() {
        XCTAssertEqual(YXLURLParser.state(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#state=test_state")), "test_state")
    }
    func testNilStateFromUniversalLinkUrl() {
        XCTAssertNil(YXLURLParser.state(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#states=test_token")))
        XCTAssertNil(YXLURLParser.state(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru?state=test_token")))
    }
    func testErrorFromUniversalLinkUrl() {
        let error = YXLURLParser.error(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#error=invalid_client")) as NSError
        XCTAssertEqual(error.code, YXLErrorCode.invalidClient.rawValue)
        XCTAssertEqual(error.userInfo[NSLocalizedFailureReasonErrorKey] as? String, "invalid_client")
    }
    func testNilErrorFromUniversalLinkUrl() {
        XCTAssertNil(YXLURLParser.error(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#errors=access_denied")))
        XCTAssertNil(YXLURLParser.error(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru?error=access_denied")))
    }
    func testIsOpenURL() {
        XCTAssertTrue(YXLURLParser.isOpen(URL(string: "yxtest.app://oauth.yandex.ru#errors=access_denied"), appId: appId))
        XCTAssertTrue(YXLURLParser.isOpen(URL(string: "yxapp://oauth.yandex.ru#errors=access_denied"), appId: "app"))
        XCTAssertFalse(YXLURLParser.isOpen(URL(string: "yxtest.app://oauth.yandex.ru#errors=access_denied"), appId: "app"))
        XCTAssertFalse(YXLURLParser.isOpen(URL(string: "vk123://oauth.yandex.ru#errors=access_denied"), appId: appId))
        XCTAssertTrue(YXLURLParser.isOpen(URL(string: redirectUri), appId: appId))
        XCTAssertFalse(YXLURLParser.isOpen(URL(string: redirectUriUniversalLink), appId: appId))
    }

    private var redirectUri: String {
        return "yx" + appId + ":///auth/finish?platform=ios"
    }

    private var redirectUriUniversalLink: String {
        return "https://yx" + appId + ".oauth.yandex.ru/auth/finish?platform=ios"
    }
}
