import Foundation
import Alamofire

fileprivate let jsonArrayContentKey = "jsonArray"

extension Array {

    func toParameters() -> Parameters {
        return [jsonArrayContentKey: self]
    }

}

struct JSONArrayEncoding: ParameterEncoding {

    let options: JSONSerialization.WritingOptions

    init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }

    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        guard let parameters = parameters, let array = parameters[jsonArrayContentKey] else { return urlRequest }
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: options)
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            urlRequest.httpBody = data
        } catch {
            throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
        return urlRequest
    }

}

enum APIResult<ResultType: Codable> {
    case success(ResultType)
    case failure(error: APIError, didHandled: Bool)
}

class BaseAPI {
    
    static let jsonDecoder = JSONDecoder()
    
    static var headers = baseHeaders
    static var headersAuthorizationValue: String? {
        get {
            return headers[headersAuthroizationKey]
        }
        set {
            if let newValue = newValue {
                headers[headersAuthroizationKey] = "Bearer " + newValue
            } else {
                headers[headersAuthroizationKey] = nil
            }
        }
    }
    
    private static let headersAuthroizationKey = "Authorization"
    private static let baseHeaders: HTTPHeaders = [
        "Content-Type": "application/json"
    ]
    private static let rootURL = "https://"
    private static let jsonEncoding = JSONEncoding()
    
    private struct ResponseObject<ResultType: Codable>: Codable {
        let data: ResultType?
        let error: APIError?
    }

    func request(method: HTTPMethod, url: String, parameters: Parameters? = nil, encoding: ParameterEncoding = BaseAPI.jsonEncoding) {
        Alamofire.request(BaseAPI.rootURL + url, method: method, parameters: parameters, encoding: encoding, headers: BaseAPI.headers)
    }
    
    @discardableResult
    func request<ResultType>(method: HTTPMethod, url: String, parameters: Parameters? = nil, encoding: ParameterEncoding = BaseAPI.jsonEncoding, completion: @escaping (APIResult<ResultType>) -> Void) -> Request {
        return Alamofire.request(BaseAPI.rootURL + url, method: method, parameters: parameters, encoding: encoding, headers: BaseAPI.headers)
            .validate(statusCode: 200...299)
            .responseData(completionHandler: { (response) in
                let httpStatusCode = response.response?.statusCode ?? -1
                let apiError: APIError
                switch response.result {
                case .success(let data):
                    do {
                        let responseObject = try BaseAPI.jsonDecoder.decode(ResponseObject<ResultType>.self, from: data)
                        if let data = responseObject.data {
                            // Success
                            completion(.success(data))
                            return
                        } else if let error = responseObject.error {
                            // Server described error
                            apiError = error
                        } else {
                            // Response lacks both data and error field
                            apiError = .badResponse(status: httpStatusCode, description: nil)
                        }
                    } catch let error {
                        // JSON decoding failed
                        apiError = .jsonDecodingFailed(status: httpStatusCode, description: error.localizedDescription)
                    }
                case .failure(let error):
                    // Request failed. NSURL related errors in most cases, like "Not connected to internet"
                    let nsError = error as NSError
                    apiError = APIError(code: httpStatusCode, status: httpStatusCode, description: nsError.description)
                }
                completion(.failure(error: apiError, didHandled: BaseAPI.handle(error: apiError)))
            })
    }
    
    // TODO: Make a better warning
    // Return true if the error is handled, false if not
    @discardableResult
    static func handle(error: APIError) -> Bool {   
        switch error.kind {
        case .invalidAPITokenHeader:
            //logout
            return true
        case .cancelled, .notConnectedToInternet, .timedOut:
            UIApplication.currentViewController()?.alert(error.description ?? "Error")
            return true
        default:
            return false
        }
    }
    
}
