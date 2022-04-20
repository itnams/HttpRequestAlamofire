//
//  File.swift
//
//
//  Created by ERM on 20/04/2022.
//

import Alamofire
import Combine
#if !os(macOS)
import UIKit
// MARK: Progress

public typealias RequestProgressHandler = (IRequest, Progress) -> Void

// MARK: IHttpClient

@available(iOS 13.0, *)
public protocol IHttpClient: class {
    /**
     Execute request and return publisher
     - Parameter request: An instance of IRequest
     - Parameter DataResponsePublisher<T>: Publisher will emit output from the request to all subcribers
     */
    
    @available(macOS 10.15, *)
    func execute<T: IResponse>(request: IRequest) -> AnyPublisher<T, Error>
    /**
     cancel request
     */
    func cancel()
}

// MARK: HttpClient

@available(iOS 13.0, *)
open class HttpClient: IHttpClient {
    fileprivate let hostUrl: String
    fileprivate let session: Alamofire.Session
    fileprivate let progressHandler: RequestProgressHandler?
    
    public init(
        hostUrl: String,
        session: Alamofire.Session = .default,
        _ progressHandler: RequestProgressHandler? = nil
    ) {
        self.hostUrl = hostUrl
        self.session = session
        self.progressHandler = progressHandler
    }
    
    /**
     current instance of Alamofire request
     */
    fileprivate var alRequest: Alamofire.DataRequest?
    
    open func execute<T>(
        request: IRequest,
        promise: @escaping (Result<T, Error>) -> Void
    ) where T: IResponse {
        /*
         RequestInterceptor:
         - To inject Authentication Token in one place and reused
         - To do retry times per each API
         **/
        /// create request URL
        let requestURLPath = hostUrl + request.relativeUrl
        guard let requestURL = URL(string: requestURLPath) else {
            fatalError("Failed to create request URL: \(requestURLPath)")
        }
        
        print("\n\n")
        
        /// update session information from request
        let method = request.method.alMethod
        let parameters = request.parameters
        let encoding = request.encoding.alParameterEncoding
        let headers = HTTPHeaders(request.headers)
        let timeout = request.timeout
        
        /// Request here
        alRequest = session.request(
            requestURL,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            requestModifier: { urlRequest in
                urlRequest.timeoutInterval = timeout
            }
        )
        .responseJSON(completionHandler: { response in
            let parserResponse = T(response)
            if parserResponse.success {
                promise(.success(parserResponse))
            } else {
                promise(.failure(parserResponse.error))
            }
        })
    }
    
    /**
     Execute request and return Combine Publisher
     */
    public func execute<T>(request: IRequest) -> AnyPublisher<T, Error> where T: IResponse {
        guard NetworkMonitor.isReachable else {
            let result = T.error(with: .client("No Internet Connection"))
            return Just(result)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        /// create any publisher
        return Future<T, Error> { [weak self] promise in
            guard let `self` = self else { return }
            self.execute(request: request, promise: promise)
        }.eraseToAnyPublisher()
    }
    
    public func cancel() {
        alRequest?.cancel()
    }
}

// MARK: MultipartFormHttpClient

open class MultipartFormHttpClient: HttpClient {
    override open func execute<T>(
        request: IRequest,
        promise: @escaping (Result<T, Error>) -> Void
    ) where T: IResponse {
        guard let request = request as? IMultipartRequest else {
            debugPrint("Passed wrong request type. It must be MultipartRequest ")
            return
        }
        
        let requestURLPath = hostUrl + request.relativeUrl
        alRequest = session.upload(multipartFormData: { multipartFormData in
            for i in 0 ..< request.files.count {
                let file = request.files[i]
                if let url = file.url {
                    multipartFormData.append(url, withName: url.lastPathComponent)
                }
            }
            
            for (key, value) in request.parameters {
                if let data = (value as AnyObject).data(using: String.Encoding.utf8.rawValue) {
                    multipartFormData.append(data, withName: key)
                }
            }
        }, to: requestURLPath)
        .uploadProgress(closure: { [weak self] progress in
            debugPrint("Progress: \(progress.fractionCompleted)")
            self?.progressHandler?(request, progress)
        })
        .responseJSON(completionHandler: { response in
            switch response.result {
            case .success:
                let parserResponse = T(response)
                if parserResponse.success {
                    promise(.success(parserResponse))
                } else {
                    promise(.failure(parserResponse.error))
                }
                
            case .failure: break
            }
        })
    }
}

// MARK: Convert HttpRequestMethod to Alamofire.HTTPMethod

extension HttpRequestMethod {
    var alMethod: Alamofire.HTTPMethod {
        let result: Alamofire.HTTPMethod
        switch self {
        case .get: result = .get
        case .post: result = .post
        case .put: result = .put
        case .delete: result = .delete
        }
        return result
    }
}

// MARK: Convert ParameterEncoding to Alamofire.ParameterEncoding

extension HttpParameterEncoding {
    var alParameterEncoding: Alamofire.ParameterEncoding {
        switch self {
        case .json: return JSONEncoding.default
        case .url: return URLEncoding.default
        }
    }
}
#endif
