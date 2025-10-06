// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2018 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import NextcloudKit
import PDFKit
import Accelerate
import CoreMedia
import Photos
import Alamofire

final class NCUtility: NSObject, Sendable {
    let utilityFileSystem = NCUtilityFileSystem()
    let global = NCGlobal.shared

    @objc func isSimulatorOrTestFlight() -> Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("CoreSimulator") || path.contains("sandboxReceipt")
    }

    func isSimulator() -> Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("CoreSimulator")
    }

    func isTypeFileRichDocument(_ metadata: tableMetadata) -> Bool {
        guard metadata.fileNameView != "." else { return false }
        let fileExtension = (metadata.fileNameView as NSString).pathExtension
        guard !fileExtension.isEmpty else { return false }
        guard let mimeType = UTType(tag: fileExtension.uppercased(), tagClass: .filenameExtension, conformingTo: nil)?.identifier else { return false }
        /// contentype
        if !NCCapabilities.shared.getCapabilities(account: metadata.account).capabilityRichDocumentsMimetypes.filter({ $0.contains(metadata.contentType) || $0.contains("text/plain") }).isEmpty {
            return true
        }
        /// mimetype
        if !NCCapabilities.shared.getCapabilities(account: metadata.account).capabilityRichDocumentsMimetypes.isEmpty && mimeType.components(separatedBy: ".").count > 2 {
            let mimeTypeArray = mimeType.components(separatedBy: ".")
            let mimeType = mimeTypeArray[mimeTypeArray.count - 2] + "." + mimeTypeArray[mimeTypeArray.count - 1]
            if !NCCapabilities.shared.getCapabilities(account: metadata.account).capabilityRichDocumentsMimetypes.filter({ $0.contains(mimeType) }).isEmpty {
                return true
            }
        }
        return false
    }

    func editorsDirectEditing(account: String, contentType: String) -> [String] {
        var editor: [String] = []
        guard let results = NCManageDatabase.shared.getDirectEditingEditors(account: account) else { return editor }

        for result: tableDirectEditingEditors in results {
            for mimetype in result.mimetypes {
                if mimetype == contentType {
                    editor.append(result.editor)
                }
                // HARDCODE
                // https://github.com/nextcloud/text/issues/913
                if mimetype == "text/markdown" && contentType == "text/x-markdown" {
                    editor.append(result.editor)
                }
                if contentType == "text/html" {
                    editor.append(result.editor)
                }
            }
            for mimetype in result.optionalMimetypes {
                if mimetype == contentType {
                    editor.append(result.editor)
                }
            }
        }
        return Array(Set(editor))
    }

    func permissionsContainsString(_ metadataPermissions: String, permissions: String) -> Bool {
        for char in permissions {
            if metadataPermissions.contains(char) == false {
                return false
            }
        }
        return true
    }

    func getCustomUserAgentNCText() -> String {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // NOTE: Hardcoded (May 2022)
            // Tested for iPhone SE (1st), iOS 12 iPhone Pro Max, iOS 15.4
            // 605.1.15 = WebKit build version
            // 15E148 = frozen iOS build number according to: https://chromestatus.com/feature/4558585463832576
            return userAgent + " " + "AppleWebKit/605.1.15 Mobile/15E148"
        } else {
            return userAgent
        }
    }

    func getCustomUserAgentOnlyOffice() -> String {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "Mozilla/5.0 (iPad) Nextcloud-iOS/\(appVersion)"
        } else {
            return "Mozilla/5.0 (iPhone) Mobile Nextcloud-iOS/\(appVersion)"
        }
    }

    @objc func isQuickLookDisplayable(metadata: tableMetadata) -> Bool {
        return true
    }

    @objc func ocIdToFileId(ocId: String?) -> String? {
        guard let ocId = ocId else { return nil }
        let items = ocId.components(separatedBy: "oc")

        if items.count < 2 { return nil }
        guard let intFileId = Int(items[0]) else { return nil }
        return String(intFileId)
    }

    func splitOcId(_ ocId: String) -> (fileId: String?, instanceId: String?) {
        let parts = ocId.components(separatedBy: "oc")
        guard parts.count == 2 else {
            return (nil, nil)
        }
        return (parts[0], "oc" + parts[1])
    }

    /// Pads a numeric fileId with leading zeros to reach 8 characters.
    func paddedFileId(_ fileId: String) -> String {
        if fileId.count >= 8 { return fileId }
        let zeros = String(repeating: "0", count: 8 - fileId.count)
        return zeros + fileId
    }

    func getLivePhotoOcId(metadata: tableMetadata) -> String? {
        if let instanceId = splitOcId(metadata.ocId).instanceId {
            return paddedFileId(metadata.livePhotoFile) + instanceId
        }
        return nil
    }

    func getVersionBuild() -> String {
        if let dictionary = Bundle.main.infoDictionary,
           let version = dictionary["CFBundleShortVersionString"],
           let build = dictionary["CFBundleVersion"] {
            return "\(version).\(build)"
        }
        return ""
    }

    func getVersionMaintenance() -> String {
        if let dictionary = Bundle.main.infoDictionary,
           let version = dictionary["CFBundleShortVersionString"] {
            return "\(version)"
        }
        return ""
    }
    
    @objc func getVersionApp(withBuild: Bool = true) -> String {
        if let dictionary = Bundle.main.infoDictionary {
            if let version = dictionary["CFBundleShortVersionString"], let build = dictionary["CFBundleVersion"] {
                if withBuild {
                    return "\(version).\(build)"
                } else {
                    return "\(version)"
                }
            }
        }
        return ""
    }

    /*
     Facebook's comparison algorithm:
     */

    func compare(tolerance: Float, expected: Data, observed: Data) throws -> Bool {
        enum customError: Error {
            case unableToGetUIImageFromData
            case unableToGetCGImageFromData
            case unableToGetColorSpaceFromCGImage
            case imagesHasDifferentSizes
            case unableToInitializeContext
        }

        guard let expectedUIImage = UIImage(data: expected), let observedUIImage = UIImage(data: observed) else {
            throw customError.unableToGetUIImageFromData
        }
        guard let expectedCGImage = expectedUIImage.cgImage, let observedCGImage = observedUIImage.cgImage else {
            throw customError.unableToGetCGImageFromData
        }
        guard let expectedColorSpace = expectedCGImage.colorSpace, let observedColorSpace = observedCGImage.colorSpace else {
            throw customError.unableToGetColorSpaceFromCGImage
        }
        if expectedCGImage.width != observedCGImage.width || expectedCGImage.height != observedCGImage.height {
            throw customError.imagesHasDifferentSizes
        }
        let imageSize = CGSize(width: expectedCGImage.width, height: expectedCGImage.height)
        let numberOfPixels = Int(imageSize.width * imageSize.height)

        // Checking that our `UInt32` buffer has same number of bytes as image has.
        let bytesPerRow = min(expectedCGImage.bytesPerRow, observedCGImage.bytesPerRow)
        assert(MemoryLayout<UInt32>.stride == bytesPerRow / Int(imageSize.width))

        let expectedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)
        let observedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)

        let expectedPixelsRaw = UnsafeMutableRawPointer(expectedPixels)
        let observedPixelsRaw = UnsafeMutableRawPointer(observedPixels)

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let expectedContext = CGContext(data: expectedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
                                              bitsPerComponent: expectedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
                                              space: expectedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            expectedPixels.deallocate()
            observedPixels.deallocate()
            throw customError.unableToInitializeContext
        }
        guard let observedContext = CGContext(data: observedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
                                              bitsPerComponent: observedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
                                              space: observedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            expectedPixels.deallocate()
            observedPixels.deallocate()
            throw customError.unableToInitializeContext
        }

        expectedContext.draw(expectedCGImage, in: CGRect(origin: .zero, size: imageSize))
        observedContext.draw(observedCGImage, in: CGRect(origin: .zero, size: imageSize))

        let expectedBuffer = UnsafeBufferPointer(start: expectedPixels, count: numberOfPixels)
        let observedBuffer = UnsafeBufferPointer(start: observedPixels, count: numberOfPixels)

        var isEqual = true
        if tolerance == 0 {
            isEqual = expectedBuffer.elementsEqual(observedBuffer)
        } else {
            // Go through each pixel in turn and see if it is different
            var numDiffPixels = 0
            for pixel in 0 ..< numberOfPixels where expectedBuffer[pixel] != observedBuffer[pixel] {
                // If this pixel is different, increment the pixel diff count and see if we have hit our limit.
                numDiffPixels += 1
                let percentage = 100 * Float(numDiffPixels) / Float(numberOfPixels)
                if percentage > tolerance {
                    isEqual = false
                    break
                }
            }
        }

        expectedPixels.deallocate()
        observedPixels.deallocate()

        return isEqual
    }

    #if !EXTENSION_FILE_PROVIDER_EXTENSION
    func getLocation(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let llocation = CLLocation(latitude: latitude, longitude: longitude)

        if let location = NCManageDatabase.shared.getLocationFromLatAndLong(latitude: latitude, longitude: longitude) {
            completion(location)
        } else {
            geocoder.reverseGeocodeLocation(llocation) { placemarks, error in
                if error == nil, let placemark = placemarks?.first {
                    let locationComponents: [String] = [placemark.name, placemark.locality, placemark.country]
                        .compactMap {$0}

                    let location = locationComponents.joined(separator: ", ")

                    NCManageDatabase.shared.addGeocoderLocation(location, latitude: latitude, longitude: longitude)
                    completion(location)
                }
            }
        }
    }
    #endif

    // https://stackoverflow.com/questions/5887248/ios-app-maximum-memory-budget/19692719#19692719
    // https://stackoverflow.com/questions/27556807/swift-pointer-problems-with-mach-task-basic-info/27559770#27559770

    func getMemoryUsedAndDeviceTotalInMegabytes() -> (Float, Float) {
        var usedmegabytes: Float = 0
        let totalbytes = Float(ProcessInfo.processInfo.physicalMemory)
        let totalmegabytes = totalbytes / 1024.0 / 1024.0
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        if kerr == KERN_SUCCESS {
            let usedbytes: Float = Float(info.resident_size)
            usedmegabytes = usedbytes / 1024.0 / 1024.0
        }

        return (usedmegabytes, totalmegabytes)
    }

    func getHeightHeaderEmptyData(view: UIView, portraitOffset: CGFloat, landscapeOffset: CGFloat, isHeaderMenuTransferViewEnabled: Bool = false) -> CGFloat {
        var height: CGFloat = 0
        if UIDevice.current.orientation.isPortrait {
            height = (view.frame.height / 2) - (view.safeAreaInsets.top / 2) + portraitOffset
        } else {
            height = (view.frame.height / 2) + landscapeOffset + CGFloat(isHeaderMenuTransferViewEnabled ? 35 : 0)
        }
        return height
    }

    func formatBadgeCount(_ count: Int) -> String {
        if count <= 9999 {
            return "\(count)"
        } else {
            return count.formatted(.number.notation(.compactName).locale(Locale(identifier: "en_US")))
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        
    // E-mail validations
    // 1. Basic Email Validator (ASCII only)
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    // 2. Manually Convert Unicode Domain to Punycode with German Char Support
    func convertToPunycode(email: String) -> String? {
        guard let atIndex = email.firstIndex(of: "@") else { return nil }
        
        let localPart = String(email[..<atIndex])
        var domainPart = String(email[email.index(after: atIndex)...])
        
        // Normalize the domain part before converting to Punycode
        let normalizedDomainPart = domainPart.precomposedStringWithCanonicalMapping
        
        // Attempt to convert Unicode to Punycode using a custom conversion function
        if let punycodeDomain = punycodeEncode(normalizedDomainPart) {
            return "\(localPart)@\(punycodeDomain)"
        }
        
        return nil
    }

    // 3. Convert Unicode String to Punycode (Manually Handling German Characters)
    func punycodeEncode(_ domain: String) -> String? {
        // Mapping of common German characters to their corresponding Punycode equivalents
        var punycodeDomain = domain.lowercased()
        
        let germanCharToPunycode: [String: String] = [
            "ü": "xn--u-1fa",  // ü → xn--u-1fa
            "ä": "xn--a-1fa",  // ä → xn--a-1fa
            "ö": "xn--o-1fa",  // ö → xn--o-1fa
            "ß": "xn--ss-1fa", // ß → xn--ss-1fa
            "é": "xn--e-1fa",  // é → xn--e-1fa
            "è": "xn--e-1f",   // è → xn--e-1f
            "à": "xn--a-1f",   // à → xn--a-1f
        ]
        
        // Replace each German character with the corresponding Punycode equivalent
        for (char, punycode) in germanCharToPunycode {
            punycodeDomain = punycodeDomain.replacingOccurrences(of: char, with: punycode)
        }
        
        // If no change occurred, return the domain as it is (i.e., no Punycode needed)
        return punycodeDomain
    }

    // 4. IDN Email Validator (handles Unicode domain by converting to Punycode)
    func isValidIDNEmail(_ email: String) -> Bool {
        // Convert domain part to Punycode and validate using basic email regex
        guard let punycodeEmail = convertToPunycode(email: email) else {
            return false
        }
        
        return isValidEmail(punycodeEmail)
    }

    // 5. Unified Email Validation - Check for both basic and IDN emails
    func validateEmail(_ email: String) -> Bool {
        if isValidEmail(email) {
            print("Valid ASCII email: \(email)")
            return true
        } else if isValidIDNEmail(email) {
            print("Valid IDN email: \(email)")
            return true
        } else {
            print("Invalid email: \(email)")
            return false
        }
    }
}
