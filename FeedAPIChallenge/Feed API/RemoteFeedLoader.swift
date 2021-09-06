//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	struct FeedImageStruct: Codable {
		var imageId: UUID
		var imageUrl: URL
		var imageDesc: String?
		var imageLoc: String?

		var feedImage: FeedImage {
			.init(id: imageId, description: imageDesc, location: imageLoc, url: imageUrl)
		}
	}

	struct FeedImageResponse: Codable {
		var items: [FeedImageStruct]
	}

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
		client.get(from: self.url) { [weak self] result in
			guard let _ = self else { return }

			guard let (data, httpResponse) = try? result.get() else {
				return completion(.failure(Error.connectivity))
			}

			guard httpResponse.statusCode == 200 else {
				return completion(.failure(Error.invalidData))
			}

			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase
			guard let response = try? decoder.decode(FeedImageResponse.self, from: data) else {
				return completion(.failure(Error.invalidData))
			}

			let feedImages = response.items.map(\.feedImage)
			completion(.success(feedImages))
		}
	}
}
