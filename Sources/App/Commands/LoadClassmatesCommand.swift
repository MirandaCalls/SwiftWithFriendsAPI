import Vapor

struct LoadClassmatesCommand: Command {
    struct Signature: CommandSignature { }

    var help: String {
        "Loads all 100 Days of SwiftUI class members."
    }

    func run(using context: CommandContext, signature: Signature) throws {
        let twitter = Twitter(
            client: context.application.client,
            bearerToken: Environment.get("TWITTER_BEARER_TOKEN") ?? ""
        )
        Task.runDetached(priority: TaskPriority.medium) {
            do {
                try await twitter.searchTweets()
            } catch {
                print(error)
            }
        }
    }
}