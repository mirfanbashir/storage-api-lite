import Foundation

/// The main entry point for Storage API Lite
public struct StorageAPILite {
    
    /// Creates a storage client for the specified provider
    /// - Parameter config: Configuration for the storage provider
    /// - Returns: A storage client instance
    public static func createClient(config: StorageConfiguration) throws -> StorageClient {
        switch config {
        case .awsS3(let awsConfig):
            return AWSS3Client(configuration: awsConfig)
        case .azureBlob(let azureConfig):
            return AzureBlobClient(configuration: azureConfig)
        }
    }
    
    /// Creates a storage client with automatic configuration detection
    /// - Parameter provider: The storage provider type
    /// - Returns: A storage client instance
    public static func createClient(provider: StorageProvider) throws -> StorageClient {
        let config = try StorageConfiguration.autoDetect(for: provider)
        return try createClient(config: config)
    }
}
