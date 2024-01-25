//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

public class DefaultHttpRequester: NSObject, HttpRequester {
    private var fogTrustRoots: SecSSLCertificates?
    private var consensusTrustRoots: SecSSLCertificates?

    private var pinnedKeys: [SecKey] {
        [fogTrustRoots, consensusTrustRoots]
            .compactMap { $0?.publicKeys }
            .flatMap { $0 }
    }

    static let certPinningEnabled = true

    static let defaultConfiguration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 40
        config.timeoutIntervalForResource = 40
        return config
    }()

    private static let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.underlyingQueue = .global()
        return queue
    }()

    private lazy var session: URLSession = {
       URLSession(
            configuration: DefaultHttpRequester.defaultConfiguration,
            delegate: self,
            delegateQueue: Self.operationQueue)
    }()

    override public init() { }

    public func request(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (Result<HTTPResponse, Error>) -> Void
    ) {
        var request = URLRequest(url: url.absoluteURL)
        request.httpMethod = method.rawValue
        headers?.forEach({ key, value in
            request.setValue(value, forHTTPHeaderField: key)
        })

        request.httpBody = body

        let task = session.dataTask(with: request) {data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(ConnectionError.invalidServerResponse("No Response")))
                return
            }
            let httpResponse = HTTPResponse(httpUrlResponse: response, responseData: data)
            completion(.success(httpResponse))
        }
        task.resume()
    }

    public func setConsensusTrustRoots(_ trustRoots: SecSSLCertificates?) {
        consensusTrustRoots = trustRoots
    }

    public func setFogTrustRoots(_ trustRoots: SecSSLCertificates?) {
        fogTrustRoots = trustRoots
    }
}

extension DefaultHttpRequester {

    public typealias URLAuthenticationChallengeCompletion = (
        URLSession.AuthChallengeDisposition,
        URLCredential?
    ) -> Void

    func urlSession(
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping URLAuthenticationChallengeCompletion
    ) {
        guard
            let trust = challenge.protectionSpace.serverTrust,
            SecTrustGetCertificateCount(trust) > 0
        else {
            // This case will probably get handled by ATS, but still...
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard Self.certPinningEnabled && pinnedKeys.isNotEmpty else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        trust.validateAgainst(pinnedKeys: pinnedKeys) { result in
            switch result {
            case .success(let message):
                logger.debug(message)
                completionHandler(.useCredential, URLCredential(trust: trust))
            case .failure(let error):
                logger.error(error.localizedDescription)
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

}

extension DefaultHttpRequester: URLSessionDelegate {

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping URLAuthenticationChallengeCompletion
    ) {
        urlSession(didReceive: challenge, completionHandler: completionHandler)
    }

}

extension DefaultHttpRequester: URLSessionTaskDelegate {

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping URLAuthenticationChallengeCompletion
    ) {
        urlSession(didReceive: challenge, completionHandler: completionHandler)
    }

}
