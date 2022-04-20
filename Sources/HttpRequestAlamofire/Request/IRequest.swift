//
//  SwiftUIView.swift
//  
//
//  Created by ERM on 20/04/2022.
//

import SwiftUI

public enum HttpRequestMethod: CustomStringConvertible {
    case get
    case post
    case put
    case delete
    
    public var description: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .delete: return "DELETE"
        }
    }
}

public enum HttpParameterEncoding {
    case json
    case url
}

/**
 Object to collect request information & generate to JSON
 which one will be input for IHttpClient
 */
public protocol IRequest {
    var relativeUrl: String { get }
    var method: HttpRequestMethod { get }
    var headers: [String: String] { get }
    var parameters: [String: Any] { get }
    var encoding: HttpParameterEncoding { get }
    var timeout: TimeInterval { get }
}

/**
 Base struct of IRequest
 */
open class Request: IRequest, CustomStringConvertible {
    public let relativeUrl: String
    public let method: HttpRequestMethod
    public var headers: [String: String] = [:]
    public var parameters: [String: Any] = [:]
    public var encoding: HttpParameterEncoding { .json }
    open var timeout: TimeInterval { 30 } // default 30s
    
    public init(relativeUrl: String, method: HttpRequestMethod) {
        self.relativeUrl = relativeUrl
        self.method = method
    }
    
    public var description: String {
        return [
            "[Relative URL]:    \(relativeUrl)",
            "[Method]:          \(method.description)",
            "[Headers]:         \(headers.description)",
        ].joined(with: "\n")
    }
}

open class CodableRequest {
    public let relativeUrl: String
    public let method: HttpRequestMethod
    public var headers: [String: String] = [:]
    public var body: Encodable?
    public var encoding: HttpParameterEncoding { .json }
    open var timeout: TimeInterval { 30 } // default 30s
    
    public init(relativeUrl: String, method: HttpRequestMethod) {
        self.relativeUrl = relativeUrl
        self.method = method
    }
}

/**
 UploadFileInfo
 */
public protocol IUploadFileInfo {
    var url: URL? { get }
    var name: String { get }
}

/**
 IMultipartRequest
 */
public protocol IMultipartRequest: IRequest {
    var files: [IUploadFileInfo] { get }
}

open class MultipartRequest: Request, IMultipartRequest {
    public var files: [IUploadFileInfo] = []
    public init(relativeUrl: String, files: [IUploadFileInfo], method: HttpRequestMethod = .post) {
        super.init(relativeUrl: relativeUrl, method: method)
        self.files = files
    }
}
