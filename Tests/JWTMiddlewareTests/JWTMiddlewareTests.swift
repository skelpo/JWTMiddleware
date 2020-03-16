import XCTest
import JWT
import Vapor
import XCTVapor
import CNIOBoringSSL
@testable import JWTMiddleware
@testable import JWTKit

struct TestPayload: JWTPayload {
    let id: UUID
    let exp: TimeInterval
    
    init(id: UUID, exp: TimeInterval) {
        self.id = id
        self.exp = exp
    }
    
    func verify(using signer: JWTSigner) throws {
        _ = SubjectClaim(value: self.id.uuidString) // Nothing to verify here.
        try ExpirationClaim(value: Date(timeIntervalSince1970: self.exp)).verifyNotExpired()
    }
}

final class JWTMiddlewareTests: XCTestCase {
    
    var tester: Application!
    
    override func setUpWithError() throws {
        // CryptoKit only generates EC keys and I don't know how to turn the raw representation into JWKS.
        var exp: BIGNUM = .init(); CNIOBoringSSL_BN_set_u64(&exp, 0x10001)
        var rsa: RSA = .init(); CNIOBoringSSL_RSA_generate_key_ex(&rsa, 4096, &exp, nil)
        
        let dBytes: [UInt8] = .init(unsafeUninitializedCapacity: Int(CNIOBoringSSL_BN_num_bytes(rsa.d))) { $1 = CNIOBoringSSL_BN_bn2bin(rsa.d, $0.baseAddress!) }
        let nBytes: [UInt8] = .init(unsafeUninitializedCapacity: Int(CNIOBoringSSL_BN_num_bytes(rsa.n))) { $1 = CNIOBoringSSL_BN_bn2bin(rsa.n, $0.baseAddress!) }
        struct LocalJWKS: Codable {
            struct LocalJWK: Codable { let kty, d, e, n, use, kid, alg: String }
            let keys: [LocalJWK]
        }
        let keyset = LocalJWKS(keys: [.init(kty: "RSA", d: String(bytes: dBytes.base64URLEncodedBytes(), encoding: .utf8)!, e: "AQAB", n: String(bytes: nBytes.base64URLEncodedBytes(), encoding: .utf8)!, use: "sig", kid: "jwttest", alg: "RS256")])
        let json = try JSONEncoder().encode(keyset)
        
        tester = Application(.testing)
        try tester.jwt.signers.use(jwksJSON: String(data: json, encoding: .utf8)!)
    }
    
    override func tearDownWithError() throws {
        tester?.shutdown()
    }

    func testPayloadValidationUnexpired() throws {
        let testPayload = TestPayload(id: UUID(), exp: Date(timeIntervalSinceNow: 10.0).timeIntervalSince1970)
        
        tester.middleware.use(JWTMiddleware<TestPayload>())
        tester.get("hello") { _ in "world" }
        
        let token = try tester.jwt.signers.sign(testPayload, kid: "jwttest")
        
        _ = try XCTUnwrap(tester.testable(method: .inMemory).test(.GET, "/hello", headers: ["Authorization": "Bearer \(token)"]) { res in
            XCTAssertEqual(res.body.string, "world")
        })
    }

    func testPayloadValidationExpired() throws {
        let testPayload = TestPayload(id: UUID(), exp: Date(timeIntervalSinceNow: -10.0).timeIntervalSince1970)

        tester.middleware.use(JWTMiddleware<TestPayload>())
        tester.get("hello") { _ in "world" }
        
        let token = try tester.jwt.signers.sign(testPayload, kid: "jwttest")
        
        _ = try XCTUnwrap(tester.testable(method: .inMemory).test(.GET, "/hello", headers: ["Authorization": "Bearer \(token)"]) { res in
            XCTAssertEqual(res.status, .unauthorized)
            
            struct JWTErrorResponse: Codable {
                let error: Bool
                let reason: String
            }

            guard let content = try? XCTUnwrap(res.content.decode(JWTErrorResponse.self)) else {
                return
            }
            XCTAssertEqual(content.error, true)
            XCTAssertEqual(content.reason, "exp claim verification failed: expired")
        })
    }
}
