import Foundation

// MARK: - StorageClient Convenience Extensions

extension StorageClient {
    
    /// Uploads a file from a local URL
    /// - Parameters:
    ///   - fileURL: Local file URL to upload
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    ///   - metadata: Additional metadata for the file
    /// - Returns: Upload result with file information
    public func uploadFile(
        from fileURL: URL,
        key: String,
        bucket: String? = nil,
        metadata: [String: String]? = nil
    ) async throws -> UploadResult {
        let data = try Data(contentsOf: fileURL)
        return try await upload(data: data, key: key, bucket: bucket, metadata: metadata)
    }
    
    /// Uploads a string as a file
    /// - Parameters:
    ///   - string: The string content to upload
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    ///   - encoding: String encoding (default: UTF-8)
    ///   - metadata: Additional metadata for the file
    /// - Returns: Upload result with file information
    public func uploadString(
        _ string: String,
        key: String,
        bucket: String? = nil,
        encoding: String.Encoding = .utf8,
        metadata: [String: String]? = nil
    ) async throws -> UploadResult {
        guard let data = string.data(using: encoding) else {
            throw StorageError.invalidData("Unable to encode string with specified encoding")
        }
        return try await upload(data: data, key: key, bucket: bucket, metadata: metadata)
    }
    
    /// Downloads a file and returns it as a string
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    ///   - encoding: String encoding (default: UTF-8)
    /// - Returns: The file content as a string
    public func downloadString(
        key: String,
        bucket: String? = nil,
        encoding: String.Encoding = .utf8
    ) async throws -> String {
        let data = try await download(key: key, bucket: bucket)
        guard let string = String(data: data, encoding: encoding) else {
            throw StorageError.invalidData("Unable to decode data as string with specified encoding")
        }
        return string
    }
    
    /// Gets the size of a file without downloading it
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    /// - Returns: File size in bytes
    public func getFileSize(
        key: String,
        bucket: String? = nil
    ) async throws -> Int64 {
        let metadata = try await getMetadata(key: key, bucket: bucket)
        return metadata.size
    }
}

/// Represents a file upload operation
public struct FileUpload {
    public let data: Data
    public let key: String
    public let bucket: String?
    public let metadata: [String: String]?
    
    public init(
        data: Data,
        key: String,
        bucket: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.data = data
        self.key = key
        self.bucket = bucket
        self.metadata = metadata
    }
    
    /// Creates a FileUpload from a local file
    /// - Parameters:
    ///   - fileURL: Local file URL
    ///   - key: Storage key for the file
    ///   - bucket: Target bucket (optional)
    ///   - metadata: Additional metadata (optional)
    /// - Returns: FileUpload instance
    public static func fromFile(
        _ fileURL: URL,
        key: String,
        bucket: String? = nil,
        metadata: [String: String]? = nil
    ) throws -> FileUpload {
        let data = try Data(contentsOf: fileURL)
        return FileUpload(data: data, key: key, bucket: bucket, metadata: metadata)
    }
}
