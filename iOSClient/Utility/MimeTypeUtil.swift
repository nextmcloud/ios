import Foundation
import UIKit
import UniformTypeIdentifiers

/// A lightweight MIME type utility mirroring core behavior of Android's MimeTypeUtil.
/// Provides: MIME detection from filename/path, helpers to categorize, and icon selection.
public struct MimeTypeUtil {

    // MARK: - Public API

    /// Returns the best MIME type for a given file name using UTType and fallback mappings.
    public static func bestMimeType(forFileName fileName: String) -> String {
        let ext = safeExtension(from: fileName)
        // Try internal mapping first
        if let mapped = extensionToMimeTypes[ext]?.first {
            return mapped
        }
        // Try UTType
        if let ut = UTType(filenameExtension: ext), let mime = ut.preferredMIMEType {
            return mime
        }
        // Fallback
        return "application/octet-stream"
    }

    /// Returns a list of possible MIME types for a given extension.
    public static func mimeTypes(forExtension ext: String) -> [String] {
        let key = ext.lowercased()
        if let list = extensionToMimeTypes[key], !list.isEmpty {
            return list
        }
        if let ut = UTType(filenameExtension: key), let mime = ut.preferredMIMEType {
            return [mime]
        }
        return []
    }

    /// Determines a MIME type from a full path.
    public static func mimeType(fromPath path: String) -> String {
        return bestMimeType(forFileName: (path as NSString).lastPathComponent)
    }

    // MARK: - Category helpers

    public static func isImage(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        return m.hasPrefix("image/") && !m.contains("djvu")
    }

    public static func isVideo(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        return m.hasPrefix("video/")
    }

    public static func isAudio(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        return m.hasPrefix("audio/")
    }

    public static func isText(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        return m.hasPrefix("text/")
    }

    public static func isPDF(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        return m == "application/pdf"
    }

    public static func isVCard(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        return m == "text/vcard"
    }

    public static func isCalendar(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        return m == "text/calendar"
    }

    public static func isFolder(_ mime: String?) -> Bool {
        guard let m = mime?.lowercased() else { return false }
        // Common directory hints
        return m == "httpd/unix-directory" || m == "inode/directory"
    }

    public static func isImage(urlOrPath: String) -> Bool {
        return isImage(mimeType(fromPath: urlOrPath))
    }

    public static func isVideo(urlOrPath: String) -> Bool {
        return isVideo(mimeType(fromPath: urlOrPath))
    }

    // MARK: - Icon mapping

    /// Returns an icon image for the provided MIME type or filename.
    /// Uses named assets if prefixed with "asset:", or SF Symbols if prefixed with "sf:" (or no prefix).
    public static func icon(forMimeType mimeType: String, fileName: String, account: String? = nil, isDarkMode: Bool = false) -> UIImage? {
        let lowerMime = mimeType.lowercased()
        if let iconName = mimetypeToIconName[lowerMime], let image = imageFromIconName(iconName) {
            return image
        }
        // Fallback to main type mapping
        if let main = lowerMime.split(separator: "/").first {
            if let iconName = mainTypeToIconName[String(main)], let image = imageFromIconName(iconName) {
                return image
            }
        }
        // Unknown -> generic document
        return UIImage(named: "file")! //UIImage(systemName: "doc")
    }

    // MARK: - Private helpers

    private static func safeExtension(from fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        return ext
    }

    private static func imageFromIconName(_ name: String) -> UIImage? {
        if name.hasPrefix("asset:") {
            let assetName = String(name.dropFirst("asset:".count))
            return UIImage(named: assetName)
        } else if name.hasPrefix("sf:") {
            let symbol = String(name.dropFirst("sf:".count))
            return UIImage(systemName: symbol)
        } else {
            // Default to SF Symbol name if no prefix provided
            return UIImage(systemName: name)
        }
    }

    // MARK: - Mappings (subset for practicality)

