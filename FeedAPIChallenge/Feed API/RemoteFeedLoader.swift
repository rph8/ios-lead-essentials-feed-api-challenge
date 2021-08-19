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

		enum CodingKeys: String, CodingKey {
			case imageId = "image_id"
			case imageUrl = "image_url"
			case imageDesc = "image_desc"
			case imageLoc = "image_loc"
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

	private func feedImages(for response: FeedImageResponse) -> [FeedImage] {
		return response.items.map {
			FeedImage(id: $0.imageId,
			          description: $0.imageDesc,
			          location: $0.imageLoc,
			          url: $0.imageUrl)
		}
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: self.url) { [weak self] result in
			guard self != nil else { return }

			guard let (data, httpResponse) = try? result.get() else {
				return completion(.failure(Error.connectivity))
			}

			let decoder = JSONDecoder()
			guard httpResponse.statusCode == 200,
			      let feedImageResponse = try? decoder.decode(FeedImageResponse.self, from: data),
			      let self = self else {
				return completion(.failure(Error.invalidData))
			}

			completion(.success(self.feedImages(for: feedImageResponse)))
		}
	}
}
