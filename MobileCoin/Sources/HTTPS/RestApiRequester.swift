//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

public class RestApiRequester {
    let requester: HttpRequester
    let baseUrl: MobileCoinUrlProtocol
    let prefix: String = "gw"

    init(requester: HttpRequester, baseUrl: MobileCoinUrlProtocol) {
        self.requester = requester
        self.baseUrl = baseUrl
    }
}

protocol Requester {
    func makeRequest<T: HTTPClientCall>(
            call: T,
            completion: @escaping (HttpCallResult<T.ResponsePayload>) -> Void
        )
}

extension RestApiRequester: Requester {
    private func completeURL(path: String) -> URL? {
        .prefix(baseUrl.httpBasedUrl, pathComponents: [prefix, path])
    }

    public func makeRequest<T: HTTPClientCall>(
        call: T,
        completion: @escaping (HttpCallResult<T.ResponsePayload>) -> Void
    ) {
        guard let url = completeURL(path: call.path) else {
            let message = "Could not construct URL"
            logger.assertionFailure(message)
            completion(HttpCallResult(error: InvalidInputError(message)))
            return
        }

        var request = URLRequest(url: url.absoluteURL)
        request.addProtoHeaders()
        request.addHeaders(call.options?.headers ?? [:])

        do {
            request.httpBody = try call.requestPayload?.serializedData()
        } catch {
            logger.assertionFailure(error.localizedDescription)
            completion(HttpCallResult(error: error))
            return
        }

        requester.request(
                url: url,
                method: call.method,
                headers: request.allHTTPHeaderFields,
                body: request.httpBody) { result in

            switch result {
            case .failure(let error):
                logger.error(error.localizedDescription)
                completion(HttpCallResult(error: error))
            case .success(let httpResponse):
                let statusCode = httpResponse.statusCode
                logger.info("Http Request url: \(url)")
                logger.info("Status code: \(statusCode)")

                let responsePayload: T.ResponsePayload? = {
                    guard let data = httpResponse.responseData,
                          let responsePayload = try? T.ResponsePayload(serializedData: data)
                    else {
                        return nil
                    }
                    return responsePayload
                }()

                let result = HttpCallResult(
                        status: HTTPStatus(code: statusCode, message: ""),
                        allHeaderFields: httpResponse.allHeaderFields,
                        response: responsePayload)
                completion(result)
            }
        }
    }

}
