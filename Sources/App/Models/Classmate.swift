import Foundation
import Vapor
import Fluent

final class Classmate: Model, Content {
    static let schema = "classmates"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "twitterId") var twitterId: Int
    @Field(key: "username") var username: String
    @Field(key: "profileImageUrl") var profileImageUrl: String
    @Field(key: "url") var url: String
    @Field(key: "joinedAt") var joinedAt: Date
    @Field(key: "description") var description: String
    @Field(key: "name") var name: String
    @Field(key: "friendIds") var friendIds: [Int]

    init() { }

    init(
        twitterId: Int,
        username: String,
        profileImageUrl: String,
        url: String,
        joinedAt: Date,
        description: String,
        name: String,
        friendIds: [Int]
    ) {
        self.twitterId = twitterId
        self.username = username
        self.profileImageUrl = profileImageUrl
        self.url = url
        self.joinedAt = joinedAt
        self.description = description
        self.name = name
        self.friendIds = friendIds
    }

}
