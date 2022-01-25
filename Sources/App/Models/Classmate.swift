import Vapor
import Foundation

struct Classmate: Content {
    var id: Int
    var username: String
    var profileImageUrl: String
    var url: String
    var joinedAt: Date
    var description: String
    var name: String
    var friendIds: [Int]
}