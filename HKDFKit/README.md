HKDFKit
=======

Simple HKDF utility with Objective-C interface

## Usage

[RFC5869](http://tools.ietf.org/html/rfc5869)-compliant key derivation function.

```objective-c
NSData *derivedData = [HKDFKit deriveKey:aSeed info:anInfo salt:aSalt outputSize:anOutputSize];
```
---

[TextSecure v2 protocol](https://github.com/WhisperSystems/TextSecure/wiki/ProtocolV2) uses different bounds for the HKDF function.

```objective-c
NSData *derivedData = [TextSecureV2deriveKey:aSeed info:anInfo salt:aSalt outputSize:anOutputSize];
```

## Documentation

API reference is available on [CocoaDocs](http://cocoadocs.org/docsets/HKDFKit).
 
## Installation

Add this line to your `Podfile`

```
pod 'HKDFKit', '~> version number'
```

## License

Licensed under the GPLv3: http://www.gnu.org/licenses/gpl-3.0.html
