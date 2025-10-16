import Foundation

/// AWS S3 implementation of the StorageClient protocol
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if os(Linux)
import FoundationNetworking
#endif

public class AWSS3Client: StorageClient {
    
    private let configuration: AWSS3Configuration
    private let urlSession: URLSession
    private let baseURL: String
    
    public init(configuration: AWSS3Configuration) {
        self.configuration = configuration
        self.urlSession = URLSession.shared
        
        // Use custom endpoint if provided, otherwise use standard S3 endpoint
        if let endpoint: String = configuration.endpoint {
            self.baseURL = endpoint
        } else {
            // Use the modern S3 endpoint format that works for all regions
            self.baseURL = "https://s3.\(configuration.region).amazonaws.com"
        }
    }
    
    // MARK: - File Operations
    
    public func upload(
        data: Data,
        key: String,
        bucket: String?,
        metadata: [String: String]?
    ) async throws -> UploadResult {
        let bucketName = try resolveBucket(bucket)
        try validateKey(key)
        try validateBucketName(bucketName)
        
        let url = try buildURL(bucket: bucketName, key: key)
        var headers: [String: String] = [:]
        
        // Add content type if not specified
        if let metadata = metadata {
            for (key, value) in metadata {
                if key.lowercased() == "content-type" || key.lowercased() == "contenttype" {
                    headers["Content-Type"] = value
                } else {
                    headers["x-amz-meta-\(key)"] = value
                }
            }
        }
        
        // Default content type if not specified
        if headers["Content-Type"] == nil {
            headers["Content-Type"] = "application/octet-stream"
        }
        
        headers["Content-Length"] = "\(data.count)"
        
        let signedHeaders = try signRequest(
            method: "PUT",
            url: url,
            headers: headers,
            payload: data
        )
        
        let request = try createURLRequest(
            method: "PUT",
            url: url,
            headers: signedHeaders,
            body: data
        )
        
        let (responseData, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: responseData)
        
        let httpResponse = response as! HTTPURLResponse
        let etag = httpResponse.value(forHTTPHeaderField: "ETag")?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        return UploadResult(
            key: key,
            bucket: bucketName,
            etag: etag,
            size: Int64(data.count),
            lastModified: Date(),
            metadata: metadata ?? [:]
        )
    }
    
    public func download(key: String, bucket: String?) async throws -> Data {
        let bucketName = try resolveBucket(bucket)
        try validateKey(key)
        try validateBucketName(bucketName)
        
        let url = try buildURL(bucket: bucketName, key: key)
        let headers: [String: String] = [:]
        
        let signedHeaders = try signRequest(
            method: "GET",
            url: url,
            headers: headers,
            payload: nil
        )
        
        let request = try createURLRequest(
            method: "GET",
            url: url,
            headers: signedHeaders,
            body: nil
        )
        
        let (data, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: data)
        
        return data
    }
    
    public func downloadToFile(key: String, bucket: String?, localURL: URL) async throws {
        let data = try await download(key: key, bucket: bucket)
        try data.write(to: localURL)
    }
    
    public func delete(key: String, bucket: String?) async throws {
        let bucketName = try resolveBucket(bucket)
        try validateKey(key)
        try validateBucketName(bucketName)
        
        let url = try buildURL(bucket: bucketName, key: key)
        let headers: [String: String] = [:]
        
        let signedHeaders = try signRequest(
            method: "DELETE",
            url: url,
            headers: headers,
            payload: nil
        )
        
        let request = try createURLRequest(
            method: "DELETE",
            url: url,
            headers: signedHeaders,
            body: nil
        )
        
        let (data, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: data)
    }
    
