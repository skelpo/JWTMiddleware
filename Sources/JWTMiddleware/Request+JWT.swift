import VaporRequestStorage
import Vapor

extension Request {
    
    /// Gets the value of the `Authorization: Bearer ...` header.
    ///
    /// - Returns: The `Authorization` header value, removing
    ///   the 'Bearer ' sub-string.
    /// - Throws: 401 (Unauthorized) if no token is found.
    public func accessToken()throws -> String {
        guard let bearer = self.http.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized)
        }
        return bearer
    }
    
    /// Gets the payload of a JWT token the was previously stored in
    /// the request by a middleware.
    ///
    /// - Parameter payloadType: The type that represents the payload. This parameter
    ///   defaults to `Payload.self`, meaning it can be set through type-casting
    ///   and left out of the parameter list.
    ///
    /// - Returns: The stored payload, converted to the `Payload` type.
    /// - Throws: An internal server error if the payload is not found in the
    ///   request storage. This is because this method should _only_ be called
    ///   if a JWT compatible model has been authenticated through a `JWTMiddleware`.
    public func payload<Payload: Decodable>(as payloadType: Payload.Type = Payload.self)throws -> Payload {
        guard let payload = try self.get(.payloadKey, as: Payload .self) else {
            throw Abort(.internalServerError, reason: "No JWTMiddleware has been registered for the current route.")
        }
        return payload
    }
    
    /// Gets the payload of a JWT token stored in the
    /// request and converts it to a different type.
    ///
    /// - Parameters:
    ///   - stored: The type payload is that is stored
    ///     In the request.
    ///   - objectType: The type you want the payload as.
    ///
    /// - Returns: The stored payload, converted to the `Object` type.
    /// - Throws: An internal server error if the payload is not found
    ///   or some other error from encoding and decoding the payload.
    public func payloadData<Payload, Object>(storedAs stored: Payload.Type, convertedTo objectType: Object.Type = Object.self)throws -> Object
        where Payload: Encodable, Object: Decodable {
            guard let payload = try self.get(.payloadKey, as: Payload.self) else {
                throw Abort(.internalServerError, reason: "No JWTMiddleware has been registered for the current route.")
            }
            
            // We convert the payload type from `Payload` to `Object`
            // by encoding it to JSON and back to `Object`.
            // If you have a better idea that works, open an
            // issue or PR on GitHub.
            let data: Data = try JSONEncoder().encode(payload)
            return try JSONDecoder().decode(Object.self, from: data)
    }
}
