import CoreGraphics
import Foundation

struct Photo {
    let id: String
    let imageName: String
    let size: CGSize
    let isLiked: Bool

    func with(isLiked: Bool) -> Photo {
        Photo(id: id, imageName: imageName, size: size, isLiked: isLiked)
    }
}

extension Photo {
    static func makeMockPhotos() -> [Photo] {
        let photos = [
            ("dog01", CGSize(width: 512, height: 456)),
            ("dog02", CGSize(width: 500, height: 375)),
            ("dog03", CGSize(width: 500, height: 421)),
            ("dog04", CGSize(width: 360, height: 273)),
            ("dog05", CGSize(width: 500, height: 465)),
            ("dog06", CGSize(width: 500, height: 333)),
            ("dog07", CGSize(width: 3024, height: 4032)),
            ("dog08", CGSize(width: 2048, height: 1536)),
            ("dog09", CGSize(width: 500, height: 375)),
            ("dog10", CGSize(width: 353, height: 526)),
            ("dog11", CGSize(width: 410, height: 307)),
            ("dog12", CGSize(width: 476, height: 500)),
            ("dog13", CGSize(width: 456, height: 500)),
            ("dog14", CGSize(width: 333, height: 500)),
            ("dog15", CGSize(width: 500, height: 375)),
            ("dog16", CGSize(width: 190, height: 168)),
            ("dog17", CGSize(width: 2488, height: 3104)),
            ("dog18", CGSize(width: 500, height: 400)),
            ("dog19", CGSize(width: 250, height: 500)),
            ("dog20", CGSize(width: 600, height: 450))
        ]

        return photos.enumerated().map { index, photo in
            return Photo(
                id: "dog-\(index + 1)",
                imageName: photo.0,
                size: photo.1,
                isLiked: index.isMultiple(of: 2)
            )
        }
    }
}
