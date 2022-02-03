import Vapor
import Fluent

struct ClassmatesController {
    let db: Database

    func getAll() async throws -> [Classmate] {
        return try await Classmate.query(on: self.db).all()
    }
    
    func insert(records: [Classmate]) async throws {
        try await records.create(on: self.db)
    }

    func deleteAll() async throws {
        try await Classmate.query(on: self.db).delete()
    }
}