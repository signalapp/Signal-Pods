//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

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
    private typealias ChainOfTrustKeyMatch = (match: Bool, index: Int, key: SecKey)
    private typealias ChainOfTrustKey = (index: Int, key: SecKey)

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

        /// Compare pinned & server public keys
        let matches: [ChainOfTrustKey]
        let trustChainEnumerated = trust.publicKeyTrustChain.enumerated()
        matches = trustChainEnumerated
            .map { chain -> ChainOfTrustKeyMatch in
                let serverCertificateKey = chain.element
                let match = pinnedKeys.contains(serverCertificateKey)
                return (match: match, index: chain.offset, key: serverCertificateKey)
            }
            .filter { $0.match }
            .map { (index: $0.index, key: $0.key) }

        switch matches.isNotEmpty {
        case true:
            let indexes = matches.map { "\($0.index)" }
            let keys = matches.compactMap { $0.key.data }.map { "\($0.base64EncodedString() )" }
            let message = """
                    Success: pinned certificates matched with server's chain of trust
                    at index(es): [\(indexes.joined(separator: ", "))] \
                    with key(s): \(keys.joined(separator: ", \n"))
                    """
            logger.debug(message)
            completionHandler(.useCredential, URLCredential(trust: trust))
        case false:
            /// Failing here means that the public key of the server does not match the stored one.
            /// This can either indicate a MITM attack, or that the backend certificate and the 
            /// private key changed, most likely due to expiration.
            logger.error("Failure: no pinned certificate matched in the server's chain of trust")
            completionHandler(.cancelAuthenticationChallenge, nil)
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
