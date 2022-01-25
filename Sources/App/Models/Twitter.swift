import Vapor

struct Tweet: Content {
    var text: String
}

struct Twitter {
    let client: Client
    let bearerToken: String

    // It takes 15 minutes for Twitter's rate limits to reset
    let waitTimeSeconds = 900

    func searchTweets() async throws -> [Tweet] {
        let res = try await client.get("https://api.twitter.com/2/tweets/search/recent") { req in
            try req.query.encode([
                "query": "#100DaysOfSwiftUI -is:retweet",
                "tweet.fields": "author_id,created_at",
                "max_results": "100"
            ])

            let auth = BearerAuthorization(token: self.bearerToken)
            req.headers.bearerAuthorization = auth
        }

        switch res.status {
            case .ok:
                print(res.content)
                return []
            default:
                return []
        }
        
        // TODO

        // Notes:
        // 
        // Loop until next token is empty
    }

}