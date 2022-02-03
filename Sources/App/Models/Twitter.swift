import Vapor

struct TwitterResponse<T: Codable>: Content {
    var data: [T]
    var meta: TwitterMeta?
}

struct TwitterMeta: Content {
    var next_token: String?
}

struct Tweet: Content {
    enum CodingKeys: CodingKey {
        case text, author_id
    }

    var text: String
    var authorId: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.text = try container.decode(String.self, forKey: .text)
        let author_id = try container.decode(String.self, forKey: .author_id)
        self.authorId = Int(author_id) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.text, forKey: .text)

        let author_id = String(self.authorId)
        try container.encode(author_id, forKey: .author_id)
    }
}

struct User: Content {
    enum CodingKeys: CodingKey {
        case id, username, profile_image_url, url, created_at, description, name
    }

    var id: Int
    var username: String
    var profileImageUrl: String
    var url: String
    var createdAt: String
    var description: String
    var name: String
    var follows: [UserFollow]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        self.id = Int(id) ?? 0

        self.username = try container.decode(String.self, forKey: .username)
        self.profileImageUrl = try container.decode(String.self, forKey: .profile_image_url)
        self.url = try container.decode(String.self, forKey: .url)
        self.createdAt = try container.decode(String.self, forKey: .created_at)
        self.description = try container.decode(String.self, forKey: .description)
        self.name = try container.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let id = String(self.id)
        try container.encode(id, forKey: .id)

        try container.encode(self.username, forKey: .username)
        try container.encode(self.profileImageUrl, forKey: .profile_image_url)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.createdAt, forKey: .created_at)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.name, forKey: .name)
    }
}

struct UserFollow: Content {
    enum CodingKeys: CodingKey {
        case id, username, name
    }

    var id: Int
    var username: String
    var name: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        self.id = Int(id) ?? 0

        self.username = try container.decode(String.self, forKey: .username)
        self.name = try container.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let id = String(self.id)
        try container.encode(id, forKey: .id)

        try container.encode(self.username, forKey: .username)
        try container.encode(self.name, forKey: .name)
    }
}

enum TwitterError: Error {
    case requestError(HTTPStatus, String), decodeError, rateLimitError
}

struct Twitter {
    let client: Client
    let bearerToken: String

    // It takes 15 minutes for Twitter's rate limits to reset
    let waitTimeSeconds = 900
    let twitterApiUrl = "https://api.twitter.com/2"

    func searchTweets(using fields: [String: String]) async throws -> [Tweet] {
        var search_fields = fields
        var tweets = [Tweet]()
        var next_token = ""
        repeat {
            if next_token != "" {
                search_fields["next_token"] = next_token
            }

            let response: TwitterResponse<Tweet> = try await self.search(relativePath: "/tweets/search/recent", fields: search_fields)
            tweets = tweets + response.data
            next_token = response.meta?.next_token ?? ""
        } while next_token != ""

        return tweets
    }

    func getUsersBy(ids: [Int]) async throws -> [User] {
        var users = [User]()
        let batches = ids.chunked(into: 100)
        for batch in batches {
            let ids_converted = batch.map{ String($0) }
            let ids_joined = ids_converted.joined(separator: ",")

            let response: TwitterResponse<User> = try await self.search(relativePath: "/users", fields: [
                "ids": ids_joined,
                "user.fields": "id,username,profile_image_url,url,created_at,description,name"
            ])

            users = users + response.data
        }

        return users
    }

    func getUserFollowsBy(userId: Int) async throws -> [UserFollow] {
        var search_fields = ["max_results": "1000"]
        var follows = [UserFollow]()
        var next_token = ""
        repeat {
            if next_token != "" {
                search_fields["pagination_token"] = next_token
            }

            let response: TwitterResponse<UserFollow> = try await self.search(relativePath: "/users/\(userId)/following", fields: search_fields)
            follows = follows + response.data
            next_token = response.meta?.next_token ?? ""
        } while next_token != ""

        return follows
    }

    fileprivate func search<T>(relativePath: String, fields: [String: String], retryCount: Int = 0) async throws -> TwitterResponse<T> {
        let res = try await client.get("\(self.twitterApiUrl)\(relativePath)") { req in
            try req.query.encode(fields)
            let auth = BearerAuthorization(token: self.bearerToken)
            req.headers.bearerAuthorization = auth
        }

        if res.status == .tooManyRequests && retryCount < 2 {
            sleep(UInt32(self.waitTimeSeconds))
            let retries = retryCount + 1
            return try await self.search(relativePath: relativePath, fields: fields, retryCount: retries)
        }

        if res.status != .ok {
            var body = ""
            if let payload = res.body {
                body = String(data: Data(payload.readableBytesView), encoding: .utf8) ?? ""
            }

            throw TwitterError.requestError(res.status, body)
        }

        let response: TwitterResponse<T>
        do {
            response = try res.content.decode(TwitterResponse<T>.self)
        } catch {
            var body = ""
            if let payload = res.body {
                body = String(data: Data(payload.readableBytesView), encoding: .utf8) ?? ""
            }
            print(body)
            throw TwitterError.decodeError
        }

        return response
    }
}