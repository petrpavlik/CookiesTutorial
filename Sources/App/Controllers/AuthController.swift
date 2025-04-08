import Fluent
import Vapor

struct AuthController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        auth.get("login", use: self.login)
        auth.post("login", use: self.login)

        auth.get("register", use: self.register)
        auth.post("register", use: self.register)
    }

    @Sendable
    func login(req: Request) async throws -> Response {

        var errorMessage: String?

        struct Query: Content {
            let next: URI?
        }

        struct LoginRequestBody: Content, Validatable {
            let email: String
            let password: String

            static func validations(_ validations: inout Vapor.Validations) {
                validations.add("email", as: String.self, is: .email)
                validations.add("password", as: String.self, is: !.empty)
            }
        }

        if req.method == .POST {
            do {

                let query = try req.query.decode(Query.self)

                try LoginRequestBody.validate(content: req)
                let data = try req.content.decode(LoginRequestBody.self)

                guard
                    let user = try await User.query(on: req.db)
                        .filter(\.$email == data.email.lowercased())
                        .first()
                else {
                    throw Abort(.unauthorized, reason: "Invalid email or password")
                }

                guard try Bcrypt.verify(data.password, created: user.passwordHash) else {
                    throw Abort(.unauthorized, reason: "Invalid email or password")
                }

                req.session.authenticate(user)

                // make sure this cannot redirect to a different domain
                return req.redirect(to: query.next?.path ?? "/me")

            } catch {
                errorMessage = "\(error.localizedDescription)"
            }

        }

        return try await req.view.render("login", ["error": errorMessage]).encodeResponse(for: req)
    }

    @Sendable
    func register(req: Request) async throws -> Response {

        var errorMessage: String?

        struct RegisterRequestBody: Content, Validatable {
            let email: String
            let password: String

            static func validations(_ validations: inout Vapor.Validations) {
                validations.add("email", as: String.self, is: .email)
                validations.add("password", as: String.self, is: .count(4...))
            }
        }

        if req.method == .POST {

            do {
                try RegisterRequestBody.validate(content: req)
                let data = try req.content.decode(RegisterRequestBody.self)

                let user = User(
                    email: data.email.lowercased(), passwordHash: try Bcrypt.hash(data.password))
                try await user.save(on: req.db)

                req.session.authenticate(user)
                req.session.data["test"] = "test value"

                return req.redirect(to: "/me")

            } catch {
                errorMessage = "\(error.localizedDescription)"
            }
        }

        return try await req.view.render("register", ["error": errorMessage]).encodeResponse(
            for: req)
    }
}
