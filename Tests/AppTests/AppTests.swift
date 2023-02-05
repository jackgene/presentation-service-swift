@testable import App
import SwiftHamcrest
import XCTVapor

final class AppTests: XCTestCase {
    func testLoadModerator() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.GET, "/moderator", afterResponse: { res in
            assertThat(res.status, equalTo(.ok))
            assertThat(res.body.string, containsString("<title>Moderator</title>"))
        })
    }
    
    func testLoadTranscriber() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "/transcriber", afterResponse: { res in
            assertThat(res.status, equalTo(.ok))
            assertThat(res.body.string, containsString("<title>Transcriber</title>"))
        })
    }
}
