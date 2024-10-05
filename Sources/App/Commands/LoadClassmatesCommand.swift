import Vapor

struct LoadClassmatesCommand: Command {
    struct Signature: CommandSignature { }

    var help: String {
        "Loads and persists all recent 100 Days of SwiftUI class members."
    }

    func run(using context: CommandContext, signature: Signature) throws {
        let console = context.console
        let database = context.application.db
        let twitter = Twitter(
            client: context.application.client,
            bearerToken: Environment.get("TWITTER_BEARER_TOKEN") ?? ""
        )

        try context.application.eventLoopGroup.next().performWithTask {
            do {
                console.print("1) Searching Twitter...", newLine: true)
                let user_ids = try await self._find_relevant_users(twitter: twitter)
                console.clear(lines: 1)
                console.print("1) Searching Twitter. Done.", newLine: true)

                console.print("2) Loading users...", newLine: true)
                var users = try await twitter.getUsersBy(ids: Array(user_ids))
                console.clear(lines: 1)
                console.print("2) Loading users. Done.", newLine: true)

                console.print("3) Loading user follows... (0/\(users.count))", newLine: true)
                for index in 0..<users.count {
                    console.clear(lines: 1)
                    console.print("3) Loading user follows... (\(index + 1)/\(users.count))", newLine: true)
                    users[index].follows = try await twitter.getUserFollowsBy(userId: users[index].id)
                }
                console.clear(lines: 1)
                console.print("3) Loading user follows. Done.", newLine: true)

                let classmates = self._convert_to_classmates(users: users)
                try await Classmate.query(on: database).delete()
                try await classmates.create(on: database)
            } catch {
                print(error)
            }
        }.wait()
    }

    private func _find_relevant_users(twitter: Twitter) async throws -> Set<Int> {
        let tweets = try await twitter.searchTweets(using: [
            "query": "#100DaysOfSwiftUI -is:retweet",
            "tweet.fields": "author_id,created_at",
            "max_results": "100"
        ])

        var user_ids = Set<Int>()
        for tweet in tweets {
            user_ids.insert(tweet.authorId)
        }

        return user_ids
    }
    
    private func _convert_to_classmates(users: [TwitterUser]) -> [Classmate] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        
        var classmates = [Classmate]()
        for user in users {
            let friends = user.follows?.filter { follow in
                guard let connection = users.first(where: { $0.id == follow.id }) else {
                    return false
                }

                for possibleFriend in connection.follows ?? [UserFollow]() {
                    if possibleFriend.id == user.id {
                        return true
                    }
                }
                
                return false
            } ?? [UserFollow]()
            
            let friend_ids: [Int] = friends.map {
                $0.id
            }
            
            classmates.append(
                Classmate(
                    twitterId: user.id,
                    username: user.username,
                    profileImageUrl: user.profileImageUrl,
                    url: user.url,
                    joinedAt: formatter.date(from: user.createdAt) ?? Date(),
                    description: user.description,
                    name: user.name,
                    friendIds: friend_ids
                )
            )
        }
        
        return classmates
    }
}
