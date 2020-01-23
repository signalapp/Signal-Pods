Argon2 Library
==

Wrapper around the [reference C implementation of Argon2](https://github.com/P-H-C/phc-winner-argon2).

Android Usage
--

```gradle
implementation 'org.signal:argon2:13.0@aar'
```

```java
Argon2 argon2 = new Argon2.Builder(Version.V13)
                          .type(Type.Argon2id)
                          .memoryCost(MemoryCost.MiB(32))
                          .parallelism(1)
                          .iterations(3)
                          .build();
                          
                          
Argon2.Result result = argon2.hash(password, salt);

byte[] hash    = result.getHash();
String hashHex = result.getHashHex();
String encoded = result.getEncoded();
```

iOS Usage
--

Add the following line to your Podfile:

```ruby
pod 'Argon2', git: 'https://github.com/signalapp/Argon2.git', submodules: true
```

```swift
let (rawHash, encodedHash) = Argon2.hash(
    iterations: 1,
    memoryInKiB: 32 * 1024,
    threads: 1,
    password: password,
    salt: salt,
    desiredLength: 32,
    variant: .id,
    version: .v13
)
```
