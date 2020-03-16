import Vapor
import JWT

public final class JWTMiddleware<T: JWTPayload>: Middleware {
    public init() {}

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        
        guard let token = request.headers.bearerAuthorization?.token.utf8 else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Missing authorization bearer header"))
        }

        do {
            request.payload = try request.jwt.verify(Array(token), as: T.self)
        } catch let JWTError.claimVerificationFailure(name: name, reason: reason) {
            request.logger.error("JWT Verification Failure: \(name), \(reason)")
            return request.eventLoop.makeFailedFuture(JWTError.claimVerificationFailure(name: name, reason: reason))
        } catch let error {
            return request.eventLoop.makeFailedFuture(error)
        }

        return next.respond(to: request)
    }

}

extension Request {
    private struct PayloadKey: StorageKey {
        typealias Value = JWTPayload
    }

    var payload: JWTPayload {
        get { self.storage[PayloadKey.self]! }
        set { self.storage[PayloadKey.self] = newValue }
    }
}
