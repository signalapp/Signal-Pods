//
//  Copyright (c) 2020-2022 MobileCoin. All rights reserved.
//

class RandomUrlLoadBalancer<ServiceUrl: MobileCoinUrlProtocol>: UrlLoadBalancer<ServiceUrl> {
    private var rng = SystemRandomNumberGenerator()
    private(set) var currentUrl: ServiceUrl

    override func nextUrl() -> ServiceUrl {
        guard urlsTyped.count > 1 else {
            return currentUrl
        }

        var nextUrl: ServiceUrl
        repeat {
            guard let url = urlsTyped.randomElement(using: &rng) else {
                // This condition should never happen
                logger.fatalError(
                    "unable to get nextUrl() from RandomUrlLoadBalancer")
            }
            nextUrl = url
        }
        while currentUrl.url == nextUrl.url

        currentUrl = nextUrl
        return currentUrl
    }

    required init(urls: [ServiceUrl]) {
        // this is to work around the 'Property not initialized at super.init call' compiler error
        currentUrl = urls[0]

        super.init(urls: urls)

        guard let nextUrl = urlsTyped.randomElement(using: &rng) else {
            // This condition should never happen
            logger.fatalError(
                "unable to get nextUrl() from RandomUrlLoadBalancer")
        }
        currentUrl = nextUrl
    }

}
