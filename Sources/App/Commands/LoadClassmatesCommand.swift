import Vapor

struct LoadClassmatesCommand: Command {
    struct Signature: CommandSignature { }

    var help: String {
        "Loads all 100 Days of SwiftUI class members."
    }

    func run(using context: CommandContext, signature: Signature) throws {
        try context.application.eventLoopGroup.next().performWithTask {
            let twitter = Twitter(
                client: context.application.client,
                bearerToken: Environment.get("TWITTER_BEARER_TOKEN") ?? ""
            )

            do {
                let user_ids = try await self._find_100DaysOfSwift_users(console: context.console, twitter: twitter);
                var users = try await self._load_twitter_users(console: context.console, twitter: twitter, userIds: Array(user_ids))
                users = try await self._load_twitter_follows(console: context.console, twitter: twitter, users: users)

                var classmates = [Classmate]()
                for user in users {
                    let friends = user.follows?.filter { follow in
                        let connection = users[follow.id]
                        for possibleFriend in connection.follows ?? [UserFollow]() {
                            if possibleFriend.id == user.id {
                                return true
                            }
                        }
                        return false
                    }

                    var friend_ids = [Int]()
                    if let friends = friends {
                        friend_ids = friends.map {
                            $0.id
                        }
                    }
                    
                    classmates.append(
                        Classmate(
                            id: user.id,
                            username: user.username,
                            profileImageUrl: user.profileImageUrl,
                            url: user.url,
                            joinedAt: user.createdAt,
                            description: user.description,
                            name: user.name,
                            friendIds: friend_ids
                        )
                    )
                }
            } catch {
                print(error)
            }
        }.wait()
    }

    private func _find_100DaysOfSwift_users(console: Console, twitter: Twitter) async throws -> Set<Int> {
        console.print("1) Searching Twitter...", newLine: true)
        let tweets = try await twitter.searchTweets(using: [
            "query": "#100DaysOfSwiftUI -is:retweet",
            "tweet.fields": "author_id,created_at",
            "max_results": "100"
        ])

        var user_ids = Set<Int>()
        for tweet in tweets {
            user_ids.insert(tweet.authorId)
        }

        console.clear(lines: 1)
        console.print("1) Searching Twitter. Done.", newLine: true)

        return user_ids
    }

    private func _load_twitter_users(console: Console, twitter: Twitter, userIds: [Int]) async throws -> [User] {
        console.print("2) Loading users...", newLine: true)
        let users = try await twitter.getUsersBy(ids: userIds)
        console.clear(lines: 1)
        console.print("2) Loading users. Done.", newLine: true)
        return users
    }

    private func _load_twitter_follows(console: Console, twitter: Twitter, users: [User]) async throws -> [User] {
        console.print("3) Loading user follows... (0/\(users.count))", newLine: true)
        var updated_users = [User]()
        for (index, user) in users.enumerated() {
            console.clear(lines: 1)
            console.print("3) Loading user follows... (\(index + 1)/\(users.count))", newLine: true)
            let follows = try await twitter.getUserFollowsBy(userId: user.id)
            var copy = user
            copy.follows = follows
            updated_users.append(copy)
        }
        console.clear(lines: 1)
        console.print("3) Loading user follows. Done.", newLine: true)

        return updated_users
    }
    
}