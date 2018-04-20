import Authentication
import Vapor
import JWT

/// A JWT paload represntation that has an ID property.
/// Designed to fetch a model (user) from a database.
public protocol IdentifiableJWTPayload: JWTPayload {
    
    /// The ID type used for the model
    /// that the ID connects to.
    associatedtype ID
    
    /// The ID of the model that
    /// will be fetched from the database.
    var id: ID { get }
}

/// A type that can be authenticated with some type and authorized with a JWT payload.
/// The `Payload.ID` type must be equal to the model's `ID` type.
public protocol JWTAuthenticatable: Authenticatable, Content where Payload.ID == Self.ID {
    
    /// The type that the model can
    /// be authenticated with.
    associatedtype AuthBody
    
    /// A JWT payload that the model can
    /// be authorized with.
    associatedtype Payload: IdentifiableJWTPayload
    
    
    /// Creates a JWT payload for the model using it's own data and
    /// that from the request passed in, that the model can later
    /// be authorized with.
    ///
    /// - Parameter request: The request for the route that the
    ///   payload will be created in.
    ///
    /// - Returns: The future value of the payload when it is successfully created.
    /// - Throws: Whatever throws in the implementation.
    func accessToken(on request: Request) throws -> EventLoopFuture<Payload>
    
    
    /// Gets an instance of the `AuthBody` type from a request to
    /// authenticate the user with.
    ///
    /// - Parameter request: The request for the route where the body
    ///   will be fetched to use in.
    ///
    /// - Returns: The authentication data. `nil` if the data does not
    ///  exist in the request.
    /// - Throws: Whatever throws in the implementation.
    static func authBody(from request: Request)throws -> AuthBody?
    
    /// Verifies the payload passed in, then fetches the
    /// correct user bassed on the payloads information.
    /// This method should throw if the authentication fails.
    ///
    /// - Parameters:
    ///   - payload: The JWT payload to authorize the request with.
    ///     The payload is fetched from the `Authorization: Bearer ...` header
    ///   - request: The request the authorization is occuring on.
    ///
    /// - Returns: A future value of the authorized model.
    /// - Throws: Whatever is thrown from the implementation.
    static func authenticate(from payload: Payload, on request: Request)throws -> Future<Self>
    
    /// Verifies the data in the body, then fetches the
    /// instance of the model that matches the data.
    /// This method should throw if the authentication fails.
    ///
    /// - Parameters:
    ///   - body: Data from the request that can be
    ///     used to get a model from the database
    ///   - request: The request the authorization is occuring on.
    ///
    /// - Returns: A future value of the model that was fetched.
    /// - Throws: Whatever the implementation throws.
    static func authenticate(from body: AuthBody, on request: Request)throws -> Future<Self>
}


