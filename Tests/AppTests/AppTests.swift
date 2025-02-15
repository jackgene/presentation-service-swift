@testable import App
import SwiftHamcrest
import XCTVapor

final class AppTests: XCTestCase {
    private func withApp(_ test: (Application) throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try test(app)
        }
        catch {
            app.asyncCommands.commands.forEach {
                if let presentationServiceCmd = $0.1 as? PresentationServiceCommand {
                    presentationServiceCmd.shutdown()
                }
            }
            try await app.asyncShutdown()
            throw error
        }
        app.asyncCommands.commands.forEach {
            if let presentationServiceCmd = $0.1 as? PresentationServiceCommand {
                presentationServiceCmd.shutdown()
            }
        }
        try await app.asyncShutdown()
    }
    
    func testLoadModerator() async throws {
        try await withApp { app in
            try app.test(.GET, "/moderator", afterResponse: { res in
                assertThat(res.status, equalTo(.ok))
                assertThat(res.body.string, containsString("<title>Moderator</title>"))
            })
        }
    }
    
    func testLoadTranscriber() async throws {
        try await withApp { app in
            try app.test(.GET, "/transcriber", afterResponse: { res in
                assertThat(res.status, equalTo(.ok))
                assertThat(res.body.string, containsString("<title>Transcriber</title>"))
            })
        }
    }
}
