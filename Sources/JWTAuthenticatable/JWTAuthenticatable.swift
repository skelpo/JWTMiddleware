import Authentication
import Vapor
import JWT

public protocol IdentifiableJWTPayload: JWTPayload {
    associatedtype ID
    
    var id: ID { get }
}

public protocol JWTAuthenticatable: Authenticatable, Content where Payload.ID == Self.ID {
    associatedtype AuthBody
    associatedtype Payload: IdentifiableJWTPayload
    
    func accessToken(on request: Request) throws -> EventLoopFuture<Payload>
    
    static func authBody(from request: Request)throws -> AuthBody?
    static func authenticate(from payload: Payload, on request: Request)throws -> Future<Self>
    static func authenticate(from body: AuthBody, on reques: Request)throws -> Future<Self>
}


