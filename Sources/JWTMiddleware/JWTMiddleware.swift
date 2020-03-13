import Vapor
import JWT

final class JWTMiddleware<T: JWTPayload>: Middleware {
    init() { }

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        
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

extension AnyHashable {
    static let payload: String = "jwt_payload"
}

extension Request {
    var loggedIn: Bool {
        return (self.userInfo[.payload] as? JWTPayload) != nil
    }
    
    var payload: JWTPayload {
        get { self.userInfo[.payload] as! JWTPayload }
        set { self.userInfo[.payload] = newValue }
    }
}
