# JWTMiddleware

Handles authentication and authorization of models through JWT tokens by themselves or mixed with other authentication methods.

## Install

Add this line to your manifest's `dependencies` array:

```swift
.package(url: "https://github.com/skelpo/JWTMiddleware.git", from: "0.6.1")
```

And add `JWTMiddleware` to all the target dependency arrays you want to access the package in.

Complete the installation by running `vapor update` or `swift package update`.

## Modules

There are currently 2 modules in the JWTMiddleware package; `JWTMiddleware` and `JWTAuthenticatable`.

The `JWTMiddleware` module contains middleware for request authentication/authorization and helpers for getting data stored in the request by the middleware.

The `JWTAuthenticatable` module holds protocols that allow a type to be authenticated/authorized in the middleware declared in the `JWTMiddleware` module.

## JWTMiddleware

The JWTMiddleware module exports the following types:

- `JWTAuthenticatableMiddlware`:

	Handles authenticating/authorizing a model conforming to `JWTAuthenticatable` using data pulled from a request. 
	
	When a request is passed though the middleware, it will first check to see if the specified model is already authenticated. If it is not, it will try to get data to authenticate the model by calling the static `authBody(from:)` method. If it successfully authenticates, it will get the model's access token by calling `accessToken(on:)`, then store both the token and the authenticated model in the request for accessing later. If `nil` is return from `authBody(from:)`, then we try to authenticate using data from the `Authorization: Bearer ...` header. If authentication succeeds, we will store both the token fetched from the header and the authenticated model in the request.
	
	You can register the middleware to a route group as shown below.
	
	```swift
	let auth = route.group(JWTAuthenticatableMiddlware<User>())
	```

- `JWTVerificationMiddleware`:

	 Gets the value from the `Authorization: Bearer ...` header, verifies it with the specified payload type, and stores it in the request for later.
	
	```swift
	route.group(JWTVerificationMiddleware<UserPayload>())
	```
- `RouteRestrictionMiddleware`:

   Restricts access to routes based on a user's permission level (i.e. Admin, Moderator, Standard, etc.)
   
   ```swift
   route.group(RouteRestrictionMiddleware(
   		restrictions: [
   			RouteRestriction(.DELETE, at: "users", User.parameter, allowed: [.admin, .moderator]),
   			...
   		],
   		parameters: [User.routingSlug: User.resolveParameter]
   ))
   ```
  
   You must add custom parameter types used due to the way the request's URI and the restrictions path components are checked. Default parameter types are added by default.
   
   If a user is authenticated via middleware before `RouteRestrictionMiddleware`, the middleware will use that user's ID to check against the ID in the JWT payload we checking a request.
   
- `RouteRestriction`:

   A restriction constraint for a `RouteRestrictionMiddleware` instance. The initializer takes in an optional method, a path, and valid permission levels for that path. If the method is `nil`, any method for the given path will be restricted.
   
   ```swift
   RouteRestriction(.GET, at: "dashboard", "user", User.parameter, "tickets", allowed: [.admin])
   ```

- `PermissionedUserPayload`: 

   Extends `IdentifiableJWTPayload` adding a 

## JWTAuthenticatable

The JWTAuthenticatable module exports the following types:

- `IdentifiableJWTPayload`:
	
	Represents a JWT payload with an `id` value. This is used by the `BasicJWTAuthenticatable` to access a model from the database based on its `id` property.
	
- `JWTAuthenticatable`:
	
	A model that can be authorized with a JWT payload and authenticated with an unspecified type that is defined by the implementing type.
	
	This protocol requires the following types/properties/methods:
	
	- `associatedtype AuthBody`: Used for authentication of the model.
	- `associatedtype Payload: IdentifiableJWTPayload`: A type that the payload of a JWT token can be converted to. This type is used to authorize requests.
	
	- `accessToken(on request: Request) throws -> Future<Payload>`: This method should create a payload for a JWT token that will later be used to authorize the model.
	- `static authBody(from request: Request)throws -> AuthBody?`: Gets data from a request that can be used to authenticate a model
	- `static authenticate(from payload: Payload, on request: Request)throws -> Future<Self>`: Verifies the payload passed in and gets an instance of the model based on the payload's contents.
	- `static authenticate(from body: AuthBody, on request: Request)throws -> Future<Self>`: Gets a model and checks it against the contents of the `body` parameter passed in.

- `BasicJWTAuthenticatable`:

	Implements `JWTAuthenticatable` methods for authenticating with an id/password combination. The ID should either be a username or email.
	
	The `authBody` method implementation gets the name of the property referenced by the `usernameKey` key-path. It will then extract the values from the request body with the key from `usernameKey` and `"password"`.
	
	The payload authorization method simply finds the instance of the model stored in the database with an ID equal to the `id` property in the payload.
	
	The `AuthBody` authentication method fetches the first user from the database with a `usernameKey` property equal to the `body.username` value. It then checks to see if the model's password hash is equal to the `body.password` value, using BCrypt verification.
	
	This protocols requires the following type/properties:
	
	- `associatedtype Payload: IdentifiableJWTPayload`: A type that the payload of a JWT token can be converted to. This type is used to authorize requests.
	- `usernameKey: KeyPath<Self, String>`: The key-path for the property that will be checked against the `body.username` value during authentication. This will usually be either an email or username. This property can be either a variable or constant.
	- `var password: String` The hashed password of the model, used to verify the request'c credibility. This properties value _must_ be hash using BCrypt.

This module also adds some helper methods to the `Request` type:

- `accessToken()throws -> String`: Gets the value of the `Authorization: Bearer ...` header.
- `payload<Payload: Decodable>(as payloadType: Payload.Type = Payload.self)throws -> Payload`: Gets the payload of a JWT token the was previously stored in the request by a middleware.
- `payloadData<Payload, Object>(storedAs stored: Payload.Type, convertedTo objectType: Object.Type = Object.self)throws -> Object`: Gets the payload of a JWT token stored in the request and converts it to a different type.