    /// Full MIME -> icon name mapping. Use "asset:" prefix to load from asset catalog, or "sf:" for SF Symbols.
    private static let mimetypeToIconName: [String: String] = [
        // Documents
        "application/pdf": "asset:file_pdf", // "asset:file_pdf",
        "text/calendar": "sf:calendar",
        "text/csv": "sf:tablecells",
        "text/html": "sf:chevron.left.forwardslash.chevron.right",
        "application/javascript": "sf:chevron.left.forwardslash.chevron.right",
        "application/json": "sf:chevron.left.forwardslash.chevron.right",
        "application/xml": "sf:chevron.left.forwardslash.chevron.right",
        "application/yaml": "sf:curlybraces",
        "text/plain": "asset:file_txt", // "sf:doc.text",
        "text/markdown": "asset:file_txt", // "sf:doc.text",
        "text/vcard": "sf:person.crop.circle",
        // Archives
        "application/zip": "asset:file_compress", // "sf:doc.zipper",
        "application/x-7z-compressed": "asset:file_compress", // "sf:doc.zipper",
        "application/x-rar-compressed": "asset:file_compress", // "sf:doc.zipper",
        "application/x-gzip": "asset:file_compress", // "sf:doc.zipper",
        "application/x-bzip2": "asset:file_compress", // "sf:doc.zipper",
        "application/x-tar": "asset:file_compress", // "sf:doc.zipper",
        // Media
        "image/svg+xml": "asset:file_photo", // "sf:photo",
        MimeTypeUtil.genericImage: "asset:file_photo", // "sf:photo",
        MimeTypeUtil.genericVideo: "asset:file_movie", // "sf:video",
        MimeTypeUtil.genericAudio: "asset:file_audio", // "sf:waveform",
    ]

    /// Main type (prefix) -> icon name mapping
    private static let mainTypeToIconName: [String: String] = [
        "audio": "asset:file_audio", // "sf:waveform",
        "image": "asset:file_photo", // "sf:photo",
        "text": "asset:file_txt", // "sf:doc.text",
        "video": "asset:file_movie", // "sf:video",
        "web": "sf:chevron.left.forwardslash.chevron.right"
    ]

    /// Extension -> [MIME] mapping (subset)
    private static let extensionToMimeTypes: [String: [String]] = [
        // Images
        "jpg": [genericImageJPEG], "jpeg": [genericImageJPEG], "png": ["image/png"], "gif": ["image/gif"],
        "heic": ["image/heic"], "heif": ["image/heif"], "svg": ["image/svg+xml", "text/plain"],
        // Video
        "mp4": [genericVideoMP4], "mov": ["video/quicktime"], "mkv": ["video/x-matroska"], "avi": ["video/x-msvideo"], "webm": ["video/webm"],
        // Audio
        "mp3": ["audio/mpeg"], "wav": ["audio/wav"], "flac": ["audio/flac"], "m4a": ["audio/mp4"],
        // Documents
        "pdf": ["application/pdf"], "csv": ["text/csv"], "html": ["text/html", "text/plain"], "htm": ["text/html", "text/plain"],
        "xml": ["application/xml", "text/plain"], "json": ["application/json", "text/plain"], "js": ["application/javascript", "text/plain"],
        "yaml": ["application/yaml", "text/plain"], "yml": ["application/yaml", "text/plain"], "txt": ["text/plain"],
        "md": ["text/markdown"], "markdown": ["text/markdown"], "mdown": ["text/markdown"],
        "ics": ["text/calendar"], "ical": ["text/calendar"], "vcf": ["text/vcard"], "vcard": ["text/vcard"],
        // Office-like
        "doc": ["application/msword"], "docx": ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
        "xls": ["application/vnd.ms-excel"], "xlsx": ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
        "ppt": ["application/vnd.ms-powerpoint"], "pptx": ["application/vnd.openxmlformats-officedocument.presentationml.presentation"],
        // Apple iWork
        "pages": ["application/x-iwork-pages-sffpages"],
        "numbers": ["application/x-iwork-numbers-sffnumbers"],
        "key": ["application/x-iwork-keynote-sffkey"], "keynote": ["application/x-iwork-keynote-sffkey"],
        // Archives
        "zip": ["application/zip"], "7z": ["application/x-7z-compressed"], "rar": ["application/x-rar-compressed"],
        "tar": ["application/x-tar"], "gz": ["application/x-gzip"], "bz2": ["application/x-bzip2"],
        // Books / graphics
        "epub": ["application/epub+zip"], "psd": ["application/x-photoshop"], "ai": ["application/illustrator"],
    ]

    // Common MIME constants used in mappings
    private static let genericImage = "image/*"
    private static let genericVideo = "video/*"
    private static let genericAudio = "audio/*"
    private static let genericImageJPEG = "image/jpeg"
    private static let genericVideoMP4 = "video/mp4"
}
