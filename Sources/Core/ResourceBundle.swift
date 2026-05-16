import Foundation

/// Locates a bundled resource regardless of how `Core` is packaged:
///  • SwiftPM test/CLI build → a sibling `*_Core.bundle` next to the binary
///  • Xcode framework build → resources copied into `Core.framework`
///  • app build → possibly the main bundle
///
/// `Bundle.allBundles` does not include SwiftPM resource bundles, so we also
/// scan the directory next to the code bundle for a `.bundle` and probe it.
enum ResourceBundle {
    private final class Token {}

    static func url(
        forResource name: String, withExtension ext: String, subdirectory sub: String
    ) -> URL? {
        let code = Bundle(for: Token.self)
        var bundles: [Bundle] = Bundle.allBundles + [code, .main]

        // Add any `*.bundle` sitting next to the code bundle / main executable.
        for dir in [code.bundleURL.deletingLastPathComponent(),
                    Bundle.main.bundleURL.deletingLastPathComponent()] {
            let found = (try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil
            )) ?? []
            bundles += found
                .filter { $0.pathExtension == "bundle" }
                .compactMap(Bundle.init(url:))
        }

        for b in bundles {
            if let u = b.url(forResource: name, withExtension: ext, subdirectory: sub)
                ?? b.url(forResource: name, withExtension: ext) {
                return u
            }
        }
        return nil
    }
}