    public func exists(key: String, bucket: String?) async throws -> Bool {
        let bucketName = try resolveBucket(bucket)
        try validateKey(key)
        try validateBucketName(bucketName)
        
        let url = try buildURL(bucket: bucketName, key: key)
        let headers: [String: String] = [:]
        
        let signedHeaders = try signRequest(
            method: "HEAD",
            url: url,
            headers: headers,
            payload: nil
        )
        
        let request = try createURLRequest(
            method: "HEAD",
            url: url,
            headers: signedHeaders,
            body: nil
        )
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            let httpResponse = response as! HTTPURLResponse
            return httpResponse.statusCode == 200
        } catch {
            if let storageError = error as? StorageError,
               case .fileNotFound = storageError {
                return false
            }
            throw error
        }
    }
    
    public func getMetadata(key: String, bucket: String?) async throws -> FileMetadata {
        let bucketName = try resolveBucket(bucket)
        try validateKey(key)
        try validateBucketName(bucketName)
        
        let url = try buildURL(bucket: bucketName, key: key)
        let headers: [String: String] = [:]
        
        let signedHeaders = try signRequest(
            method: "HEAD",
            url: url,
            headers: headers,
            payload: nil
        )
        
        let request = try createURLRequest(
            method: "HEAD",
            url: url,
            headers: signedHeaders,
            body: nil
        )
        
        let (_, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: Data())
        
        let httpResponse = response as! HTTPURLResponse
        
        let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length").flatMap { Int64($0) } ?? 0
        let etag = httpResponse.value(forHTTPHeaderField: "ETag")?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
        
        let lastModifiedString = httpResponse.value(forHTTPHeaderField: "Last-Modified")
        let lastModified = parseHTTPDate(lastModifiedString) ?? Date()
        
        // Extract custom metadata
        var customMetadata: [String: String] = [:]
        for (headerName, headerValue) in httpResponse.allHeaderFields {
            if let headerNameString = headerName as? String,
               headerNameString.lowercased().hasPrefix("x-amz-meta-") {
                let metadataKey = String(headerNameString.dropFirst("x-amz-meta-".count))
                customMetadata[metadataKey] = headerValue as? String
            }
        }
        
        return FileMetadata(
            key: key,
            bucket: bucketName,
            size: contentLength,
            lastModified: lastModified,
            etag: etag,
            contentType: contentType,
            metadata: customMetadata
        )
    }
    
    // MARK: - Listing Operations
    
    public func listFiles(
        bucket: String?,
        prefix: String?,
        maxResults: Int?,
        continuationToken: String?
    ) async throws -> FileListResult {
        let bucketName = try resolveBucket(bucket)
        try validateBucketName(bucketName)
        
        var urlComponents = URLComponents(string: "\(baseURL)/\(bucketName)")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "list-type", value: "2")
        ]
        
        if let prefix = prefix {
            queryItems.append(URLQueryItem(name: "prefix", value: prefix))
        }
        
        if let maxResults = maxResults {
            queryItems.append(URLQueryItem(name: "max-keys", value: "\(maxResults)"))
        }
        
        if let continuationToken = continuationToken {
            queryItems.append(URLQueryItem(name: "continuation-token", value: continuationToken))
        }
        
        urlComponents.queryItems = queryItems
        let url = urlComponents.url!
        
        let headers: [String: String] = [:]
        let signedHeaders = try signRequest(
            method: "GET",
            url: url,
            headers: headers,
            payload: nil
        )
        
        let request = try createURLRequest(
            method: "GET",
            url: url,
            headers: signedHeaders,
            body: nil
        )
        
        let (data, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: data)
        
        return try parseListObjectsResponse(data: data, bucket: bucketName, prefix: prefix, continuationToken: continuationToken)
    }
    
    // MARK: - Bucket Operations
    
    public func createBucket(_ bucket: String) async throws {
        try validateBucketName(bucket)
        
        let url = try buildURL(bucket: bucket, key: nil)
        var headers: [String: String] = [:]
        
        // For regions other than us-east-1, we need to specify the location constraint
        var body: Data?
        if configuration.region != "us-east-1" {
            let locationConstraint = """
            <CreateBucketConfiguration>
                <LocationConstraint>\(configuration.region)</LocationConstraint>
            </CreateBucketConfiguration>
            """
            body = locationConstraint.data(using: .utf8)
            headers["Content-Type"] = "application/xml"
            headers["Content-Length"] = "\(body?.count ?? 0)"
        }
        
        let signedHeaders = try signRequest(
            method: "PUT",
            url: url,
            headers: headers,
            payload: body
        )
        
        let request = try createURLRequest(
            method: "PUT",
            url: url,
            headers: signedHeaders,
            body: body
        )
        
        let (responseData, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: responseData)
    }
    
    public func deleteBucket(_ bucket: String) async throws {
        try validateBucketName(bucket)
        
        let url = try buildURL(bucket: bucket, key: nil)
        let headers: [String: String] = [:]
        
        let signedHeaders = try signRequest(
            method: "DELETE",
            url: url,
            headers: headers,
            payload: nil
        )
        
        let request = try createURLRequest(
            method: "DELETE",
            url: url,
            headers: signedHeaders,
            body: nil
        )
        
        let (data, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: data)
    }
    
    public func listBuckets() async throws -> [String] {
        let url = URL(string: baseURL)!
        let headers: [String: String] = [:]
        
        let signedHeaders = try signRequest(
            method: "GET",
            url: url,
            headers: headers,
            payload: nil
        )
        
        let request = try createURLRequest(
            method: "GET",
            url: url,
            headers: signedHeaders,
            body: nil
        )
        
        let (data, response) = try await urlSession.data(for: request)
        try validateResponse(response: response, data: data)
        
        return try parseListBucketsResponse(data: data)
    }
    
    // MARK: - URL Operations
    
    public func generatePresignedURL(
        key: String,
        bucket: String?,
        operation: PresignedURLOperation,
        expirationTime: TimeInterval
    ) async throws -> URL {
        let bucketName = try resolveBucket(bucket)
        try validateKey(key)
        try validateBucketName(bucketName)
        
        let url = try buildURL(bucket: bucketName, key: key)
        let method = operation == .read ? "GET" : "PUT"
        
        _ = Int(Date().timeIntervalSince1970 + expirationTime)
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems = urlComponents.queryItems ?? []
        
        queryItems.append(contentsOf: [
            URLQueryItem(name: "X-Amz-Algorithm", value: "AWS4-HMAC-SHA256"),
            URLQueryItem(name: "X-Amz-Credential", value: "\(configuration.accessKeyId)/\(getCredentialScope())"),
            URLQueryItem(name: "X-Amz-Date", value: getCurrentTimestamp()),
            URLQueryItem(name: "X-Amz-Expires", value: "\(Int(expirationTime))"),
            URLQueryItem(name: "X-Amz-SignedHeaders", value: "host")
        ])
        
        if let sessionToken = configuration.sessionToken {
            queryItems.append(URLQueryItem(name: "X-Amz-Security-Token", value: sessionToken))
        }
        
        urlComponents.queryItems = queryItems
        let unsignedURL = urlComponents.url!
        
        // Generate signature for presigned URL
        let signature = try generatePresignedSignature(
            method: method,
            url: unsignedURL,
            expirationTime: Int(expirationTime)
        )
        
        queryItems.append(URLQueryItem(name: "X-Amz-Signature", value: signature))
        urlComponents.queryItems = queryItems
        
        return urlComponents.url!
    }
    
    // MARK: - Private Helpers
    
    private func resolveBucket(_ bucket: String?) throws -> String {
        guard let bucketName = bucket ?? configuration.defaultBucket else {
            throw StorageError.configurationError("No bucket specified and no default bucket configured")
        }
        return bucketName
    }
    
    private func validateKey(_ key: String) throws {
        guard !key.isEmpty else {
            throw StorageError.invalidKey("Key cannot be empty")
        }
        
        // AWS S3 key validation rules
        if key.contains("//") || key.hasPrefix("/") || key.hasSuffix("/") {
            throw StorageError.invalidKey("Invalid key format: \(key)")
        }
    }
    
    private func validateBucketName(_ bucket: String) throws {
        guard bucket.count >= 3 && bucket.count <= 63 else {
            throw StorageError.invalidBucketName("Bucket name must be between 3 and 63 characters")
        }
        
        guard bucket.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." }) else {
            throw StorageError.invalidBucketName("Bucket name contains invalid characters")
        }
        
        guard !bucket.hasPrefix("-") && !bucket.hasSuffix("-") else {
            throw StorageError.invalidBucketName("Bucket name cannot start or end with a hyphen")
        }
    }
    
    private func buildURL(bucket: String, key: String?) throws -> URL {
        var urlString = "\(baseURL)/\(bucket)"
        if let key = key {
            // Properly encode the key for URL
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
            urlString += "/\(encodedKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidKey("Unable to construct URL for bucket: \(bucket), key: \(key ?? "nil")")
        }
        
        return url
    }
    
    private func signRequest(
        method: String,
        url: URL,
        headers: [String: String],
        payload: Data?
    ) throws -> [String: String] {
        let signer = AWSSignatureV4(
            accessKey: configuration.accessKeyId,
            secretKey: configuration.secretAccessKey,
            sessionToken: configuration.sessionToken,
            region: configuration.region
        )
        
        return signer.signRequest(
            method: method,
            url: url,
            headers: headers,
            payload: payload
        )
    }
    
    private func createURLRequest(
        method: String,
        url: URL,
        headers: [String: String],
        body: Data?
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func validateResponse(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorageError.networkError(NSError(domain: "InvalidResponse", code: -1, userInfo: nil))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 404:
            throw StorageError.fileNotFound(key: "", bucket: nil)
        case 403:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Access denied"
            print("🔍 DEBUG: HTTP 403 Response Body: \(errorMessage)")
            throw StorageError.insufficientPermissions("Access denied: \(errorMessage)")
        case 401:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Invalid AWS credentials"
            print("🔍 DEBUG: HTTP 401 Response Body: \(errorMessage)")
            throw StorageError.invalidCredentials("Invalid AWS credentials: \(errorMessage)")
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🔍 DEBUG: HTTP \(httpResponse.statusCode) Response Body: \(errorMessage)")
            throw StorageError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    private func parseListObjectsResponse(
        data: Data,
        bucket: String,
        prefix: String?,
        continuationToken: String?
    ) throws -> FileListResult {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw StorageError.invalidData("Unable to parse response as UTF-8")
        }
        
        let parser = S3XMLParser()
        return try parser.parseListObjectsV2Response(
            xmlString: xmlString,
            bucket: bucket,
            prefix: prefix,
            continuationToken: continuationToken
        )
    }
    
    private func parseListBucketsResponse(data: Data) throws -> [String] {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw StorageError.invalidData("Unable to parse response as UTF-8")
        }
        
        let parser = S3XMLParser()
        return try parser.parseListBucketsResponse(xmlString: xmlString)
    }
    
    private func parseHTTPDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        return formatter.date(from: dateString)
    }
    
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: Date())
    }
    
    private func getCredentialScope() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateStamp = formatter.string(from: Date())
        return "\(dateStamp)/\(configuration.region)/s3/aws4_request"
    }
    
    private func generatePresignedSignature(
        method: String,
        url: URL,
        expirationTime: Int
    ) throws -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let timestamp = dateFormatter.string(from: date)
        
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "yyyyMMdd"
        shortDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateStamp = shortDateFormatter.string(from: date)
        
        let credentialScope = "\(dateStamp)/\(configuration.region)/s3/aws4_request"
        let credential = "\(configuration.accessKeyId)/\(credentialScope)"
        
        // Create the canonical request for presigned URL
        let canonicalRequest = try createPresignedCanonicalRequest(
            method: method,
            url: url,
            timestamp: timestamp,
            credential: credential,
            expirationTime: expirationTime
        )
        
        // Create string to sign
        let hashedCanonicalRequest = CrossPlatformCrypto.sha256Hash(data: canonicalRequest.data(using: .utf8)!)
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            timestamp,
            credentialScope,
            hashedCanonicalRequest
        ].joined(separator: "\n")
        
        // Create signing key
        let signingKey = createPresignedSigningKey(
            secretKey: configuration.secretAccessKey,
            dateStamp: dateStamp,
            region: configuration.region
        )
        
        // Calculate signature
        let signature = CrossPlatformCrypto.hmacSHA256(data: stringToSign.data(using: .utf8)!, key: signingKey)
            .map { String(format: "%02x", $0) }.joined()
        
        return signature
    }
    
    private func createPresignedCanonicalRequest(
        method: String,
        url: URL,
        timestamp: String,
        credential: String,
        expirationTime: Int
    ) throws -> String {
        // Build canonical URI
        let canonicalURI: String
        if url.path.isEmpty {
            canonicalURI = "/"
        } else {
            // Split the path, encode each component, then rejoin
            let pathComponents = url.path.split(separator: "/", omittingEmptySubsequences: false)
            let encodedComponents = pathComponents.map { component in
                String(component).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(component)
            }
            canonicalURI = "/" + encodedComponents.dropFirst().joined(separator: "/")
        }
        
        // Build canonical query string for presigned URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw StorageError.configurationError("Invalid URL for presigned signature")
        }
        
        let canonicalQueryString = queryItems
            .sorted { $0.name < $1.name }
            .map { item in
                let name = item.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~"))) ?? item.name
                let value = item.value?.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~"))) ?? ""
                return "\(name)=\(value)"
            }
            .joined(separator: "&")
        
        // For presigned URLs, we only include the host header
        let canonicalHeaders = "host:\(url.host ?? "")"
        let signedHeaders = "host"
        
        // For presigned URLs, payload is always UNSIGNED-PAYLOAD
        let payloadHash = "UNSIGNED-PAYLOAD"
        
        return [
            method,
            canonicalURI,
            canonicalQueryString,
            canonicalHeaders,
            "",
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")
    }
    
    private func createPresignedSigningKey(
        secretKey: String,
        dateStamp: String,
        region: String
    ) -> Data {
        let kDate = CrossPlatformCrypto.hmacSHA256(data: dateStamp.data(using: .utf8)!, key: "AWS4\(secretKey)".data(using: .utf8)!)
        let kRegion = CrossPlatformCrypto.hmacSHA256(data: region.data(using: .utf8)!, key: kDate)
        let kService = CrossPlatformCrypto.hmacSHA256(data: "s3".data(using: .utf8)!, key: kRegion)
        let kSigning = CrossPlatformCrypto.hmacSHA256(data: "aws4_request".data(using: .utf8)!, key: kService)
        return kSigning
    }
}
