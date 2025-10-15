import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

#if os(Linux)
import FoundationXML
#endif

/// Simple XML parser for S3 responses
internal class S3XMLParser: NSObject, XMLParserDelegate {
    
    private var currentElement = ""
    private var currentValue = ""
    private var files: [FileMetadata] = []
    private var buckets: [String] = []
    private var isTruncated = false
    private var nextContinuationToken: String?
    private var currentBucket = ""
    private var currentPrefix: String?
    private var currentContinuationToken: String?
    
    // Current file being parsed
    private var currentKey = ""
    private var currentSize: Int64 = 0
    private var currentLastModified = Date()
    private var currentETag = ""
    
    func parseListObjectsV2Response(
        xmlString: String,
        bucket: String,
        prefix: String?,
        continuationToken: String?
    ) throws -> FileListResult {
        files = []
        isTruncated = false
        nextContinuationToken = nil
        currentBucket = bucket
        currentPrefix = prefix
        currentContinuationToken = continuationToken
        
        guard let data = xmlString.data(using: .utf8) else {
            throw StorageError.invalidData("Unable to convert XML string to data")
        }
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            throw StorageError.invalidData("Failed to parse XML response")
        }
        
        return FileListResult(
            files: files,
            bucket: bucket,
            prefix: prefix,
            isTruncated: isTruncated,
            continuationToken: continuationToken,
            nextContinuationToken: nextContinuationToken
        )
    }
    
    func parseListBucketsResponse(xmlString: String) throws -> [String] {
        buckets = []
        
        guard let data = xmlString.data(using: .utf8) else {
            throw StorageError.invalidData("Unable to convert XML string to data")
        }
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            throw StorageError.invalidData("Failed to parse XML response")
        }
        
        return buckets
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
        
        if elementName == "Contents" {
            // Reset for new file
            currentKey = ""
            currentSize = 0
            currentLastModified = Date()
            currentETag = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "Key":
            currentKey = currentValue
        case "Size":
            currentSize = Int64(currentValue) ?? 0
        case "LastModified":
            currentLastModified = parseS3Date(currentValue) ?? Date()
        case "ETag":
            currentETag = currentValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        case "Contents":
            // End of file entry
            let metadata = FileMetadata(
                key: currentKey,
                bucket: currentBucket,
                size: currentSize,
                lastModified: currentLastModified,
                etag: currentETag
            )
            files.append(metadata)
        case "IsTruncated":
            isTruncated = currentValue.lowercased() == "true"
        case "NextContinuationToken":
            nextContinuationToken = currentValue
        case "Name":
            if currentElement == "Name" {
                buckets.append(currentValue)
            }
        default:
            break
        }
        
        currentValue = ""
    }
    
    private func parseS3Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Fallback to format without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}
