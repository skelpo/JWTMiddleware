import JWTAuthenticatable
import JWTVapor
import Fluent
import Crypto
import Vapor
import JWT

public final class JWTAuthenticatableMiddlware<A: JWTAuthenticatable>: Middleware where A.Database: QuerySupporting {
    public init() {}
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        if try request.isAuthenticated(A.self) {
            return try next.respond(to: request)
            
        } else if let payload = try A.authBody(from: request) {
            return try A.authenticate(from: payload, on: request).flatMap(to: Response.self) { authenticated in
                return try next.respond(to: request)
            }
            
        } else if request.http.headers.bearerAuthorization != nil {
            let payload: A.Payload = try request.payload()
            
            return try A.authenticate(from: payload, on: request).flatMap(to: Response.self) { model in
                return try next.respond(to: request)
            }
            
        } else {
            throw Abort(.unauthorized, reason: "No authorized user to data to authorize a user was found")
        }
    }
}


