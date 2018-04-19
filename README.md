# JWTMiddleware

Handles authentication and authorization of models through JWT tokens by themselves or mixed with other authentication methods.

## Install

Add this line to your manifest's `dependencies` array:

```swift
.package(url: "https://github.com/skelpo/JWTMiddleware.git", from: "0.2.0")
```

And add `JWTMiddleware` to all the target dependency arrays you want to access the package in.

Complete the installation by running `vapor update` or `swift package update`.

## Middleware

**`JWTAuthenticatableMiddlware`**

Handles authenticating/authorizing a model conforming to `JWTAuthenticatable` using data pulled from a request.

```swift
route.group(JWTAuthenticatableMiddlware<User>())
```

---

**`JWTVerificationMiddleware`**

Gets a JWT payload from a request, validates it, and stores it for later.

```swift
route.group(JWTVerificationMiddleware<UserPayload>())
```

## Protocols

See source doc comments for details.

- `IdentifiableJWTPayload`
- `JWTAuthenticatable`
- `BasicJWTAuthenticatable`