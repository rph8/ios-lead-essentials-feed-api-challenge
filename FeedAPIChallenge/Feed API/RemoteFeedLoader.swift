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

			guard let (data, httpResponse) = try? result.get(), httpResponse.statusCode == 200 else {
				completion(.failure(Error.invalidData))
				return
			}

			guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary, let itemsArr = jsonDict["items"] as? NSArray else {
				completion(.failure(Error.invalidData))
				return
			}

			// Validate JSON object structure
			let isValid = itemsArr
				.map { item -> Bool in
					guard let dict = item as? NSDictionary else { return false }
					return dict["image_id"] != nil && dict["image_url"] != nil
				}
				.reduce(true) { previous, next in previous && next }

			guard isValid else {
				completion(.failure(Error.invalidData))
				return
			}

			// Convert the JSON to objects
			let feedImages = itemsArr.map { item -> FeedImage? in
				guard let dict = item as? NSDictionary,
				      let imageIdString = dict["image_id"] as? String,
				      let imageId = UUID(uuidString: imageIdString),
				      let urlString = dict["image_url"] as? String,
				      let url = URL(string: urlString) else { return nil }
				return FeedImage(id: imageId,
				                 description: dict["image_desc"] as? String,
				                 location: dict["image_loc"] as? String,
				                 url: url)
			}
			.reduce([]) { previous, feedImage -> [FeedImage] in
				guard let feedImage = feedImage else { return previous }
				return previous + [feedImage]
			}

			completion(.success(feedImages))
		}
	}
}
