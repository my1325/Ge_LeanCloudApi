//
//  Ge_URLSession+LC.swift
//  Ge_LCApi
//
//  Created by my on 2023/12/9.
//

import Foundation
import Combine

public extension CharacterSet {
    // as afURLQueryAllowed
    static let ge_URLQueryAllowed: CharacterSet = {
        let ge_generalDelimitersToEncode = ":#[]@"
        let ge_subDelimitersToEncode = "!$&'()*+,;="
        let ge_encodableDelimiters = CharacterSet(charactersIn: "\(ge_generalDelimitersToEncode)\(ge_subDelimitersToEncode)")

        return CharacterSet.urlQueryAllowed.subtracting(ge_encodableDelimiters)
    }()
}

public extension Ge_LCRequest.Ge_LCHTTPMethod {
    var ge_httpMethod: String {
        switch self {
        case .ge_delete: return "DELETE"
        case .ge_get: return "GET"
        case .ge_post: return "POST"
        case .ge_put: return "PUT"
        }
    }
}

public extension Ge_LCRequest {
    var ge_requestURL: URL {
        let ge_urlParamsList = ge_parameters.filter { $0.ge_isQuery }
            .map(\.ge_parameters)
            .map(ge_parametersFormatter)
        
        let ge_urlParams = ge_urlParamsList.reduce(into: [:]) { $0.merge($1, uniquingKeysWith: { $1 }) }
        
        var ge_urlComponents = URLComponents(string: ge_api.ge_requestUrl.absoluteString)!
        let ge_queryItems = ge_urlComponents.queryItems ?? []
        ge_urlComponents.queryItems = ge_urlParams.reduce(ge_queryItems) { $0 + [.init(name: $1.key, value: $1.value)] }
        ge_urlComponents.queryItems = ge_queryItems
        
        guard let ge_requestURL = ge_urlComponents.url else {
            fatalError("\(ge_api.ge_requestUrl) \(ge_urlParams) combine invalid URL")
        }
        return ge_requestURL
    }
    
    var ge_requestHeaders: [String: String] {
        var ge_retHeaders = ge_api.ge_headers
        if ge_hasJsonEncoding {
            ge_retHeaders["Content-Type"] = "application/json"
        } else if ge_hasBodyParameters {
            ge_retHeaders["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
        }
        return ge_retHeaders
    }
    
    var ge_URLRequest: URLRequest {
        var ge_urlRequest = URLRequest(url: ge_requestURL)
        ge_urlRequest.allHTTPHeaderFields = ge_requestHeaders
        ge_urlRequest.httpMethod = ge_httpMethod.ge_httpMethod
        switch ge_httpMethod {
        case .ge_put, .ge_post:
            ge_urlRequest.httpBody = ge_encodeBodyParameters()
        default: break
        }
        return ge_urlRequest
    }
    
    var ge_hasJsonEncoding: Bool {
        ge_parameters.reduce(false) { $0 || $1.ge_isJsonEncoding }
    }
    
    var ge_hasBodyParameters: Bool {
        ge_parameters.reduce(false) { $0 || !$1.ge_isQuery }
    }
    
    private func ge_parametersFormatter(_ ge_map: [String: Any]) -> [String: String] {
        var ge_retValues: [String: String] = [:]
        ge_map.forEach {
            ge_retValues.merge(ge_queryEncoding($0.key, ge_value: $0.value), uniquingKeysWith: { $1 })
        }
        return ge_retValues
    }
    
    private func ge_escape(_ ge_string: String) -> String {
        ge_string.addingPercentEncoding(withAllowedCharacters: .ge_URLQueryAllowed) ?? ge_string
    }
    
    private func ge_queryEncoding(_ ge_key: String, ge_value: Any) -> [String: String] {
        var ge_retValue: [String: String] = [:]
        if let ge_boolValue = ge_value as? Bool {
            ge_retValue[ge_escape(ge_key)] = ge_escape(ge_boolToEncoding(ge_boolValue))
        } else if let ge_dictionary = ge_value as? [String: Any] {
            for (ge_nestedKey, ge_value) in ge_dictionary {
                ge_retValue.merge(ge_queryEncoding("\(ge_key)[\(ge_nestedKey)]", ge_value: ge_value), uniquingKeysWith: { $1 })
            }
        } else if let ge_array = ge_value as? [Any] {
            for (ge_index, ge_value) in ge_array.enumerated() {
                ge_retValue.merge(ge_queryEncoding(ge_arrayKeyEncoding(ge_key, ge_index: ge_index), ge_value: ge_value), uniquingKeysWith: { $1 })
            }
        } else {
            ge_retValue[ge_escape(ge_key)] = ge_escape("\(ge_value)")
        }
        return ge_retValue
    }
    
    private func ge_boolToEncoding(_ ge_bool: Bool) -> String {
        ge_bool ? "1" : "0"
    }
    
    private func ge_arrayKeyEncoding(_ ge_key: String, ge_index: Int) -> String {
        "\(ge_key)[]"
    }
    
    private func ge_encodeBodyParameters() -> Data {
        let ge_bodyParameters = ge_parameters.filter { !$0.ge_isQuery }
            .map(\.ge_parameters)
            .reduce([:]) { $0.merging($1, uniquingKeysWith: { $1 }) }
        
        if ge_hasJsonEncoding {
            guard JSONSerialization.isValidJSONObject(ge_bodyParameters) else {
                fatalError("can not handle value to string \(ge_bodyParameters)")
            }
            do {
                let ge_jsonData = try JSONSerialization.data(withJSONObject: ge_bodyParameters)
                return ge_jsonData
            } catch {
                fatalError("can not handle value to string \(ge_bodyParameters)")
            }
        } else {
            var ge_allEncodings: [(String, String)] = []
            for ge_key in ge_bodyParameters.keys.sorted(by: <) {
                let ge_value = ge_bodyParameters[ge_key]!
                let ge_encodings = ge_queryEncoding(ge_key, ge_value: ge_value).map { ($0.key, $0.value) }
                ge_allEncodings += ge_encodings
            }
            let ge_encodingString = ge_allEncodings.map { "\($0)=\($1)" }.joined(separator: "&")
            return Data(ge_encodingString.utf8)
        }
    }
}

public extension URLSession {
    func ge_request(_ ge_request: Ge_LCRequest) -> URLSessionDataTask {
        URLSession.shared.dataTask(with: ge_request.ge_URLRequest)
    }
    
