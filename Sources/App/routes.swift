import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "Online!"
    }

    app.get("api", "classmates") { req in
        return Classmate.query(on: req.application.db).all()
    }
}
