import VaporRequestStorage
import Authentication
import JWTVapor
import Fluent
import Crypto
import Vapor

/// Used to decode a request body in
/// `BasicJWTAuthenticatable.authBody(from:)`.
///
/// This type is generic so we can access the property
/// name of the `usernameKey` as the `username` deocding string value.
struct UsernamePassword<Model: BasicJWTAuthenticatable>: Codable {
    
    /// The `username` value for creating
    /// a `BasicAuthorization` instance.
    let username: String?
    
    /// The `password` value for creating
    /// a `BasicAuthorization` instance.
    let password: String?
    
    /// The keys used to decode a request
    /// body to this struct type.
    enum CodingKeys: CodingKey {
        
        /// The decoding key for the `password` property.
        case password
        
        /// The decoding key for the `username` property.
        case username
        
        /// See `CodingKey.stringValue`.
        var stringValue: String {
            switch self {
            case .password: return "password"
            case .username: return (try? Model.reflectProperty(forKey: Model.usernameKey)?.path[0] ?? "email") ?? "email"
            }
        }
    }
}

/// Represents a type that can be authenticated with a basic
/// username/email and password and be authorized with
/// a JWT payload.
///
/// The `AuthBody` type is constrained to `BasicAuthorization` and the `Database` type
/// must conform to the `QuerySupporting` protocol.
public protocol BasicJWTAuthenticatable: JWTAuthenticatable where AuthBody == BasicAuthorization, Database: QuerySupporting {
    
    /// The keypath for the property
    /// that is used to authenticate the
    /// model. This is probably `username`
    /// or `email`.
    static var usernameKey: KeyPath<Self, String> { get }
    
    /// A string that is used with the
    /// property of the `usernameKey`
    /// to authenticate the model.
    /// This model is expected to be
    /// a hash created with BCrypt.
    var password: String { get }
}

/// Default implementations of some methods
/// required by the `JWTAuthenticatable` protocol.
extension BasicJWTAuthenticatable {
    
    public static func authBody(from request: Request)throws -> Future<BasicAuthorization?> {
        
        // Get the request body as a `UsernamePassword` instance and convert it to a `BasicAuthorization` instance.
        return try request.content.decode(UsernamePassword<Self>.self).map(to: AuthBody?.self) { authData in
            guard let password = authData.password, let username = authData.username else {
                return nil
            }
            return AuthBody(username: username, password: password)
        }
    }
    
    public static func authenticate(from payload: Payload, on request: Request)throws -> Future<Self> {
        
        // Fetch the model from the database that has an ID
        // matching the one in the JWT payload.
        return try Self.find(payload.id, on: request)
            
        // No user was found. Throw a 404 (Not Found) error
        .unwrap(or: Abort(.notFound, reason: "No user found with the ID from the access token"))
        .map(to: Self.self, { (model) in
            
            // Store the model and payload in the request
            // using the request's `privateContainer`.
            try request.authenticate(model)
            try request.set("skelpo-payload", to: payload)
            
            return model
        })
    }
    
    public static func authenticate(from body: AuthBody, on request: Request)throws -> Future<Self> {
        // We use the same error when the user is not found and the password doesn't match
        // as an anti-attack technique. We don't want someone to knwo they guessed a valid
        // username.
        
        // Get the user where the property referanced by `usernameKey` matches the `body.username` value.
        // If no model is found, throw a 401 (Unauothorized) error.
        let futureUser = try Self.query(on: request).filter(Self.usernameKey == body.username).first().unwrap(or: Abort(.unauthorized, reason: "Username or password is incorrect"))
        
        return futureUser.flatMap(to: (Payload, Self).self) { (found) in
            
            // Verify the stored password hash against the password in the `body` object.
            guard try BCrypt.verify(body.password, created: found.password) else {
                throw Abort(.unauthorized, reason: "Username or password is incorrect")
            }
            
            // Get the access token from the model that was found.
            return try found.accessToken(on: request).map(to: (Payload, Self).self) { ($0, found) }
            }.map(to: Self.self) { (authenticated) in
                
                // Store the payload and the model in the request
                // for later access.
                try request.set("skelpo-payload", to: authenticated.0)
                try request.authenticate(authenticated.1)
                
                return authenticated.1
        }
    }
}
