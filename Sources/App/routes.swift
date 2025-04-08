import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    // Create protected route group which requires user auth.
    let protected = app.routes.grouped([
        User.sessionAuthenticator(),
        User.redirectMiddleware { req -> String in
            return "/auth/login?next=\(req.url.path)"
        },
    ])

    // Add GET /me route for reading user's email.
    protected.get("me") { req -> View in
        let email = try req.auth.require(User.self).email
        return try await req.view.render("me", ["email": email])
    }

    // Making this a GET would be vulnerable to CSRF attacks. GET request should not have side effects.
    protected.delete("signout") { req -> String in
        req.session.destroy()
        return "signed out"
    }

    try app.register(collection: AuthController())
}
