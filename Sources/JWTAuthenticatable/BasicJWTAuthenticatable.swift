import VaporRequestStorage
import Authentication
import JWTVapor
import Fluent
import Crypto
import Vapor

public protocol BasicJWTAuthenticatable: JWTAuthenticatable where AuthBody == BasicAuthorization, Database: QuerySupporting {
    static var usernameKey: KeyPath<Self, String> { get }
    
    var password: String { get }
}

extension BasicJWTAuthenticatable {
    public static func authBody(from request: Request)throws -> BasicAuthorization? {
        guard let email: String = try request.content.syncGet(at: "email"), let password: String = try request.content.syncGet(at: "passowrd") else {
            return nil
        }
        return AuthBody(username: email, password: password)
    }
    
    public static func authenticate(from payload: Payload, on request: Request)throws -> Future<Self> {
        return try Self.find(payload.id, on: request).unwrap(
            or: Abort(.notFound, reason: "No user found with the ID from the access token")
            ).map(to: Self.self, { (model) in
                try request.authenticate(model)
                try request.set("skelpo-payload", to: payload)
                
                return model
            })
    }
    
    public static func authenticate(from body: AuthBody, on request: Request)throws -> Future<Self> {
        let futureUser = try Self.query(on: request).filter(Self.usernameKey == body.username).first().unwrap(or: Abort(.notFound, reason: "Username or password is incorrect"))
        
        return futureUser.flatMap(to: (Payload, Self).self) { (found) in
            guard try BCrypt.verify(body.password, created: found.password) else {
                throw Abort(.unauthorized, reason: "Username or password is incorrect")
            }
            return try found.accessToken(on: request).map(to: (Payload, Self).self) { ($0, found) }
            }.map(to: Self.self) { (authenticated) in
                try request.set("skelpo-payload", to: authenticated.0)
                try request.authenticate(authenticated.1)
                
                return authenticated.1
        }
    }
}
