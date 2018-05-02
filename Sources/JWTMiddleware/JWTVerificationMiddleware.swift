@_exported import VaporRequestStorage
@_exported import JWTVapor
import Vapor
import JWT

/// Gets a JWT payload from a request, validates it, and stores it for later.
public final class JWTStorageMiddleware<Payload: JWTPayload>: Middleware {
    
    // We create this empty init because the
    // synthesized init is marked `internal`.
    
    /// Creates an instance of the middleware
    public init() {}
    
    /// See Middleware.respond(to:chainingTo:).
    public func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        
        // 1. Get the payload from the request
        // 2. Store the payload in the request
        //    for easier access.
        // 3. Fire the next responder.
        
        let payload: Payload = try request.payload()
        
        try request.set("skelpo-payload", to: payload)
        return try next.respond(to: request)
    }
}


/// Validates a JWT token in a request's `Auithorization` header.
public final class JWTVerificationMiddleware: Middleware {
    
    // We create this empty init because the
    // synthesized init is marked `internal`.
    
    /// Creates an instance of the middleware
    public init() {}
    
    /// See Middleware.respond(to:chainingTo:).
    public func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        
        // Extract the token from the request. It is expected to
        // be in the `Authorization` header as a bearer: `Bearer ...`
        guard let token = request.http.headers.bearerAuthorization?.token else {
            throw Abort(.badRequest, reason: "'Authorization' header with bearer token is missing")
        }
        
        // Get JWT service to verify the token with
        let jwt = try request.make(JWTService.self)
        let data: Data = Data(token.utf8)
        
        // Verify to tokens data.
        if try jwt.verify(data) {
            return try next.respond(to: request)
        } else {
            throw Abort(.forbidden, reason: "JWT verification failed")
        }
    }
}
