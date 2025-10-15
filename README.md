# Storage API Lite

A lightweight, cross-platform Swift package providing a unified API for cloud storage solutions. Currently supports AWS S3 with full feature parity including uploads, downloads, presigned URLs, and comprehensive bucket operations.

## Features

- 🚀 **Lightweight and performant** - Zero external dependencies, optimized for speed
- ☁️ **AWS S3 Complete** - Full S3 API support with native Swift implementation
- 📱 **Cross-platform** - iOS 15+, macOS 12+, Linux, tvOS 15+, watchOS 8+
- 🛡️ **Type-safe Swift API** - Comprehensive error handling and data validation
- 🔧 **Easy configuration** - Environment variables or programmatic setup
- 🔐 **Secure authentication** - AWS Signature V4, session tokens, custom endpoints
- 📄 **Rich metadata support** - Custom headers and file metadata
- 🔗 **Presigned URLs** - Secure, time-limited access for GET and PUT operations
- ⚡ **Async/await ready** - Modern Swift concurrency support
- 🧪 **Thoroughly tested** - Unit tests and CLI integration testing
- 🔧 **CLI Tool included** - Complete command-line interface for testing and automation

## Supported Platforms

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- Linux

## Testing
To test in docker, use the following command from the source root.

```bash
docker-compose -f ./docker/docker-compose.yml run test
```

To run on mac simply

```bash
swift test
```

## CLI Tool

The package includes a command-line interface for testing all StorageClient APIs.

### Quick CLI Usage

```bash
# Build the CLI
swift build --product storage-cli

# Set environment variables for S3
export STORAGE_PROVIDER=s3
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=us-west-2
export S3_BUCKET=my-test-bucket

# Test file upload
swift run storage-cli upload
```

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mirfanbashir/storage-api-lite.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["StorageApiLite"]
    )
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/mirfanbashir/storage-api-lite.git`

## Quick Start

```swift
import StorageApiLite

// Configure AWS S3
let awsConfig = AWSS3Configuration(
    accessKeyId: "your-access-key",
    secretAccessKey: "your-secret-key",
    region: "us-east-1",
    defaultBucket: "my-bucket"
)

// Create S3 client
let s3Client = try StorageAPILite.createClient(config: .awsS3(awsConfig))

// Or use environment-based configuration
let autoClient = try StorageAPILite.createClient(provider: .awsS3)

// Upload a file
let data = "Hello, World!".data(using: .utf8)!
let result = try await s3Client.upload(
    data: data,
    key: "hello.txt",
    bucket: nil, // Uses default bucket
    metadata: ["contentType": "text/plain"]
)

// Download a file
let downloadedData = try await s3Client.download(key: "hello.txt", bucket: nil)
let content = String(data: downloadedData, encoding: .utf8)

// List files
let fileList = try await s3Client.listFiles(
    bucket: nil,
    prefix: "documents/",
    maxResults: 100,
    continuationToken: nil
)

// Use convenience methods
try await s3Client.uploadString("Hello, Swift!", key: "greeting.txt")
let greeting = try await s3Client.downloadString(key: "greeting.txt")

// Generate presigned URLs
let downloadURL = try await s3Client.generatePresignedURL(
    key: "my-file.txt",
    bucket: nil,
    operation: .read,
    expirationTime: 3600 // 1 hour
)

let uploadURL = try await s3Client.generatePresignedURL(
    key: "new-file.txt",
    bucket: nil, 
    operation: .write,
    expirationTime: 3600
)

// Delete files
try await s3Client.deleteFile(key: "old-file.txt", bucket: nil)

// Check if file exists
let exists = try await s3Client.fileExists(key: "my-file.txt", bucket: nil)
```

### Environment Variables

For automatic configuration, set these environment variables:

**AWS S3:**
- `AWS_ACCESS_KEY_ID` - Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret access key  
- `AWS_REGION` - AWS region (e.g., `us-east-1`, `eu-west-1`)
- `AWS_DEFAULT_BUCKET` (optional) - Default S3 bucket name
- `AWS_ENDPOINT` (optional) - Custom endpoint for S3-compatible services
- `AWS_SESSION_TOKEN` (optional) - For temporary/federated credentials

## API Reference

### Core Operations

- `upload(data:key:bucket:metadata:)` - Upload data to storage
- `download(key:bucket:)` - Download data from storage  
- `uploadString(_:key:bucket:metadata:)` - Upload string content
- `downloadString(key:bucket:)` - Download string content
- `deleteFile(key:bucket:)` - Delete a file
- `fileExists(key:bucket:)` - Check if file exists
- `listFiles(bucket:prefix:maxResults:continuationToken:)` - List files with pagination
- `generatePresignedURL(key:bucket:operation:expirationTime:)` - Generate presigned URLs

### Bucket Operations

- `createBucket(_:region:)` - Create a new bucket
- `deleteBucket(_:)` - Delete an empty bucket  
- `listBuckets()` - List all accessible buckets

### Error Handling

All operations throw `StorageError` with specific error types:
- `.invalidKey` - Invalid file key format
- `.invalidBucket` - Invalid bucket name
- `.fileNotFound` - File doesn't exist
- `.insufficientPermissions` - Access denied
- `.networkError` - Network connectivity issues
- `.configurationError` - Invalid configuration

For detailed API documentation, see the inline documentation in the source code.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the terms specified in the LICENSE file.

## Version 1.0.0 - AWS S3 Complete ✅

**Fully Implemented Features:**
- ✅ File upload/download operations
- ✅ String upload/download convenience methods
- ✅ File existence checks and deletion
- ✅ Bucket creation, deletion, and listing
- ✅ File listing with pagination support
- ✅ Presigned URL generation (GET and PUT)
- ✅ AWS Signature Version 4 authentication
- ✅ Custom endpoints (S3-compatible services)
- ✅ Session token support for temporary credentials
- ✅ Cross-platform compatibility (iOS, macOS, Linux, tvOS, watchOS)
- ✅ Comprehensive error handling
- ✅ CLI tool for testing and automation
- ✅ Zero external dependencies

## Future Roadmap

**Version 1.1.0 - Enhanced S3 Features**
- [ ] Multipart uploads for large files (>5GB)
- [ ] Server-side encryption options
- [ ] Object tagging support
- [ ] Advanced metadata operations

**Version 1.2.0 - Performance & Reliability**
- [ ] Connection pooling and retry logic
- [ ] Request timeout configuration
- [ ] Progress callbacks for large transfers
- [ ] Bandwidth throttling

**Version 2.0.0 - Multi-Cloud Support**
- [ ] Azure Blob Storage integration
- [ ] Google Cloud Storage support
- [ ] Unified multi-cloud interface

**Additional Providers (Future)**
- [ ] Cloudflare R2
- [ ] Wasabi Cloud Storage (100% S3 API compatible)
- [ ] Google Cloud Storage (S3-compatible XML API)
- [ ] MinIO and other S3-compatible services
- [ ] Local filesystem adapter

