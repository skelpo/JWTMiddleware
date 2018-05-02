@_exported import JWTAuthenticatable
import JWTVapor
import Fluent
import Crypto
import Vapor
import JWT

/// Handles authenticating/authorizing a model conforming to `JWTAuthenticatable`
/// using data pulled from a request.
public final class JWTAuthenticatableMiddleware<A: JWTAuthenticatable>: Middleware {
    
    // We create this empty init because the
    // synthesized init is marked `internal`.
    
    /// Creates an instance of the middleware
    public init() {}
    
    /// See Middleware.respond(to:chainingTo:).
    public func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        
        // If the model is already quthenticated,
        // no more work for us! Fire the next responder.
        if try request.isAuthenticated(A.self) {
            return try next.respond(to: request)
            
        } else {
            return try A.authBody(from: request).flatMap(to: Response.self, { body in
                
                // Check to see if an `AuthBody` instance can be created.
                if let payload = body {
                    
                    // We got an `AuthBody` instance. Authenticate the model, then fire the next responder.
                    return try A.authenticate(from: payload, on: request).flatMap(to: Response.self) { authenticated in
                        return try next.respond(to: request)
                    }
                    
                    // Check to see if a `Authorization: Bearer ...` header exists.
                } else if request.http.headers.bearerAuthorization != nil {
                    
                    // Header found. Get the payload from the request.
                    let payload: A.Payload = try request.payload()
                    
                    // Authenticate the model, then fire the next responder.
                    return try A.authenticate(from: payload, on: request).flatMap(to: Response.self) { model in
                        return try next.respond(to: request)
                    }
                    
                } else {
                    
                    // No Authorized model or data to auth found. Throw a 401 (Unauthorized) error.
                    throw Abort(.unauthorized, reason: "No authorized user or data to authorize a user was found")
                }
            })
        }
    }
}



