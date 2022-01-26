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
                let tweets = try await twitter.searchTweets(using: [
                    "query": "#100DaysOfSwiftUI -is:retweet",
                    "tweet.fields": "author_id,created_at",
                    "max_results": "100"
                ])

                for tweet in tweets {
                    context.console.print(tweet.text, newLine: true)
                }
            } catch {
                print(error)
            }
        }.wait()
    }
}