//
//  ContentManager.swift
//  HelloAssumeRole
//
//  Created by Kaz Yoshikawa on 2024/06/22.
//

import Foundation
import AWSClientRuntime
import AWSSDKIdentity
import AWSS3
import AWSSTS
import Smithy
import SmithyIdentity

class ContentManager: ObservableObject {

	struct Item: Codable, Hashable {
		let uuid: UUID
		let timestamp: Date
		var timestampString: String {
			let formater = DateFormatter()
			formater.dateStyle = .long
			formater.timeStyle = .long
			return formater.string(from: self.timestamp)
		}
		var key: String {
			return (self.uuid.uuidString as NSString).appendingPathExtension("plist")!
		}
	}

	let accessKey: String = "<< YOUR_ACCESS_KEY >>"
	let secretKey: String = "<< YOUR-SECRET_KEY >>"
	let region: String = "<< REGION >>"
	let roleArn: String = "<< YOUR_ROLE_ARN >>"
	let bucket = "<< YOUR_BUKET >>"

	static let shared = ContentManager()
		
	private init() {
	}
	func makeSTSClient() throws -> STSClient {
		let identity = AWSCredentialIdentity(accessKey: self.accessKey, secret: self.secretKey)
		let resolver = try StaticAWSCredentialIdentityResolver(identity)
		let configuration = try STSClient.STSClientConfiguration(awsCredentialIdentityResolver: resolver, region: self.region, signingRegion: self.region)
		let stsClient = STSClient(config: configuration)
		return stsClient
	}
	func assumeRole() async throws -> STSClientTypes.Credentials {
		let stsClient = try self.makeSTSClient()
		let output = try await stsClient.assumeRole(input: AssumeRoleInput(roleArn: self.roleArn, roleSessionName: "content.manager"))
		guard let credentials = output.credentials else {
			throw NSError(domain: "ContentManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to assume role"])
		}
		return credentials
	}
	func makeS3Client() async throws -> S3Client {
		let credentials = try await self.assumeRole()
		guard let accessKeyId = credentials.accessKeyId, let secret = credentials.secretAccessKey, let sessionToken = credentials.sessionToken
		else { fatalError() }
		let identity = AWSCredentialIdentity(accessKey: accessKeyId, secret: secret, sessionToken: sessionToken)
		let resolver = try StaticAWSCredentialIdentityResolver(identity)
		let configuration = try await S3Client.S3ClientConfiguration(awsCredentialIdentityResolver: resolver, region: self.region, signingRegion: self.region)
		let s3Client = S3Client(config: configuration)
		return s3Client
	}
	private var _s3Client: S3Client?
	func s3Client() async throws -> S3Client {
		if let s3Client = self._s3Client { return s3Client }
		let s3Client = try await self.makeS3Client()
		self._s3Client = s3Client
		return s3Client
	}
	func listItems() async throws -> [String] {
		let result = try await self.s3Client().listObjectsV2(input: ListObjectsV2Input(bucket: self.bucket))
		return (result.contents ?? []).compactMap { $0.key }
	}
	func getItem(key: String) async throws -> Item? {
		let result = try await self.s3Client().getObject(input: GetObjectInput(bucket: self.bucket, key: key))
		guard let binary = try await result.body?.readData()
		else { throw NSError(domain: "getItem", code: -1, userInfo: [NSLocalizedDescriptionKey : "no body data"]) }
		guard let item = try? PropertyListDecoder().decode(Item.self, from: binary)
		else { throw NSError(domain: "getItem", code: -1, userInfo: [NSLocalizedDescriptionKey : "item can't be decoded"]) }
		assert(UUID(uuidString: (key as NSString).deletingPathExtension) == item.uuid) // TLDR: assume key name represent uuid
		return item
	}
	func putItem(_ item: Item) async throws {
		let binary = try PropertyListEncoder().encode(item)
		let result = try await self.s3Client().putObject(input: PutObjectInput(body: ByteStream.data(binary), bucket: self.bucket, key: item.key))
		print(result)
	}
	func deleteItem(_ item: Item) async throws {
		let key = (item.uuid.uuidString as NSString).appendingPathExtension("plist")
		let _ = try await self.s3Client().deleteObject(input: DeleteObjectInput(bucket: self.bucket, key: item.key))
	}
	func allItems() async throws -> [Item] {
		let keys = try await listItems()
		var items: [Item] = []
		for key in keys {
			if let item = try await getItem(key: key) {
				items.append(item)
			}
		}
		return items
	}
}
