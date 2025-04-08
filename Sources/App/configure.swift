import Fluent
import FluentSQLiteDriver
import Leaf
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // you probably want to use PostgreSQL for production
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)

    app.sessions.use(.fluent)

    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateUser())

    app.sessions.configuration.cookieName = "cookies_tutorial_vapor"

    // this is important for the cookie to be secure
    app.sessions.configuration.cookieFactory = { sessionID in
        .init(
            string: sessionID.string,  // TODO: explain how Vapor encodes the user ID exactly
            maxAge: 60 * 60 * 24 * 7,  // expire the cookie after 7 days
            domain: nil,  // By default, it's the host that set the cookie (e.g., app.example.com). To support subdomains, you need to set it explicitly to `.example.com`.
            path: "/",  // add cokkies to any path, you can set it to `/me` if you want to limit the cookie to that path
            isSecure: true,  // transfer cookies only over https, browsers treat localhost as an exception so dev will work
            isHTTPOnly: true,  // cookies are not accessible from JS and are a malicious injected JS script XSS cannot do `document.cookie` to steal them
            sameSite: .lax)  // Prevents CSRF attacks. This stuff is mysterious and important so you should read about it to not get pwned.
    }

    app.views.use(.leaf)

    app.middleware.use(app.sessions.middleware)

    try await app.autoMigrate()

    // register routes
    try routes(app)
}
