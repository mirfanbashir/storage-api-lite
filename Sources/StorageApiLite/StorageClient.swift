import Foundation

/// Protocol defining the core storage operations
public protocol StorageClient {
    
    // MARK: - File Operations
    
    /// Uploads data to the storage
    /// - Parameters:
    ///   - data: The data to upload
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    ///   - metadata: Additional metadata for the file
    /// - Returns: Upload result with file information
    func upload(
        data: Data,
        key: String,
        bucket: String?,
        metadata: [String: String]?
    ) async throws -> UploadResult
    
    /// Downloads data from storage
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    /// - Returns: The downloaded data
    func download(key: String, bucket: String?) async throws -> Data
    
    /// Downloads data to a local file
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    ///   - localURL: Local file URL to save the downloaded data
    func downloadToFile(key: String, bucket: String?, localURL: URL) async throws
    
    /// Deletes a file from storage
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    func delete(key: String, bucket: String?) async throws
    
    /// Checks if a file exists in storage
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    /// - Returns: True if the file exists, false otherwise
    func exists(key: String, bucket: String?) async throws -> Bool
    
    /// Gets metadata for a file
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    /// - Returns: File metadata information
    func getMetadata(key: String, bucket: String?) async throws -> FileMetadata
    
    // MARK: - Listing Operations
    
    /// Lists files in a bucket/container
    /// - Parameters:
    ///   - bucket: The container/bucket name (optional, can use default)
    ///   - prefix: Optional prefix to filter files
    ///   - maxResults: Maximum number of results to return
    ///   - continuationToken: Token for pagination
    /// - Returns: List of files with pagination information
    func listFiles(
        bucket: String?,
        prefix: String?,
        maxResults: Int?,
        continuationToken: String?
    ) async throws -> FileListResult
    
    // MARK: - Bucket/Container Operations
    
    /// Creates a new bucket/container
    /// - Parameter bucket: The name of the bucket/container to create
    func createBucket(_ bucket: String) async throws
    
    /// Deletes a bucket/container
    /// - Parameter bucket: The name of the bucket/container to delete
    func deleteBucket(_ bucket: String) async throws
    
    /// Lists all buckets/containers
    /// - Returns: List of bucket/container names
    func listBuckets() async throws -> [String]
    
    // MARK: - URL Operations
    
    /// Generates a presigned URL for direct file access
    /// - Parameters:
    ///   - key: The unique identifier/path for the file
    ///   - bucket: The container/bucket name (optional, can use default)
    ///   - operation: The type of operation (read, write)
    ///   - expirationTime: How long the URL should be valid
    /// - Returns: The presigned URL
    func generatePresignedURL(
        key: String,
        bucket: String?,
        operation: PresignedURLOperation,
        expirationTime: TimeInterval
    ) async throws -> URL
}

// MARK: - Supporting Types

/// Result of an upload operation
public struct UploadResult {
    public let key: String
    public let bucket: String
    public let etag: String?
    public let size: Int64
    public let lastModified: Date
    public let metadata: [String: String]
    
    public init(
        key: String,
        bucket: String,
        etag: String? = nil,
        size: Int64,
        lastModified: Date,
        metadata: [String: String] = [:]
    ) {
        self.key = key
        self.bucket = bucket
        self.etag = etag
        self.size = size
        self.lastModified = lastModified
        self.metadata = metadata
    }
}

/// File metadata information
public struct FileMetadata {
    public let key: String
    public let bucket: String
    public let size: Int64
    public let lastModified: Date
    public let etag: String?
    public let contentType: String?
    public let metadata: [String: String]
    
    public init(
        key: String,
        bucket: String,
        size: Int64,
        lastModified: Date,
        etag: String? = nil,
        contentType: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.key = key
        self.bucket = bucket
        self.size = size
        self.lastModified = lastModified
        self.etag = etag
        self.contentType = contentType
        self.metadata = metadata
    }
}

/// Result of a file listing operation
public struct FileListResult {
    public let files: [FileMetadata]
    public let bucket: String
    public let prefix: String?
    public let isTruncated: Bool
    public let continuationToken: String?
    public let nextContinuationToken: String?
    
    public init(
        files: [FileMetadata],
        bucket: String,
        prefix: String? = nil,
        isTruncated: Bool = false,
        continuationToken: String? = nil,
        nextContinuationToken: String? = nil
    ) {
        self.files = files
        self.bucket = bucket
        self.prefix = prefix
        self.isTruncated = isTruncated
        self.continuationToken = continuationToken
        self.nextContinuationToken = nextContinuationToken
    }
}

/// Types of operations for presigned URLs
public enum PresignedURLOperation {
    case read
    case write
}
