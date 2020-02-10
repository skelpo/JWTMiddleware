import Foundation
import Vapor
import JWT

struct Payload: JWTPayload {
    let firstname: String?
    let lastname: String?
    let email: String
    let role: String
    let id: Int
    let status: Int = 0
    let exp: String
    let iat: String
    
    init(id: Int, email: String, role: String) {
        self.id = id
        self.email = email
        self.role = role
        self.firstname = nil
        self.lastname = nil
        self.exp = String(Date().addingTimeInterval(60*60*24).timeIntervalSince1970)
        self.iat = String(Date().timeIntervalSince1970)
    }
    
    func verify(using signer: JWTSigner) throws {
        let expiration = Date(timeIntervalSince1970: Double(self.exp)!)
        try ExpirationClaim(value: expiration).verifyNotExpired()
    }
}
