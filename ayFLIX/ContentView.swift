import SwiftUI

struct ContentView: View {
    @State private var items: [Media] = []
    @State private var query = ""
    @State private var loading = true
    @State private var error: String?
    @State private var player: Media?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0b0f19").ignoresSafeArea()

                if loading {
                    ProgressView().tint(.white).scaleEffect(1.4)

                } else if let err = error {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        Button("إعادة المحاولة") { Task { await load(search: query) } }
                            .foregroundStyle(Color(hex: "#ff2e93"))
                    }
                    .padding()

                } else if items.isEmpty {
                    Text("لا نتائج")
                        .foregroundStyle(.white.opacity(0.5))

                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items) { item in
                                MediaCard(item: item)
                                    .onTapGesture { player = item }
                            }
                        }
                        .padding(15)
                    }
                }
            }
            .navigationTitle("ayFLIX")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $query, prompt: "بحث...")
            .autocorrectionDisabled()
            .onChange(of: query) { q in
                Task { await load(search: q) }
            }
            .task { await load(search: "") }
            .fullScreenCover(item: $player) { media in
                WebPlayerView(title: media.displayTitle,
                              tmdbID: media.id,
                              mediaType: media.type)
            }
        }
    }

    private func load(search q: String) async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let trimmed = q.trimmingCharacters(in: .whitespaces)
            items = try await (trimmed.isEmpty
                ? MovieService.trending()
                : MovieService.search(trimmed))
            if items.isEmpty && !trimmed.isEmpty {
                error = "لا نتائج لـ \"\(trimmed)\""
            }
        } catch {
            self.error = "تعذّر الاتصال بالإنترنت"
            // fallback data لو الـ API ما اشتغل
            if items.isEmpty {
                items = MovieService.fallback
            }
        }
    }
}

// MARK: - Card

struct MediaCard: View {
    let item: Media

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: item.posterURL) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Color(hex: "#1c273e")
                            .overlay(Image(systemName: "film")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.15)))
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(2/3, contentMode: .fill)
                .clipped()

                Text(item.type == "tv" ? "مسلسل" : "فيلم")
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 5).padding(.vertical, 3)
                    .background(.black.opacity(0.7))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(5)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !item.rating.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                        Text(item.rating)
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(hex: "#151f32"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color(hex: "#202b42"), lineWidth: 1))
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}
