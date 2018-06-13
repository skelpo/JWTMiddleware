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

/// A data structure that a request must match for
/// the request to pass through `RouteRestrictionMiddleware`.
public struct RouteRestriction<Status> where Status: Equatable {
    
    /// The components of a path that the
    /// request's URI must match.
    public let path: [PathComponent]
    
    /// The HTTP method that request's method
    /// must match. Any method is valid if this
    /// property is `nil`.
    public let method: HTTPMethod?
    
    /// The permission levels that are allowed to
    /// access routes with the given path
    /// and method.
    public let allowed: [Status]
    
    /// Creats a new restriction for incoming requests.
    ///
    /// - Parameters:
    ///   - method: The method that the request must match.
    ///   - path: The path components that the request's
    ///     path elements must match.
    ///   - allowed: An array of permission levels that
    ///     are allowed to access the matching route.
    public init(_ method: HTTPMethod? = nil, at path: PathComponentsRepresentable..., allowed: [Status]) {
        self.method = method
        self.path = path.convertToPathComponents()
        self.allowed = allowed
    }
}

/// Verifies incoming request's againts `RouteRestriction` constraints.
public final class RouteRestrictionMiddleware<Status, Payload, Authed>: Middleware
    where Authed: Authenticatable & Model & Parameter, Payload: PermissionedUserPayload, Status == Payload.Status, Authed.ID: LosslessStringConvertible, Authed.ID == Payload.ID
{
    
    /// All the restrictions to check against the
    /// incoming request. Only one restriction must
    /// pass for the request to validated.
    public let restrictions: [RouteRestriction<Status>]
    
    /// The status code to throw if no restriction passes.
    public let failureError: HTTPStatus
    
    /// Parameters types that can be used in a route path.
    public let parameters: [String: (String, Container)throws -> Any]
    
    /// Creates a new `RouteRestrictionMiddleware`.
    ///
    /// - Parameters:
    ///   - restrictions: An array the `RouteRestrictions` to verify each incoming
    ///     request against.
    ///   - failureError: The HTTP status to throw if all restrictions fail. The default
    ///     value is `.notFound` (404). `.unauthorized` (401) would be another common option.
    ///   - parameters: Paramater types that can be used in a route path. Basic types are
    ///     added by default, so only add custom types.
    public init(restrictions: [RouteRestriction<Status>], failureError: HTTPStatus = .notFound, parameters: [String: (String, Container)throws -> Any] = [:]) {
        self.restrictions = restrictions
        self.failureError = failureError
        
        let defaultParameters: [String: (String, Container)throws -> Any] = [
            String.routingSlug: String.resolveParameter,
            Int.routingSlug: Int.resolveParameter,
            Int8.routingSlug: Int8.resolveParameter,
            Int16.routingSlug: Int16.resolveParameter,
            Int32.routingSlug: Int32.resolveParameter,
            Int64.routingSlug: Int64.resolveParameter,
            UInt.routingSlug: UInt.resolveParameter,
            UInt8.routingSlug: UInt8.resolveParameter,
            UInt16.routingSlug: UInt16.resolveParameter,
            UInt32.routingSlug: UInt32.resolveParameter,
            UInt64.routingSlug: UInt64.resolveParameter,
            Float.routingSlug: Float.resolveParameter,
            Double.routingSlug: Double.resolveParameter,
            UUID.routingSlug: UUID.resolveParameter
        ]
        self.parameters = parameters.merging(defaultParameters) { first, _ in first }
    }
    
    /// Called with each `Request` that passes through this middleware.
    /// - Parameters:
    ///     - request: The incoming `Request`.
    ///     - next: Next `Responder` in the chain, potentially another middleware or the main router.
    /// - Returns: An asynchronous `Response`.
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let cleanPath = Array(request.http.url.pathComponents.dropFirst())
        
        // Iterate over each restrction, seeing if it matches the request.
        let passes = try restrictions.filter { restriction in
            
            // Verify restriction path components and request URI equality.
            // We drop the first element of the request's patch components because
            // that values is always `/`, which we don't need to match against.
            try self.compare(components: restriction.path, to: cleanPath, parameters: self.parameters, on: request) &&
                
                // Verfiy resriction and request method equality.
                (restriction.method == nil || restriction.method == request.http.method)
        }
        
        if passes.count <= 0 {
            
            // There are no matching restrictions for the request. Continue the responder chain.
            return try next.respond(to: request)
        }
        
        do {
            // Fetch the payload from the request `Authorization: Bearer ...` header.
            // We use the payload to get the user's permission level.
            let payload = try request.payload(as: Payload.self)
            
            // Check that the user's permission level exists in the ones
            // contained in the restrictions thatr match the request.
            guard
                try passes.map({ $0.allowed }).joined().contains(payload.status) ||
                self.authedIDs(from: request, matching: cleanPath, and: passes[0].path, for: Authed.self).contains(payload.id)
            else {
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
    
    /// Compares an array of path component cases to a URI's path components,
    /// resolving whether the URI would be valid for a route with the given components.
    ///
    /// - Parameters:
    ///   - components: The `PathComponent` cases to check against
    ///     the URI path components.
    ///   - path: The URI path components. If the `URL.pathComponents` property
    ///     is used for this value, drop the leading forward slash before passing it in.
    ///   - The parameter types that appear in `components` array. If there are none, an
    ///     empty dictionary can be passed in. A single entry is `<TYPE>.routingSlug: <TYPE>.resolveParameter`.
    ///   - container: The container used to run the paramter resolving functions. This will probably be a request.
    ///
    /// - Returns: `true` if the components and path are equivalent. `false` if they are not.
    public func compare(components: [PathComponent], to path: [String], parameters: [String: (String, Container)throws -> Any], on container: Container)throws -> Bool {
        
        // Zip the arrays togeather so we can check each
        // element in the same position.
        for (component, element) in zip(components, path) {
            switch component {
                
                // Always matches the rest of the components.
            // We haven't returned false yet, so return true.
            case .catchall: return true
                
                // Always matches the current case.
            // Continue to the next loop iteraton.
            case .anything: continue
                
                // Check that the current path element and component match.
            // If they do, continue to the next iteration, otherwise return `false`.
            case let .constant(constant): guard constant == element else { return false }
                
                // Get the parameter type for the given placeholder slug.
                // Run the `.resolveParameter` method on it. If it doesn't
            // throw, we assume a match and continue the loop.
            case let .parameter(value):
                guard let resolver = parameters[value] else {
                    throw Abort(.internalServerError, reason: "No registed parameter type found for slug '\(value)'")
                }
                _ = try resolver(element, container)
            }
        }
        return true
    }
    
    /// Gets the IDs of a model type from a URI's path components
    /// by comparing them to an array of `PathComponent` cases, along
    /// with the uthenticated model's ID.
    ///
    /// - Parameters:
    ///   - path: The path components to extract the IDs from.
    ///   - matching: The `PathComponent` cases that represent
    ///     the `path` parameter passed in.
    ///   - The parent model type for the IDs that are being extracted.
    ///
    /// - Returns: All the `Parent.ID` instances that appear in the path passed in.
    public func authedIDs<Parent>(from request: Request, matching path: [String], and components: [PathComponent], for userType: Parent.Type = Parent.self)throws -> [Parent.ID]
        where Parent: Model & Parameter & Authenticatable, Parent.ID: LosslessStringConvertible
    {
        
        // The all the parameter IDs, plus the ID of
        // the authenticated user if there is one.
        let ids = try self.ids(from: path, matching: components, for: Parent.self)
        if let parent = try request.authenticated(Parent.self) {
            return try ids + [parent.requireID()]
        }
        return ids
    }
    
    /// Gets the IDs of a model type from a URI's path components
    /// by comparing them to an array of `PathComponent` cases.
    ///
    /// - Parameters:
    ///   - path: The path components to extract the IDs from.
    ///   - matching: The `PathComponent` cases that represent
    ///     the `path` parameter passed in.
    ///   - The parent model type for the IDs that are being extracted.
    ///
    /// - Returns: All the `Parent.ID` instances that appear in the path passed in.
    public func ids<Parent>(from path: [String], matching: [PathComponent], for userType: Parent.Type = Parent.self)throws -> [Parent.ID]
        where Parent: Model & Parameter, Parent.ID: LosslessStringConvertible
    {
        
        // Get path componentns that are used as parameters.
        return try zip(path, matching).compactMap { components -> (slug: String, element: String)? in
            guard case let PathComponent.parameter(slug) = components.1 else { return nil }
            return (slug, components.0)
            }
            
            // Filter out parameters for the `Parent` model.
            .filter { $0.slug == Parent.routingSlug }
            
            // Get the `Parent` IDs from the paramneter value
            // passed in through the URL.
            .map { parameter in
                guard let id = Parent.ID.init(parameter.element) else {
                    throw Abort(.badRequest, reason: "Unable to create \(String(describing: Parent.self)) ID from parameter '\(parameter.element)'")
                }
                return id
        }
    }
}