    func ge_requestPublisher(_ ge_request: Ge_LCRequest) -> URLSession.DataTaskPublisher {
        URLSession.shared.dataTaskPublisher(for: ge_request.ge_URLRequest)
    }
    
    struct Ge_MultiparFormData {
        public enum Ge_FormData {
            case ge_filePath(String)
            case ge_data(Data)
            
            var ge_inputStream: InputStream {
                switch self {
                case let .ge_data(ge_data): return InputStream(data: ge_data)
                case let .ge_filePath(ge_filePath): return InputStream(fileAtPath: ge_filePath)!
                }
            }
            
            var ge_bodyContentLength: UInt64 {
                switch self {
                case let .ge_data(ge_data): return UInt64(ge_data.count)
                case let .ge_filePath(ge_filePath):
                    guard let ge_attributes = try? FileManager.default.attributesOfItem(atPath: ge_filePath),
                          let ge_fileSize = ge_attributes[.size] as? NSNumber
                    else {
                        return 0
                    }

                    return ge_fileSize.uint64Value
                }
            }
        }
        
        let ge_headers: [String: String] = [:]
        let ge_formData: Ge_FormData
        let ge_mimeType: String
        let ge_fileName: String
        let ge_name: String
        let ge_boundary: String
        let ge_hasInitialBoundary: Bool
        let ge_hasFinalBoundary: Bool
        let ge_inputStream: InputStream
        let ge_bodyContentLength: UInt64
        
        public init(ge_formData: Ge_FormData,
                    ge_headers: [String: String] = [:],
                    ge_mimeType: String,
                    ge_fileName: String,
                    ge_name: String,
                    ge_boundary: String = Ge_MultiparFormData.ge_randomBoundary(),
                    ge_hasInitialBoundary: Bool = true,
                    ge_hasFinalBoundary: Bool = true)
        {
            self.ge_hasFinalBoundary = ge_hasFinalBoundary
            self.ge_hasInitialBoundary = ge_hasInitialBoundary
            self.ge_bodyContentLength = ge_formData.ge_bodyContentLength
            self.ge_inputStream = ge_formData.ge_inputStream
            self.ge_formData = ge_formData
            self.ge_mimeType = ge_mimeType
            self.ge_fileName = ge_fileName
            self.ge_name = ge_name
            self.ge_boundary = ge_boundary
        }
        
        public static func ge_randomBoundary() -> String {
            let ge_first = UInt32.random(in: UInt32.min...UInt32.max)
            let ge_second = UInt32.random(in: UInt32.min...UInt32.max)

            return String(format: "ge.boundary.%08x%08x", ge_first, ge_second)
        }
        
        enum Ge_EncodingCharacters {
            static let ge_crlf = "\r\n"
        }
        
        var ge_bodyPartData: Data {
            var ge_encoded = Data()

            let ge_initialData = ge_hasInitialBoundary ? ge_initialBoundaryData : ge_encapsulatedBoundaryData
            ge_encoded.append(ge_initialData)

            ge_encoded.append(ge_encodeHeaders)

            let ge_bodyStreamData = encodeBodyStream
            ge_encoded.append(ge_bodyStreamData)

            if ge_hasFinalBoundary {
                ge_encoded.append(ge_finalBoundaryData)
            }

            return ge_encoded
        }
        
        private var ge_encodeHeaders: Data {
            
            var ge_retHeaders = ge_headers
            ge_retHeaders["Content-Disposition"] = "form-data; name=\"\(ge_name)\"; filename=\"\(ge_fileName)\""
            ge_retHeaders["Content-Type"] = ge_mimeType
            let ge_headerText = ge_retHeaders.map { "\($0.key): \($0.value)\(Ge_EncodingCharacters.ge_crlf)" }
                .joined()
                + Ge_EncodingCharacters.ge_crlf

            return Data(ge_headerText.utf8)
        }
        
