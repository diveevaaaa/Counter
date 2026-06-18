import Foundation

struct MoviesResponse: Decodable {
    let items: [Movie]
    let errorMessage: String
}

struct Movie: Decodable {
    let id: String
    let title: String
    let image: String
    let imDbRating: String

    var rating: Float? {
        Float(imDbRating)
    }

    var imageURL: URL? {
        URL(string: image)
    }
}
