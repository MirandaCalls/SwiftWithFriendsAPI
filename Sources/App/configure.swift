import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.commands.use(LoadClassmatesCommand(), as: "load-classmates")

    app.databases.use(
        .postgres(
            hostname: Environment.get("DB_HOSTNAME")!,
            username: Environment.get("DB_USERNAME")!,
            password: Environment.get("DB_PASSWORD")!,
            database: "swiftwithfriends"
        ),
        as: .psql
    )
    
    app.migrations.add(migration_1_classmates_table())

    // register routes
    try routes(app)
}
