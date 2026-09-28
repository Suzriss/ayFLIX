import Foundation

enum MovieService {
    private static let key = "15d23e101e4a2ec680f056559d16b534"
    private static let base = "https://api.themoviedb.org/3"

    static func trending() async throws -> [Media] {
        let url = URL(string: "\(base)/trending/all/day?api_key=\(key)&language=ar-SA")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TMDBResponse.self, from: data).results
    }

    static func search(_ query: String) async throws -> [Media] {
        var comps = URLComponents(string: "\(base)/search/multi")!
        comps.queryItems = [
            .init(name: "api_key",   value: key),
            .init(name: "query",     value: query),
            .init(name: "language",  value: "ar-SA"),
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(TMDBResponse.self, from: data).results
    }
}