        private var ge_initialBoundaryData: Data {
            Data("--\(ge_boundary)\(Ge_EncodingCharacters.ge_crlf)".utf8)
        }

        private var ge_encapsulatedBoundaryData: Data {
            Data("\(Ge_EncodingCharacters.ge_crlf)--\(ge_boundary)\(Ge_EncodingCharacters.ge_crlf)".utf8)
        }

        private var ge_finalBoundaryData: Data {
            Data("\(Ge_EncodingCharacters.ge_crlf)--\(ge_boundary)--\(Ge_EncodingCharacters.ge_crlf)".utf8)
        }
        
        private var encodeBodyStream: Data {
            ge_inputStream.open()
            defer { ge_inputStream.close() }

            var ge_encoded = Data()

            while ge_inputStream.hasBytesAvailable {
                var ge_buffer = [UInt8](repeating: 0, count: 1024)
                let ge_bytesRead = ge_inputStream.read(&ge_buffer, maxLength: 1024)

                if let ge_error = ge_inputStream.streamError {
                    fatalError("inpu stream read failed \(ge_error)")
//                    throw AFError.multipartEncodingFailed(reason: .inputStreamReadFailed(error: error))
                }

                if ge_bytesRead > 0 {
                    ge_encoded.append(ge_buffer, count: ge_bytesRead)
                } else {
                    break
                }
            }

            guard UInt64(ge_encoded.count) == ge_bodyContentLength else {
                fatalError("unexpected input stream length \(UInt64(ge_encoded.count)) expected \(ge_bodyContentLength)")
            }

            return ge_encoded
        }
    }
    
    func ge_uploadRequest(_ ge_baseURL: URL, ge_formData: Ge_MultiparFormData) -> URLSessionUploadTask {
        var ge_urlRequest = URLRequest(url: ge_baseURL)
        ge_urlRequest.httpMethod = "POST"
        ge_urlRequest.setValue("multipart/form-data; boundary=\(ge_formData.ge_boundary)", forHTTPHeaderField: "Content-Type")
        return URLSession.shared.uploadTask(with: ge_urlRequest, from: ge_formData.ge_bodyPartData)
    }
    
    struct Ge_UploadTaskPublisher: Publisher {
        public typealias Output = (data: Data, response: URLResponse)
        public typealias Failure = Error

        public let ge_request: URLRequest

        public let ge_session: URLSession
        
        public let ge_formData: Ge_MultiparFormData

        public init(ge_request: URLRequest, ge_session: URLSession, ge_formData: Ge_MultiparFormData) {
            self.ge_request = ge_request
            self.ge_session = ge_session
            self.ge_formData = ge_formData
        }
        
        private final class Ge_UploadTaskSubscription<S: Subscriber>: Subscription where S.Failure == Error, S.Input == (data: Data, response: URLResponse) {
            public let ge_request: URLRequest

            public let ge_session: URLSession
            
            public let ge_formData: Ge_MultiparFormData
            
            private var ge_uploadTask: URLSessionUploadTask?
            
            private let ge_subscriber: S
            
            init(ge_subscriber: S, ge_request: URLRequest, ge_session: URLSession, ge_formData: Ge_MultiparFormData) {
                self.ge_subscriber = ge_subscriber
                self.ge_request = ge_request
                self.ge_session = ge_session
                self.ge_formData = ge_formData
            }
            
            func request(_ demand: Subscribers.Demand) {
                ge_uploadTask = URLSession.shared.uploadTask(with: ge_request, from: ge_formData.ge_bodyPartData, completionHandler: { [weak self] (ge_data, ge_URLResponse, ge_error) in
                    if let ge_error {
                        self?.ge_subscriber.receive(completion: .failure(ge_error))
                    } else if let ge_data, let ge_URLResponse {
                        _ = self?.ge_subscriber.receive((ge_data, ge_URLResponse))
                        self?.ge_subscriber.receive(completion: .finished)
                    } else {
                        self?.ge_subscriber.receive(completion: .finished)
                    }
                })
                ge_uploadTask?.resume()
            }
            
            func cancel() {
                ge_uploadTask?.cancel()
            }
        }
       
        public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Error, S.Input == (data: Data, response: URLResponse) {
            subscriber.receive(subscription: Ge_UploadTaskSubscription(ge_subscriber: subscriber, ge_request: ge_request, ge_session: ge_session, ge_formData: ge_formData))
        }
    }
    
    func ge_uploadRequestPublisher(_ ge_baseURL: URL, ge_formData: Ge_MultiparFormData) -> Ge_UploadTaskPublisher {
        var ge_urlRequest = URLRequest(url: ge_baseURL)
        ge_urlRequest.httpMethod = "POST"
        ge_urlRequest.setValue("multipart/form-data; boundary=\(ge_formData.ge_boundary)", forHTTPHeaderField: "Content-Type")
        return .init(ge_request: ge_urlRequest, ge_session: URLSession.shared, ge_formData: ge_formData)
    }
}
