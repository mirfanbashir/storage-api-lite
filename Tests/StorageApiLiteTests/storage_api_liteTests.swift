import Testing
import Foundation
@testable import StorageApiLite

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

@Test func testAWSS3Configuration() throws {
    // Test AWS S3 configuration creation
    let config = AWSS3Configuration(
        accessKeyId: "test-access-key",
        secretAccessKey: "test-secret-key",
        region: "us-east-1",
        defaultBucket: "test-bucket"
    )
    
    #expect(config.accessKeyId == "test-access-key")
    #expect(config.secretAccessKey == "test-secret-key")
    #expect(config.region == "us-east-1")
    #expect(config.defaultBucket == "test-bucket")
}

@Test func testAzureBlobConfiguration() throws {
    // Test Azure Blob configuration creation
    let config = AzureBlobConfiguration(
        accountName: "testaccount",
        accountKey: "test-account-key",
        defaultContainer: "test-container"
    )
    
    #expect(config.accountName == "testaccount")
    #expect(config.accountKey == "test-account-key")
    #expect(config.defaultContainer == "test-container")
}

@Test func testStorageConfigurationCases() throws {
    // Test storage configuration enum cases
    let awsConfig = AWSS3Configuration(
        accessKeyId: "key",
        secretAccessKey: "secret",
        region: "us-east-1"
    )
    
    let azureConfig = AzureBlobConfiguration(
        accountName: "account",
        accountKey: "key"
    )
    
    let awsStorageConfig = StorageConfiguration.awsS3(awsConfig)
    let azureStorageConfig = StorageConfiguration.azureBlob(azureConfig)
    
    #expect(awsStorageConfig.provider == .awsS3)
    #expect(azureStorageConfig.provider == .azureBlob)
}

@Test func testStorageClientCreation() throws {
    // Test storage client creation
    let awsConfig = AWSS3Configuration(
        accessKeyId: "test-key",
        secretAccessKey: "test-secret",
        region: "us-east-1"
    )
    
    let storageConfig = StorageConfiguration.awsS3(awsConfig)
    let client = try StorageAPILite.createClient(config: storageConfig)
    
    #expect(client is AWSS3Client)
}
