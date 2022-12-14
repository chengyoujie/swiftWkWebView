

import Foundation
import CoreServices
import CommonCrypto

extension String {
    func md5() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        return String(format: hash as String)
    }
    
    func isJSONFile() -> Bool {
        if self.count == 0 { return false }
        let pattern = "\\.(json)"
        do {
            let result = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive).matches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange(location: 0, length: self.count))
            return result.count > 0
        } catch {
            return false
        }
    }

    func isJpeFile() -> Bool {
        if self.count == 0 { return false }
        let pattern = "\\.(jpg|jpeg)"
        do {
            let result = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive).matches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange(location: 0, length: self.count))
            return result.count > 0
        } catch {
            return false
        }
    }

    
    func isSoundFile() -> Bool {
        if self.count == 0 { return false }
        let pattern = "\\.(mp3|avi|mp4)"
        do {
            let result = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive).matches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange(location: 0, length: self.count))
            return result.count > 0
        } catch {
            return false
        }
    }
    
    //???????????????????????????Mime-Type
    static func mimeType(pathExtension: String?) -> String {
        guard let pathExtension = pathExtension else { return "application/octet-stream" }
        if pathExtension == "php"
        {
            return "text/html"
        }else if pathExtension == "atlas" || pathExtension == "json"{
            return "application/json"
        }
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           pathExtension as NSString,
                                                           nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?
                .takeRetainedValue() {
                return mimetype as String
            }
        }
        
        //???????????????????????????????????????????????????application/octet-stream????????????????????????????????????
        return "application/octet-stream"
    }
}


