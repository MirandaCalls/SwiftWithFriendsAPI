import Vapor

struct TwitterResponse<T: Codable>: Content {
    var data: [T]
    var meta: TwitterMeta
}

struct TwitterMeta: Content {
    var next_token: String?
}

struct Tweet: Content {
    var text: String
    var author_id: String
}

enum TwitterError: Error {
    case requestError, decodeError
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

            let res = try await client.get("\(self.twitterApiUrl)/tweets/search/recent") { req in
                try req.query.encode(search_fields)
                let auth = BearerAuthorization(token: self.bearerToken)
                req.headers.bearerAuthorization = auth
            }

            if res.status != .ok {
                throw TwitterError.requestError
            }

            let response: TwitterResponse<Tweet>
            do {
                response = try res.content.decode(TwitterResponse<Tweet>.self)
            } catch {
                throw TwitterError.decodeError
            }

            tweets = tweets + response.data
            next_token = response.meta.next_token ?? ""
        } while next_token != ""

        return tweets
    }

}