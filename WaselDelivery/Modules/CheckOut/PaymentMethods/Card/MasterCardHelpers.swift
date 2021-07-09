//
//  MasterCardHelpers.swift
//  WaselDelivery
//
//  Created by Radu Ursache on 14/05/2019.
//  Copyright © 2019 [x]cube Labs. All rights reserved.
//

import Foundation
import PassKit
//import MPGSDK

enum Result<T> {
    case success(T)
    case error(Error)
}

enum MerchantAPIError: Error {
    case failedRequest
    case other(Error)
}

// a structure bundling the session id and the api version on which that session was created.
struct GatewaySession {
    var id: String
    var apiVersion: String
}

struct Transaction {
    // The Payment Session from the gateway
    var session: GatewaySession?
    
    // basic transaction properties
    var amount: NSDecimalNumber = 0.1
    var amountString = "0.10"
    var currency = "BHD"
    var amountFormatted = "BHD 0.10"
    var summary = "Some transaction"
    
    // card information
    var nameOnCard: String?
    var cardNumber: String?
    var expiryMM: String?
    var expiryYY: String?
    var cvv: String?
    
    // Apple Pay Information
    var applePayMerchantIdentifier: String?
    var countryCode = "US"
    var supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .discover, .amex]
    var applePayPayment: PKPayment?
    
    var isApplePay: Bool {
        return applePayPayment != nil
    }
    
    var orderId: String = Transaction.randomID()
    var id: String = Transaction.randomID()
    
    // a masked card number for the confirmation text
    var maskedCardNumber: String? {
        guard let number = cardNumber else { return nil }
        let last4 = number.suffix(4)
        let dotCount = number.dropLast(last4.count).count
        return String(repeating: "•", count: dotCount) + last4
    }
    
    // a 3DSecure ID used to identify the transaction durring the 3DS steps with the gateway
    var threeDSecureId: String? = Transaction.randomID()
    
    var pkPaymentRequest: PKPaymentRequest? {
        guard let merchantId = applePayMerchantIdentifier else { return nil }
        let request = PKPaymentRequest()
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: summary, amount: amount, type: .final)]
        request.merchantIdentifier = merchantId
        request.countryCode = countryCode
        request.currencyCode = currency
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = [.capabilityCredit, .capabilityDebit, .capability3DS]
        return request
    }
    
    static func randomID() -> String {
        return String(UUID().uuidString.split(separator: "-").first!)
    }
}

class MerchantAPI {
    static var shared: MerchantAPI?
    
    let merchantServerURL: URL
    let urlSession: URLSession
    lazy var decoder: JSONDecoder = JSONDecoder()
    
    init(url: URL, urlSession: URLSession = .shared) {
        self.merchantServerURL = url
        self.urlSession = urlSession
    }
    
    func createSession(completion: @escaping (Result<GatewayMap>) -> Void) {
        issueRequest(path: "api/v2/security/credimax/session", method: "POST", completion: completion)
    }
    
    func makePaymentWithToken(paymentToken: String?, sessionId: String?, threeDSecureId: String?, orderId: String, transactionId: String, amount: String, currency: String, completion: @escaping (Result<GatewayMap>) -> Void) {
        
        var payload = GatewayMap(["apiOperation": "PAY"])//"AUTHORIZE"])
        if paymentToken != nil {
            payload[at: "sourceOfFunds.token"] =  paymentToken
        }
        if sessionId != nil {
            payload[at: "session.id"] =  sessionId
        }
        
        if (threeDSecureId != nil) {
            payload[at: "3DSecureId"] =  threeDSecureId
        }
      
        payload[at: "order.amount"] = amount
//        payload[at: "order.amount"] = "0.01"
        payload[at: "order.currency"] = currency
        payload[at: "sourceOfFunds.type"] = "CARD"
        payload[at: "transaction.source"] = "INTERNET"
        payload[at: "transaction.frequency"] = "SINGLE"
        
        issueRequest(path: "api/v2/security/credimax/transaction/order/" + orderId + "/transaction/" + transactionId, method: "PUT", body: payload, completion: completion)
    }
    
