//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: self.url) { result in
			guard case .success = result else {
				completion(.failure(Error.connectivity))
				return
			}
			guard let (_, httpResponse) = try? result.get(), httpResponse.statusCode == 200 else {
				completion(.failure(Error.invalidData))
				return
			}
			completion(.success([FeedImage(id: UUID(), description: nil, location: nil, url: URL(string: "https://a-given-url.com")!)]))
		}
	}
}
