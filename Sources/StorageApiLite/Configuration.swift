import Foundation

/// Supported storage providers
public enum StorageProvider {
    case awsS3
    case azureBlob
}

/// Configuration for different storage providers
public enum StorageConfiguration {
    case awsS3(AWSS3Configuration)
    case azureBlob(AzureBlobConfiguration)
    
    /// The storage provider type
    public var provider: StorageProvider {
        switch self {
        case .awsS3:
            return .awsS3
        case .azureBlob:
            return .azureBlob
        }
    }
    
    /// Attempts to automatically detect configuration from environment variables
    /// - Parameter provider: The storage provider to configure
    /// - Returns: Configuration for the specified provider
    /// - Throws: StorageError if configuration cannot be detected
    public static func autoDetect(for provider: StorageProvider) throws -> StorageConfiguration {
        switch provider {
        case .awsS3:
            return .awsS3(try AWSS3Configuration.fromEnvironment())
        case .azureBlob:
            return .azureBlob(try AzureBlobConfiguration.fromEnvironment())
        }
    }
}

/// Configuration for AWS S3
public struct AWSS3Configuration {
    public let accessKeyId: String
    public let secretAccessKey: String
    public let region: String
    public let defaultBucket: String?
    public let endpoint: String?  // For S3-compatible services
    public let sessionToken: String?  // For temporary credentials
    
    public init(
        accessKeyId: String,
        secretAccessKey: String,
        region: String,
        defaultBucket: String? = nil,
        endpoint: String? = nil,
        sessionToken: String? = nil
    ) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.region = region
        self.defaultBucket = defaultBucket
        self.endpoint = endpoint
        self.sessionToken = sessionToken
    }
    
    /// Creates configuration from environment variables
    /// Expected environment variables:
    /// - AWS_ACCESS_KEY_ID
    /// - AWS_SECRET_ACCESS_KEY
    /// - AWS_REGION
    /// - AWS_DEFAULT_BUCKET (optional)
    /// - AWS_ENDPOINT (optional)
    /// - AWS_SESSION_TOKEN (optional)
    public static func fromEnvironment() throws -> AWSS3Configuration {
        guard let accessKeyId = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"],
              let secretAccessKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"],
              let region = ProcessInfo.processInfo.environment["AWS_REGION"] else {
            throw StorageError.configurationError("Missing required AWS environment variables")
        }
        
        return AWSS3Configuration(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            region: region,
            defaultBucket: ProcessInfo.processInfo.environment["AWS_DEFAULT_BUCKET"],
            endpoint: ProcessInfo.processInfo.environment["AWS_ENDPOINT"],
            sessionToken: ProcessInfo.processInfo.environment["AWS_SESSION_TOKEN"]
        )
    }
}

/// Configuration for Azure Blob Storage
public struct AzureBlobConfiguration {
    public let accountName: String
    public let accountKey: String?
    public let connectionString: String?
    public let defaultContainer: String?
    public let sasToken: String?  // For SAS-based authentication
    
    public init(
        accountName: String,
        accountKey: String? = nil,
        connectionString: String? = nil,
        defaultContainer: String? = nil,
        sasToken: String? = nil
    ) {
        self.accountName = accountName
        self.accountKey = accountKey
        self.connectionString = connectionString
        self.defaultContainer = defaultContainer
        self.sasToken = sasToken
    }
    
    /// Creates configuration from environment variables
    /// Expected environment variables:
    /// - AZURE_STORAGE_ACCOUNT_NAME
    /// - AZURE_STORAGE_ACCOUNT_KEY or AZURE_STORAGE_CONNECTION_STRING or AZURE_STORAGE_SAS_TOKEN
    /// - AZURE_DEFAULT_CONTAINER (optional)
    public static func fromEnvironment() throws -> AzureBlobConfiguration {
        guard let accountName = ProcessInfo.processInfo.environment["AZURE_STORAGE_ACCOUNT_NAME"] else {
            throw StorageError.configurationError("Missing AZURE_STORAGE_ACCOUNT_NAME environment variable")
        }
        
        let accountKey = ProcessInfo.processInfo.environment["AZURE_STORAGE_ACCOUNT_KEY"]
        let connectionString = ProcessInfo.processInfo.environment["AZURE_STORAGE_CONNECTION_STRING"]
        let sasToken = ProcessInfo.processInfo.environment["AZURE_STORAGE_SAS_TOKEN"]
        
        guard accountKey != nil || connectionString != nil || sasToken != nil else {
            throw StorageError.configurationError("Missing Azure authentication: provide AZURE_STORAGE_ACCOUNT_KEY, AZURE_STORAGE_CONNECTION_STRING, or AZURE_STORAGE_SAS_TOKEN")
        }
        
        return AzureBlobConfiguration(
            accountName: accountName,
            accountKey: accountKey,
            connectionString: connectionString,
            defaultContainer: ProcessInfo.processInfo.environment["AZURE_DEFAULT_CONTAINER"],
            sasToken: sasToken
        )
    }
}
