import Fluent

struct migration_1_classmates_table: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Classmate.schema)
            .id()
            .field("username", .string, .required)
            .field("profileImageUrl", .string, .required)
            .field("url", .string, .required)
            .field("joinedAt", .datetime, .required)
            .field("description", .string, .required)
            .field("name", .string, .required)
            .field("friendIds", .array(of: .int), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Classmate.schema).delete()
    }
}