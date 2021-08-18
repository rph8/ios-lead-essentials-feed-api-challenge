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

			guard case .success = result else {
				completion(.failure(Error.connectivity))
				return
			}

			guard let (data, httpResponse) = try? result.get(), httpResponse.statusCode == 200 else {
				completion(.failure(Error.invalidData))
				return
			}

			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase
			guard let response = try? decoder.decode(FeedImageResponse.self, from: data) else {
				return completion(.failure(Error.invalidData))
			}
			
			let feedImages = response.items.map {
				FeedImage(id: $0.image_id,
						  description: $0.image_desc,
						  location: $0.image_loc,
						  url: $0.image_url)
			}
			completion(.success(feedImages))
		}
	}
}
