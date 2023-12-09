//
//  Ge_LCMethod.swift
//  Ge_LCApi
//
//  Created by my on 2023/12/9.
//

import Foundation

public struct Ge_LCRequest {
    let ge_api: Ge_LCApi
    public enum Ge_LCHTTPMethod {
        case ge_post
        case ge_get
        case ge_put
        case ge_delete
    }
    let ge_httpMethod: Ge_LCHTTPMethod
    
    public enum Ge_LCParameters {
        case ge_query(ge_params: [String: Any])
        
        public enum Ge_LCParametersEncoding {
            case ge_default
            case ge_josn
        }
        case ge_body(ge_params: [String: Any], ge_encoding: Ge_LCParametersEncoding)
        
        public var ge_isQuery: Bool {
            switch self {
            case .ge_query: return true
            default: return false 
            }
        }
        
        public var ge_parameters: [String: Any] {
            switch self {
            case let .ge_query(ge_params): return ge_params
            case let .ge_body(ge_params, _): return ge_params
            }
        }
        
        public var ge_isJsonEncoding: Bool {
            switch self {
            case .ge_body(_, ge_encoding: .ge_josn): return true
            default: return false 
            }
        }
    }
    let ge_parameters: [Ge_LCParameters]
}

public extension Ge_LCApi {
    func ge_post(_ ge_urlParameters: [String: Any]? = nil, 
                 ge_bodyParameters: [String: Any],
                 ge_bodyEncoding: Ge_LCRequest.Ge_LCParameters.Ge_LCParametersEncoding) 
    -> Ge_LCRequest
    {
        var ge_parameters: [Ge_LCRequest.Ge_LCParameters] = [.ge_body(ge_params: ge_bodyParameters, ge_encoding: ge_bodyEncoding)]
        if let ge_urlParameters {
            ge_parameters.append(.ge_query(ge_params: ge_urlParameters))
        }
        return Ge_LCRequest(ge_api: self, ge_httpMethod: .ge_post, ge_parameters: ge_parameters)
    }
    
    func ge_get(_ ge_parameters: [String: Any] = [:]) -> Ge_LCRequest {
        Ge_LCRequest(ge_api: self, ge_httpMethod: .ge_get, ge_parameters: [.ge_query(ge_params: ge_parameters)])
    }
    
    func ge_put(_ ge_urlParameters: [String: Any]? = nil,
                 ge_bodyParameters: [String: Any],
                 ge_bodyEncoding: Ge_LCRequest.Ge_LCParameters.Ge_LCParametersEncoding)
    -> Ge_LCRequest
    {
        var ge_parameters: [Ge_LCRequest.Ge_LCParameters] = [.ge_body(ge_params: ge_bodyParameters, ge_encoding: ge_bodyEncoding)]
        if let ge_urlParameters {
            ge_parameters.append(.ge_query(ge_params: ge_urlParameters))
        }
        return Ge_LCRequest(ge_api: self, ge_httpMethod: .ge_put, ge_parameters: ge_parameters)
    }
    
    func ge_delete(_ ge_parameters: [String: Any] = [:]) -> Ge_LCRequest {
        Ge_LCRequest(ge_api: self, ge_httpMethod: .ge_delete, ge_parameters: [.ge_query(ge_params: ge_parameters)])
    }
}
