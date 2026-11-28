import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func load(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url as NSURL
        if let image = cache.object(forKey: key) {
            DispatchQueue.main.async {
                completion(image)
            }
            return
        }
        session.dataTask(with: url) { [weak self] data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            if let image {
                self?.cache.setObject(image, forKey: key)
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
