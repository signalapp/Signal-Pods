//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

class NonRotatingUrlLoadBalancer<ServiceUrl: MobileCoinUrlProtocol>: UrlLoadBalancer<ServiceUrl> {
    private(set) var currentUrl: ServiceUrl

    override func nextUrl() -> ServiceUrl {
        guard urlsTyped.count > 1 else {
            return currentUrl
        }
        logger.warning(
            "This service does not support URL rotation. The url at index == 0 is always returned")
        return currentUrl
    }

    required init(urls: [ServiceUrl]) {
        // this is to work around the 'Property not initialized at super.init call' compiler error
        currentUrl = urls[0]
        super.init(urls: urls)
    }

}
