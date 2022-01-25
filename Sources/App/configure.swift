import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.commands.use(LoadClassmatesCommand(), as: "load-classmates")

    // register routes
    try routes(app)
}
