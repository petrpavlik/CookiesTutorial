import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() {}

    init(id: UUID? = nil, email: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
    }
}

// Allow this model to be persisted in sessions.
extension User: ModelSessionAuthenticatable {}

// struct User: Authenticatable {
//     var email: String
// }

// extension User: SessionAuthenticatable {
//     var sessionID: String {
//         self.email
//     }
// }

// struct UserSessionAuthenticator: AsyncSessionAuthenticator {
//     typealias User = App.User
//     func authenticate(sessionID: String, for request: Request) async throws {
//         request.logger.info("UserSessionAuthenticator: found sessionID \(sessionID)")
//         let user = User(email: sessionID)
//         request.auth.login(user)
//     }
// }

// struct FakeAuthenticator: AsyncRequestAuthenticator {
//     func authenticate(request: Vapor.Request) async throws {
//         request.logger.info("FakeAuthenticator: logging in user hello@vapor.codes")
//         let user = User(email: "hello@vapor.codes")
//         request.auth.login(user)
//     }

// }
