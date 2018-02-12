25519 [![Build Status](https://travis-ci.org/FredericJacobs/25519.svg?branch=master)](https://travis-ci.org/FredericJacobs/25519)
=====

Curve25519 is a fast and secure curve used for key agreement. Unfortunately, it does not support signing out of the box. This pod translates the point curves to do ed25519 signing with curve25519 keys.

## Usage

Generating a curve25519 key:

```objective-c
ECKeyPair *curve25519Key = [Curve25519 generateKeyPair];
```

`ECKeyPair` conforms to `NSCoding` to make storage of it more convenient. 

- - -

Generating a curve25519 shared secret:

```objective-c
NSData *sharedSecret = [Curve25519 generateSharedSecretFromPublicKey:aPublicKey andKeyPair:anECKeyPair];
```

- - -

ed25519-sign message with curve25519 key pair:

```objective-c
NSData *signature = [Ed25519 sign:message withKeyPair:ecKeyPair]
```

- - -

ed25519-verify message with curve25519 key pair:

```objective-c
BOOL validSignature = [Ed25519 verifySignature:signature publicKey:ecPublicKey msg:message;
```

## Documentation

API reference is available on [CocoaDocs](http://cocoadocs.org/docsets/25519).
 
## Installation

Add this line to your `Podfile`

```
pod '25519', '~> version number'
```
## Cryptographic Implementations

The Curve25519 key pair and ECDH is done with [Adam Langley](https://www.imperialviolet.org/)’s [curve25519-donna](https://github.com/agl/curve25519-donna). [The point conversion algorithm](https://www.github.com/trevp/ref10_extract) was written by the inimitable [Trevor Perrin](http://trevp.net/).

## License

Licensed under the GPLv3: http://www.gnu.org/licenses/gpl-3.0.html

