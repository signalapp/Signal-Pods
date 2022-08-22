//
//  Copyright (c) 2020-2022 MobileCoin. All rights reserved.
//
//
// swiftlint:disable unavailable_function

class UrlLoadBalancer<MobileCoinUrlType: MobileCoinUrlProtocol> {

    var urlsTyped: [MobileCoinUrlType]

    static func make(
        urls: [MobileCoinUrlType]
    ) -> Result<UrlLoadBalancer<MobileCoinUrlType>, InvalidInputError> {
        guard urls.isNotEmpty else {
            return .failure(InvalidInputError("url list cannot be empty"))
        }
        return .success(Self(urls: urls))
    }

    required internal init(urls: [MobileCoinUrlType]) {
        urlsTyped = urls
    }

    func nextUrl() -> MobileCoinUrlType {
        fatalError("abstract method must be overridden")
    }
}
