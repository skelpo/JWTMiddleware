import JWTAuthenticatable
import Authentication
import JWTVapor
import Fluent
import Vapor

/// Represents a payload for a JWT token that represents
/// a user, holding both its ID and permission status.
public protocol PermissionedUserPayload: IdentifiableJWTPayload {
    
    /// The type used to represent the user's status.
    associatedtype Status: Equatable
    
    /// The user's permission status in
    /// the current service.
    var status: Status { get }
}

/// Verifies incoming request's authentication payload status
/// against pre-defined allowed statuses.
public final class PermissionsMiddleware<Payload>: Middleware where Payload: PermissionedUserPayload {
    
    /// All the restrictions to check against the
    /// incoming request. Only one restriction must
    /// pass for the request to validated.
    public let statuses: [Payload.Status]
    
    /// The status code to throw if no restriction passes.
    public let failureError: HTTPStatus
    
    /// Creates a new `RouteRestrictionMiddleware`.
    ///
    /// - Parameters:
    ///   - statuses: An array of valid permission statuses.
    ///   - failureError: The HTTP status to throw if all restrictions fail. The default
    ///     value is `.notFound` (404). `.unauthorized` (401) would be another common option.
    public init(allowed statuses: [Payload.Status], failureError: HTTPStatus = .notFound) {
        self.statuses = statuses
        self.failureError = failureError
    }
    
    /// Called with each `Request` that passes through this middleware.
    /// - Parameters:
    ///     - request: The incoming `Request`.
    ///     - next: Next `Responder` in the chain, potentially another middleware or the main router.
    /// - Returns: An asynchronous `Response`.
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        do {
            // Fetch the payload from the request `Authorization: Bearer ...` header.
            // We use the payload to get the user's permission level.
            let payload = try request.payload(as: Payload.self)
            
            // Check that the user's permission level exists in the
            // registered statuses.
            guard self.statuses.contains(payload.status) else {
                throw Abort(self.failureError)
            }
        } catch {
            
            // There us no payload, but we expected one.
            // The user is not authenticated, so throw the
            // registered failure error.
            throw Abort(self.failureError)
        }
        
        // Continue the responder chain.
        return try next.respond(to: request)
    }
}
