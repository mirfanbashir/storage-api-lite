import Testing
import Foundation
@testable import StorageApiLite

@Test("S3 XML Parser") 
func testS3XMLParser() throws {
    let parser = S3XMLParser()
    
    // Test parsing a simple list buckets response
    let listBucketsXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListAllMyBucketsResult>
        <Buckets>
            <Bucket>
                <Name>test-bucket-1</Name>
                <CreationDate>2023-01-01T00:00:00.000Z</CreationDate>
            </Bucket>
            <Bucket>
                <Name>test-bucket-2</Name>
                <CreationDate>2023-01-02T00:00:00.000Z</CreationDate>
            </Bucket>
        </Buckets>
    </ListAllMyBucketsResult>
    """
    
    let buckets = try parser.parseListBucketsResponse(xmlString: listBucketsXML)
    #expect(buckets.count == 2)
    #expect(buckets.contains("test-bucket-1"))
    #expect(buckets.contains("test-bucket-2"))
}

@Test("S3 File List XML Parser") 
func testS3FileListXMLParser() throws {
    let parser = S3XMLParser()
    
    // Test parsing a list objects response
    let listObjectsXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListBucketResult>
        <Name>test-bucket</Name>
        <IsTruncated>false</IsTruncated>
        <Contents>
            <Key>file1.txt</Key>
            <Size>1024</Size>
            <LastModified>2023-01-01T12:00:00.000Z</LastModified>
            <ETag>"d41d8cd98f00b204e9800998ecf8427e"</ETag>
        </Contents>
        <Contents>
            <Key>file2.txt</Key>
            <Size>2048</Size>
            <LastModified>2023-01-02T12:00:00.000Z</LastModified>
            <ETag>"098f6bcd4621d373cade4e832627b4f6"</ETag>
        </Contents>
    </ListBucketResult>
    """
    
    let result = try parser.parseListObjectsV2Response(
        xmlString: listObjectsXML,
        bucket: "test-bucket",
        prefix: nil,
        continuationToken: nil
    )
    
    #expect(result.files.count == 2)
    #expect(result.bucket == "test-bucket")
    #expect(result.isTruncated == false)
    #expect(result.files[0].key == "file1.txt")
    #expect(result.files[0].size == 1024)
    #expect(result.files[1].key == "file2.txt")
    #expect(result.files[1].size == 2048)
}
