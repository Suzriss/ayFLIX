import Foundation

struct TMDBResponse: Decodable {
    let results: [Media]
}

struct Media: Decodable, Identifiable {
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let voteAverage: Double?
    let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name
        case posterPath   = "poster_path"
        case voteAverage  = "vote_average"
        case mediaType    = "media_type"
    }

    var displayTitle: String { title ?? name ?? "—" }
    var type: String { mediaType == "tv" ? "tv" : "movie" }
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
    }
    var rating: String {
        guard let v = voteAverage, v > 0 else { return "" }
        return String(format: "%.1f", v)
    }
}
