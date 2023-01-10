@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testLoadModerator() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
//        defer { (app.commands.defaultCommand as? PresentationServiceCommand)?.shutdown() }
        try configure(app)

        try app.test(.GET, "/moderator", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertContains(res.body.string, "<title>Moderator</title>")
        })
    }
}
