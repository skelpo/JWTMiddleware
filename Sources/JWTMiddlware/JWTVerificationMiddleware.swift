@_exported import VaporRequestStorage
@_exported import JWTVapor
import Vapor
import JWT

/// Gets a JWT payload from a request and stores it for later.
public final class JWTVerificationMiddleware<Payload: JWTPayload>: Middleware {
    
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
