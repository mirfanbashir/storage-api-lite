import Foundation
import StorageApiLite

@main
struct StorageCLI {
    static func main() async {
        do {
            let arguments = CommandLine.arguments
            
            // Parse operation argument
            let operation = parseOperation(from: arguments)
            
            // Handle help without initializing client
            if case .help = operation {
                printUsage()
                return
            }
            
            let cli = try StorageClientTester()
            
            switch operation {
            case .upload:
                try await cli.runUploadTest()
            case .help:
                printUsage() // This won't be reached due to early return above
            }
        } catch {
            print("❌ Error: \(error)")
            exit(1)
        }
    }
    
    enum Operation {
        case upload
        case help
    }
    
    static func parseOperation(from arguments: [String]) -> Operation {
        // Skip the first argument (program name)
        let operationArgs = arguments.dropFirst()
        
        for arg in operationArgs {
            switch arg.lowercased() {
            case "upload", "--upload":
                return .upload
            case "help", "--help", "-h":
                return .help
            default:
                continue
            }
        }
        
        // No valid operation found, show help
        return .help
    }
    
    static func printUsage() {
        print("📦 Storage API Lite CLI")
        print("")
        print("USAGE:")
        print("  swift run storage-cli <operation> [options]")
        print("")
        print("OPERATIONS:")
        print("  upload                    Test file upload operation")
        print("  help, --help, -h         Show this help message")
        print("")
        print("EXAMPLES:")
        print("  swift run storage-cli upload")
        print("  swift run storage-cli diagnose")
        print("")
        print("ENVIRONMENT VARIABLES:")
        print("  STORAGE_PROVIDER         Provider type (s3, azure)")
        print("  AWS_ACCESS_KEY_ID        AWS access key")
        print("  AWS_SECRET_ACCESS_KEY    AWS secret key")
        print("  AWS_REGION              AWS region")
        print("  S3_BUCKET               S3 bucket name")
        print("")
        print("For detailed setup instructions, see CLI_README.md")
    }
}

struct StorageClientTester {
    private let client: StorageClient
    private let testBucket: String
    private let testKey: String = "test-file-\(UUID().uuidString).txt"
    private let testData: Data
    
    init() throws {
        // Read configuration from environment variables
        let config = try EnvironmentConfig.load()
        
        switch config.provider {
        case .s3:
            let s3Config = AWSS3Configuration(
                accessKeyId: config.accessKey!,
                secretAccessKey: config.secretKey!,
                region: config.region!,
                defaultBucket: config.bucket,
                endpoint: config.endpoint,
                sessionToken: config.sessionToken
            )
            self.client = AWSS3Client(configuration: s3Config)
        case .azure:
            let azureConfig = AzureBlobConfiguration(
                accountName: config.accountName!,
                accountKey: config.accessKey!,
                defaultContainer: config.container
            )
            self.client = AzureBlobClient(configuration: azureConfig)
        }
        
        self.testBucket = config.testBucket ?? config.bucket ?? "default-test-bucket"
        self.testData = "Hello, Storage API Lite! This is test data from CLI.\nTimestamp: \(Date())".data(using: .utf8)!
    }
    
    func runDiagnostics() async throws {
        print("🔧 Starting Comprehensive Diagnostics")
        print("📦 Provider: \(try EnvironmentConfig.load().provider)")
        print("🪣 Target Bucket: \(testBucket)")
        print("")
        
        // Run all diagnostic tests
        try await testBucketOperations()
        try await testFileOperations()
        try await testListingOperations()
        try await testURLOperations()
        
        // Clean up test file
        try await client.delete(key: testKey, bucket: testBucket)
        print("🗑️  Cleaned up test file from storage")
        
        print("")
        print("✅ All diagnostics completed successfully!")
        print("🎉 Storage API Lite is working correctly on this platform")
    }
    
