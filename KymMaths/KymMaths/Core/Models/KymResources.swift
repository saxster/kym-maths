import Foundation

/// The one place bundled content is looked up. SwiftPM puts resources in the
/// target's own bundle; the Xcode app targets copy them into the main bundle.
enum KymResources {
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        .module
        #else
        .main
        #endif
    }

    static func url(forResource name: String, withExtension ext: String, subdirectory: String) -> URL? {
        bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
            ?? bundle.url(forResource: name, withExtension: ext)
    }
}
