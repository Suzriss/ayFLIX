import Foundation

enum MovieService {
    private static let key  = "15d23e101e4a2ec680f056559d16b534"
    private static let base = "https://api.themoviedb.org/3"

    static func trending() async throws -> [Media] {
        let url = URL(string: "\(base)/trending/all/day?api_key=\(key)&language=ar-SA")!
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TMDBResponse.self, from: data).results
    }

    static func search(_ query: String) async throws -> [Media] {
        var comps = URLComponents(string: "\(base)/search/multi")!
        comps.queryItems = [
            .init(name: "api_key",  value: key),
            .init(name: "query",    value: query),
            .init(name: "language", value: "ar-SA"),
        ]
        let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TMDBResponse.self, from: data).results
    }

    static let fallback: [Media] = [
        Media(id: 27205,  title: "Inception",               name: nil, posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg", voteAverage: 8.8, mediaType: "movie"),
        Media(id: 157336, title: "Interstellar",            name: nil, posterPath: "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg",  voteAverage: 8.6, mediaType: "movie"),
        Media(id: 550,    title: "Fight Club",              name: nil, posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",  voteAverage: 8.8, mediaType: "movie"),
        Media(id: 299536, title: "Avengers: Infinity War",  name: nil, posterPath: "/7WsyChLLEz32B3f8J3J321.jpg",        voteAverage: 8.3, mediaType: "movie"),
        Media(id: 634649, title: "Spider-Man: No Way Home", name: nil, posterPath: "/1g0dhYjbszX7I37JYjznMp6A1B3.jpg",   voteAverage: 8.0, mediaType: "movie"),
        Media(id: 1396,   title: nil, name: "Breaking Bad", posterPath: "/ggFHVNu6YYI5L9pCfOacjizRGt.jpg",               voteAverage: 9.5, mediaType: "tv"),
    ]
}
