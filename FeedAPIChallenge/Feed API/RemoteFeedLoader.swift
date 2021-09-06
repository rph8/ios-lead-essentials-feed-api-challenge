//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private struct FeedImageStruct: Decodable {
		var imageId: UUID
		var imageUrl: URL
		var imageDesc: String?
		var imageLoc: String?

		var feedImage: FeedImage {
			.init(id: imageId, description: imageDesc, location: imageLoc, url: imageUrl)
		}
	}

	private struct FeedImageResponse: Decodable {
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
			guard self != nil else { return }

			guard let (data, httpResponse) = try? result.get() else {
				return completion(.failure(Error.connectivity))
			}

			guard httpResponse.statusCode == 200 else {
				return completion(.failure(Error.invalidData))
			}

			completion(RemoteFeedLoader.map(data, from: httpResponse))
		}
	}

	private static func map(_ data: Data, from httpResponse: HTTPURLResponse) -> FeedLoader.Result {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		guard let response = try? decoder.decode(FeedImageResponse.self, from: data) else {
			return .failure(Error.invalidData)
		}

		return .success(response.items.map(\.feedImage))
	}
}