    func runUploadTest() async throws {
        print("🚀 Testing Upload Operation")
        print("📦 Provider: \(try EnvironmentConfig.load().provider)")
        print("🪣 Target Bucket: \(testBucket)")
        print("🔑 Test Key: \(testKey)")
        print("")
        
        // Test upload operation
        print("📁 Testing File Upload...")
        
        print("  ⬆️  Uploading file...")
        print("     📊 Data size: \(testData.count) bytes")
        
        let metadata = [
            "content-type": "text/plain",
            "source": "storage-cli",
            "operation": "upload-test",
            "test-id": UUID().uuidString
        ]
        
        do {
            let uploadResult = try await client.upload(
                data: testData,
                key: testKey,
                bucket: testBucket,
                metadata: metadata
            )
            
            print("     ✅ Upload completed successfully!")
            print("     📄 Key: \(uploadResult.key)")
            print("     📊 Size: \(uploadResult.size) bytes")
            print("     🏷️  ETag: \(uploadResult.etag ?? "N/A")")
            print("     📅 Last Modified: \(uploadResult.lastModified)")
            print("     🏗️  Bucket: \(uploadResult.bucket)")
            
            if !uploadResult.metadata.isEmpty {
                print("     📋 Metadata:")
                for (key, value) in uploadResult.metadata {
                    print("        \(key): \(value)")
                }
            }
            
            // Verify the upload by checking if file exists
            print("  🔍 Verifying upload...")
            let exists = try await client.exists(key: testKey, bucket: testBucket)
            if exists {
                print("     ✅ File exists in storage")
            } else {
                print("     ❌ File not found in storage")
            }

            try await client.delete(key: testKey, bucket: testBucket)
            print("  🗑️  Cleaned up test file from storage")
            
            print("")
            print("✅ Upload test completed successfully!")
            print("💡 File '\(testKey)' has been uploaded to bucket '\(testBucket)'")
            print("💡 Use other operations to download, delete, or list files")
            
        } catch let error as StorageError {
            print("     ❌ Upload failed with StorageError: \(error)")
            throw error
        }
    }
    
    func run() async throws {
        print("⚠️  The full test suite has been replaced with individual operations.")
        print("Please specify an operation:")
        print("")
        StorageCLI.printUsage()
    }
    
    // MARK: - Bucket Operations Tests
    
    func testBucketOperations() async throws {
        print("🪣 Testing Bucket Operations...")
        
        // List buckets
        print("  📋 Listing buckets...")
        let buckets = try await client.listBuckets()
        print("     Found \(buckets.count) buckets: \(buckets.joined(separator: ", "))")
        
        // Create test bucket if it doesn't exist
        if !buckets.contains(testBucket) {
            print("  ➕ Creating test bucket: \(testBucket)")
            try await client.createBucket(testBucket)
        } else {
            print("  ✅ Test bucket already exists: \(testBucket)")
        }
        
        // List buckets again to verify creation
        let bucketsAfter = try await client.listBuckets()
        print("     Buckets after creation: \(bucketsAfter.count) total")
        
        print("")
    }
    
    // MARK: - File Operations Tests
    
    func testFileOperations() async throws {
        print("📁 Testing File Operations...")
        
        // Upload file
        print("  ⬆️  Uploading file...")
        let metadata = [
            "content-type": "text/plain",
            "source": "storage-cli",
            "test-id": UUID().uuidString
        ]
        
        let uploadResult = try await client.upload(
            data: testData,
            key: testKey,
            bucket: testBucket,
            metadata: metadata
        )
        
        print("     Uploaded: \(uploadResult.key)")
        print("     Size: \(uploadResult.size) bytes")
        print("     ETag: \(uploadResult.etag ?? "N/A")")
        print("     Last Modified: \(uploadResult.lastModified)")
        
        // Check if file exists
        print("  🔍 Checking if file exists...")
        let exists = try await client.exists(key: testKey, bucket: testBucket)
        print("     File exists: \(exists)")
        
        // Get file metadata
        print("  📊 Getting file metadata...")
        let fileMetadata = try await client.getMetadata(key: testKey, bucket: testBucket)
        print("     Key: \(fileMetadata.key)")
        print("     Size: \(fileMetadata.size) bytes")
        print("     Content Type: \(fileMetadata.contentType ?? "N/A")")
        print("     Custom Metadata: \(fileMetadata.metadata)")
        
        // Download file
        print("  ⬇️  Downloading file...")
        let downloadedData = try await client.download(key: testKey, bucket: testBucket)
        let downloadedString = String(data: downloadedData, encoding: .utf8) ?? "Unable to decode"
        print("     Downloaded \(downloadedData.count) bytes")
        print("     Content preview: \(String(downloadedString.prefix(50)))...")
        
        // Download to local file
        print("  💾 Downloading to local file...")
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("storage-cli-test.txt")
        try await client.downloadToFile(key: testKey, bucket: testBucket, localURL: tempURL)
        let localFileSize = try FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? Int64 ?? 0
        print("     Downloaded to: \(tempURL.path)")
        print("     Local file size: \(localFileSize) bytes")
        
        // Clean up local file
        try? FileManager.default.removeItem(at: tempURL)
        
        print("")
    }
    
    // MARK: - Listing Operations Tests
    
    func testListingOperations() async throws {
        print("📋 Testing Listing Operations...")
        
        // List files in bucket
        print("  📄 Listing files in bucket...")
        let fileList = try await client.listFiles(
            bucket: testBucket,
            prefix: nil,
            maxResults: 10,
            continuationToken: nil
        )
        
        print("     Found \(fileList.files.count) files")
        print("     Is truncated: \(fileList.isTruncated)")
        print("     Continuation token: \(fileList.nextContinuationToken ?? "N/A")")
        
        for (index, file) in fileList.files.enumerated() {
            print("     File \(index + 1): \(file.key) (\(file.size) bytes)")
        }
        
        // List files with prefix filter
        let testPrefix = String(testKey.prefix(10))
        print("  🔍 Listing files with prefix '\(testPrefix)'...")
        let filteredList = try await client.listFiles(
            bucket: testBucket,
            prefix: testPrefix,
            maxResults: 5,
            continuationToken: nil
        )
        
        print("     Found \(filteredList.files.count) files with prefix")
        
        print("")
    }
    
