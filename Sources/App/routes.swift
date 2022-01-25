import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "Online!"
    }

    app.get("/classmates") { req -> String in
        return "TODO"
    }
}
