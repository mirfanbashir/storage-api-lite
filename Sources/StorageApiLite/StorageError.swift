import Foundation

/// Errors that can occur during storage operations
public enum StorageError: Error, LocalizedError {
    
    // MARK: - Configuration Errors
    case configurationError(String)
    case invalidCredentials(String)
    
    // MARK: - Network Errors
    case networkError(Error)
    case requestFailed(statusCode: Int, message: String)
    case timeout
    case connectionFailed
    
    // MARK: - File Operation Errors
    case fileNotFound(key: String, bucket: String?)
    case bucketNotFound(String)
    case fileAlreadyExists(key: String, bucket: String?)
    case bucketAlreadyExists(String)
    case insufficientPermissions(String)
    case quotaExceeded
    
    // MARK: - Data Errors
    case invalidData(String)
    case checksumMismatch
    case fileTooLarge(maxSize: Int64)
    case invalidKey(String)
    case invalidBucketName(String)
    
    // MARK: - Provider-Specific Errors
    case awsS3Error(code: String, message: String)
    case azureBlobError(code: String, message: String)
    
    // MARK: - General Errors
    case unknownError(Error)
    case operationCancelled
    case unsupportedOperation(String)
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .invalidCredentials(let message):
            return "Invalid credentials: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .requestFailed(let statusCode, let message):
            return "Request failed with status \(statusCode): \(message)"
        case .timeout:
            return "Operation timed out"
        case .connectionFailed:
            return "Failed to establish connection"
        case .fileNotFound(let key, let bucket):
            let bucketInfo = bucket.map { " in bucket '\($0)'" } ?? ""
            return "File '\(key)' not found\(bucketInfo)"
        case .bucketNotFound(let bucket):
            return "Bucket '\(bucket)' not found"
        case .fileAlreadyExists(let key, let bucket):
            let bucketInfo = bucket.map { " in bucket '\($0)'" } ?? ""
            return "File '\(key)' already exists\(bucketInfo)"
        case .bucketAlreadyExists(let bucket):
            return "Bucket '\(bucket)' already exists"
        case .insufficientPermissions(let operation):
            return "Insufficient permissions for operation: \(operation)"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .checksumMismatch:
            return "Checksum verification failed"
        case .fileTooLarge(let maxSize):
            return "File too large. Maximum size: \(maxSize) bytes"
        case .invalidKey(let key):
            return "Invalid key: '\(key)'"
        case .invalidBucketName(let bucket):
            return "Invalid bucket name: '\(bucket)'"
        case .awsS3Error(let code, let message):
            return "AWS S3 error (\(code)): \(message)"
        case .azureBlobError(let code, let message):
            return "Azure Blob error (\(code)): \(message)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        case .operationCancelled:
            return "Operation was cancelled"
        case .unsupportedOperation(let operation):
            return "Unsupported operation: \(operation)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .configurationError:
            return "Storage client is not properly configured"
        case .invalidCredentials:
            return "Authentication credentials are invalid or expired"
        case .networkError, .requestFailed, .timeout, .connectionFailed:
            return "Network connectivity or server issues"
        case .fileNotFound, .bucketNotFound:
            return "Requested resource does not exist"
        case .fileAlreadyExists, .bucketAlreadyExists:
            return "Resource already exists"
        case .insufficientPermissions:
            return "User does not have required permissions"
        case .quotaExceeded:
            return "Storage limits have been reached"
        case .invalidData, .checksumMismatch, .fileTooLarge, .invalidKey, .invalidBucketName:
            return "Invalid input data or parameters"
        case .awsS3Error, .azureBlobError:
            return "Provider-specific error occurred"
        case .unknownError, .operationCancelled, .unsupportedOperation:
            return "Unexpected error condition"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .configurationError, .invalidCredentials:
            return "Check your configuration and credentials"
        case .networkError, .requestFailed, .timeout, .connectionFailed:
            return "Check your network connection and try again"
        case .fileNotFound, .bucketNotFound:
            return "Verify the resource exists and the path is correct"
        case .fileAlreadyExists, .bucketAlreadyExists:
            return "Use a different name or delete the existing resource"
        case .insufficientPermissions:
            return "Contact your administrator to grant necessary permissions"
        case .quotaExceeded:
            return "Free up space or upgrade your storage plan"
        case .invalidData, .invalidKey, .invalidBucketName:
            return "Correct the input data and try again"
        case .checksumMismatch:
            return "The file may be corrupted, try uploading again"
        case .fileTooLarge:
            return "Reduce the file size or use chunked upload"
        case .awsS3Error, .azureBlobError, .unknownError:
            return "Contact support if the problem persists"
        case .operationCancelled:
            return "Restart the operation if needed"
        case .unsupportedOperation:
            return "Use a supported operation or update the library"
        }
    }
}
