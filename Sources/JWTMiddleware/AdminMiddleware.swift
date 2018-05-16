import JWTVapor
import Vapor

/// Protects routes with an access token using with a
/// permission level for request's that have an `admin` level.
public final class AdminMiddleware: Middleware {
    
    /// The name of the key for the value that
    /// is the user's permission status.
    public let permissionKey: String
    
    /// The value that the `permissionKey` should
    /// link to for the middleware to succeed.
    public let adminValue: String
    
    /// Creates a middleware with a payload key and
    /// and the value it should be for the middleware
    /// to pass.
    ///
    /// - Parameters:
    ///   - permissionKey: he key for the value that
    ///     is the user's permission status.
    ///   - adminValue: The value that the `permissionKey` should
    ///     be for the middleware to succeed.
    public init(permissionKey: String, adminValue: String) {
        self.permissionKey = permissionKey
        self.adminValue = adminValue
    }
    
    /// Called with each `Request` that passes through this middleware.
    /// - parameters:
    ///     - request: The incoming `Request`.
    ///     - next: Next `Responder` in the chain, potentially another middleware or the main router.
    /// - returns: An asynchronous `Response`.
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let payload = try request.payload(as: [String: String].self)
        guard payload[self.permissionKey] == self.adminValue else {
            throw Abort(.notFound)
        }
        return try next.respond(to: request)
    }
}

/// Conforms `Dictionary<Codable, Codable>` to `JWTPayload` so we can get
/// a token's payload without a special type.
extension Dictionary: JWTPayload where Key: Codable, Value: Codable {
    
    /// Verifies the claim or payload is correct or throws an error
    public func verify() throws {
        // We use this so we can decode an access token
        // to a dictionary. Verification should be handled
        // with a more specific type.
    }
}
