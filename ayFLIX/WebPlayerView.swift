import SwiftUI
import WebKit

struct WebPlayerView: View {
    let title: String
    let tmdbID: Int
    let mediaType: String

    @Environment(\.dismiss) private var dismiss
    @State private var sourceIndex = 0

    private let sources = ["vidlink", "vidsrc", "2embed"]

    private var embedURL: URL {
        switch sourceIndex {
        case 1:  return URL(string: "https://vidsrc.to/embed/\(mediaType)/\(tmdbID)")!
        case 2:  return URL(string: "https://2embed.cc/embed/\(tmdbID)")!
        default: return URL(string: "https://vidlink.pro/\(mediaType)/\(tmdbID)")!
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AdFreeWebView(url: embedURL).ignoresSafeArea()

            VStack {
                // شريط علوي
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // أزرار المصدر
                HStack(spacing: 8) {
                    ForEach(sources.indices, id: \.self) { i in
                        Button(sources[i]) { sourceIndex = i }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(sourceIndex == i
                                ? Color(hex: "#ff2e93")
                                : Color.black.opacity(0.55))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .animation(.easeOut(duration: 0.15), value: sourceIndex)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - WKWebView + Ad Blocker

private struct AdFreeWebView: UIViewRepresentable {
    let url: URL

    private static let blockRules: String = {
        let domains = [
            "doubleclick\\.net", "googlesyndication\\.com", "adnxs\\.com",
            "amazon-adsystem\\.com", "outbrain\\.com", "taboola\\.com",
            "exoclick\\.com", "juicyads\\.com", "trafficjunky\\.net",
            "popads\\.net", "propellerads\\.com", "revcontent\\.com",
            "mgid\\.com", "zedo\\.com", "adform\\.net", "bidswitch\\.net",
            "rubiconproject\\.com", "openx\\.net", "pubmatic\\.com",
            "criteo\\.com", "moatads\\.com", "adsrvr\\.org",
        ]
        let rules = domains.map {
            #"{"trigger":{"url-filter":".*\#($0).*"},"action":{"type":"block"}}"#
        }.joined(separator: ",")
        return "[\(rules)]"
    }()

    private static let cleanupJS = """
    (function(){
        window.open = function(){ return null; };

        // وقف روابط _blank / _top
        window.addEventListener('click', function(e){
            var a = e.target.closest('a[target="_blank"],a[target="_top"]');
            if (a) { e.preventDefault(); e.stopImmediatePropagation(); }
        }, true);

        var SEL = [
            '[class*="preroll"]','[class*="ad-overlay"]','[class*="ad-container"]',
            '[class*="ad-wrapper"]','[id*="ad-slot"]','[id*="google_ads"]',
            '[class*="popup"]','[class*="promo"]','[data-ad-unit]',
            'ins.adsbygoogle','.vast-blocker','.jw-overlays',
        ].join(',');

        function sweep(){
            try {
                document.querySelectorAll(SEL).forEach(function(el){
                    if (!el.querySelector('video') && !el.closest('video'))
                        el.style.cssText = 'display:none!important';
                });
            } catch(e){}
        }
        sweep();
        new MutationObserver(sweep)
            .observe(document.documentElement, {childList:true, subtree:true});
    })();
    """

    private static var cachedRuleList: WKContentRuleList?
    private static var compiled = false

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let uc = WKUserContentController()
        uc.addUserScript(WKUserScript(
            source: Self.cleanupJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        ))
        config.userContentController = uc

        if let cached = Self.cachedRuleList {
            uc.add(cached)
        } else if !Self.compiled {
            Self.compiled = true
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "ayflix-adblock",
                encodedContentRuleList: Self.blockRules
            ) { list, _ in
                guard let list else { return }
                DispatchQueue.main.async {
                    Self.cachedRuleList = list
                    config.userContentController.add(list)
                }
            }
        }

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.scrollView.isScrollEnabled = false
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        load(url, into: wv)
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        if wv.url?.absoluteString != url.absoluteString { load(url, into: wv) }
    }

    private func load(_ url: URL, into wv: WKWebView) {
        var req = URLRequest(url: url)
        req.setValue("https://\(url.host ?? "")", forHTTPHeaderField: "Referer")
        wv.load(req)
    }
}