    // MARK: - URL Operations Tests
    
    func testURLOperations() async throws {
        print("🔗 Testing URL Operations...")
        
        // Generate presigned URL for reading
        print("  📖 Generating presigned URL for reading...")
        let readURL = try await client.generatePresignedURL(
            key: testKey,
            bucket: testBucket,
            operation: .read,
            expirationTime: 3600 // 1 hour
        )
        print("     Read URL: \(readURL)")
        
        // Generate presigned URL for writing
        print("  ✍️  Generating presigned URL for writing...")
        let writeKey = "presigned-test-\(UUID().uuidString).txt"
        let writeURL = try await client.generatePresignedURL(
            key: writeKey,
            bucket: testBucket,
            operation: .write,
            expirationTime: 1800 // 30 minutes
        )
        print("     Write URL: \(writeURL)")
        
        print("")
    }
    
    // MARK: - Cleanup
    
    private func printCleanupMessage() {
        print("💡 Test file '\(testKey)' left in bucket for inspection")
        print("   Use --cleanup flag to remove test files (feature not implemented)")
    }
}

// MARK: - Environment Configuration

struct EnvironmentConfig {
    enum Provider: String, CaseIterable {
        case s3 = "s3"
        case azure = "azure"
    }
    
    let provider: Provider
    let accessKey: String?
    let secretKey: String?
    let region: String?
    let bucket: String?
    let sessionToken: String?
    let endpoint: String?
    let accountName: String?
    let container: String?
    let testBucket: String?
    
    static func load() throws -> EnvironmentConfig {
        let providerString = ProcessInfo.processInfo.environment["STORAGE_PROVIDER"] ?? "s3"
        
        guard let provider = Provider(rawValue: providerString.lowercased()) else {
            throw CLIError.invalidProvider(providerString, available: Provider.allCases.map(\.rawValue))
        }
        
        switch provider {
        case .s3:
            return try loadS3Config(provider: provider)
        case .azure:
            return try loadAzureConfig(provider: provider)
        }
    }
    
    private static func loadS3Config(provider: Provider) throws -> EnvironmentConfig {
        guard let accessKey = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"] else {
            throw CLIError.missingEnvironmentVariable("AWS_ACCESS_KEY_ID")
        }
        
        guard let secretKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"] else {
            throw CLIError.missingEnvironmentVariable("AWS_SECRET_ACCESS_KEY")
        }
        
        let region = ProcessInfo.processInfo.environment["AWS_REGION"] ?? "us-east-1"
        
        return EnvironmentConfig(
            provider: provider,
            accessKey: accessKey,
            secretKey: secretKey,
            region: region,
            bucket: ProcessInfo.processInfo.environment["S3_BUCKET"],
            sessionToken: ProcessInfo.processInfo.environment["AWS_SESSION_TOKEN"],
            endpoint: ProcessInfo.processInfo.environment["S3_ENDPOINT"],
            accountName: nil,
            container: nil,
            testBucket: ProcessInfo.processInfo.environment["TEST_BUCKET"]
        )
    }
    
    private static func loadAzureConfig(provider: Provider) throws -> EnvironmentConfig {
        guard let accountName = ProcessInfo.processInfo.environment["AZURE_ACCOUNT_NAME"] else {
            throw CLIError.missingEnvironmentVariable("AZURE_ACCOUNT_NAME")
        }
        
        guard let accessKey = ProcessInfo.processInfo.environment["AZURE_ACCESS_KEY"] else {
            throw CLIError.missingEnvironmentVariable("AZURE_ACCESS_KEY")
        }
        
        return EnvironmentConfig(
            provider: provider,
            accessKey: accessKey,
            secretKey: nil,
            region: nil,
            bucket: nil,
            sessionToken: nil,
            endpoint: nil,
            accountName: accountName,
            container: ProcessInfo.processInfo.environment["AZURE_CONTAINER"],
            testBucket: ProcessInfo.processInfo.environment["TEST_CONTAINER"]
        )
    }
}

// MARK: - CLI Errors

enum CLIError: Error, CustomStringConvertible {
    case missingEnvironmentVariable(String)
    case invalidProvider(String, available: [String])
    
    var description: String {
        switch self {
        case .missingEnvironmentVariable(let variable):
            return "Missing required environment variable: \(variable)"
        case .invalidProvider(let provider, let available):
            return "Invalid provider '\(provider)'. Available: \(available.joined(separator: ", "))"
        }
    }
}