    func check3DSEnrollment(transaction: Transaction, redirectURL: String, completion: @escaping (Result<GatewayMap>) -> Void) {
        var payload = GatewayMap(["apiOperation": "CHECK_3DS_ENROLLMENT"])
        payload[at: "order.amount"] = transaction.amountString
        payload[at: "order.currency"] = transaction.currency
        payload[at: "session.id"] = transaction.session?.id
        payload[at: "3DSecure.authenticationRedirect.responseUrl"] = redirectURL
        
        let query = [URLQueryItem(name: "3DSecureId", value: transaction.threeDSecureId)]
        
        print(payload.dictionary)
        print("3DSecureId: \(transaction.threeDSecureId)")
        
        issueRequest(path: "3DSecure.php", method: "PUT", query: query, body: payload, completion: completion)
    }
    
    func executeCheck3DSEnrollment(sessionId: String, amount: String, completion: @escaping (Result<GatewayMap>) -> Void) {
        var payload = GatewayMap(["sessionId": sessionId])
        payload[at: "orderAmount"] = amount
        
        issueRequest(path: "api/v2/security/credimax/check3dsEnrollment", method: "POST",  body: payload, completion: completion)
    }
    
    func completeSession(transaction: Transaction, completion: @escaping (Result<GatewayMap>) -> Void) {
        var payload = GatewayMap(["apiOperation": "PAY"])//"AUTHORIZE"])
        payload[at: "sourceOfFunds.type"] =  "CARD"
        payload[at: "transaction.frequency"] = "SINGLE"
        payload[at: "transaction.source"] = "INTERNET"
        payload[at: "order.amount"] = transaction.amountString
        payload[at: "order.currency"] = transaction.currency
        payload[at: "session.id"] = transaction.session!.id
        if let threeDSecureId = transaction.threeDSecureId {
            payload[at: "3DSecureId"] = threeDSecureId
        }
        if transaction.isApplePay {
            payload[at: "order.walletProvider"] = "APPLE_PAY"
        }
        
        let query = [URLQueryItem(name: "order", value: transaction.orderId), URLQueryItem(name: "transaction", value: transaction.id)]
        issueRequest(path: "transaction.php", method: "PUT", query: query, body: payload, completion: completion)
        
    }
    
    fileprivate func issueRequest(path: String, method: String, query: [URLQueryItem]? = nil, body: GatewayMap? = nil, completion: @escaping (Result<GatewayMap>) -> Void) {
        var completeURLComp = URLComponents(url: merchantServerURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        completeURLComp.queryItems = query
        var request = URLRequest(url: completeURLComp.url!)
        
        let accessToken_ = Utilities.getAccessToken()
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.addValue("Bearer \(accessToken_!)", forHTTPHeaderField: "Authorization")
        
        
        print("url: \((request.url?.absoluteString)!)")
        
        request.httpMethod = method
        
        let encoder = JSONEncoder()
        if (body != nil) {
            request.httpBody = try? encoder.encode(body)
        }
        
        print("params: \(request.httpBody)")
        
        let task = urlSession.dataTask(with: request, completionHandler: responseHandler(completion))
        task.resume()
    }
    
    fileprivate func responseHandler<T: Decodable>(_ completion: @escaping (Result<T>) -> Void) -> (Data?, URLResponse?, Error?) -> Void {
        return { (data, response, error) in
            if let error = error {
                completion(Result.error(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode), let data = data else {
                completion(Result.error(MerchantAPIError.failedRequest))
                return
            }
            
            
            print(String(data: data, encoding: .utf8) ?? "Invalid Data")
            
            do {
                let response = try self.decoder.decode(T.self, from: data)
                completion(.success(response))
            } catch {
                completion(Result.error(error))
            }
        }
    }
}
