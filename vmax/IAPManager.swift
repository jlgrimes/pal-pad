//
//  IAPManager.swift
//  Pal Pad
//
//  Created by Jared Grimes on 1/5/20.
//  Copyright © 2020 Jared Grimes. All rights reserved.
//

import Foundation
import StoreKit

extension IAPManager.IAPManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noProductIDsFound: return "No In-App Purchase product identifiers were found."
        case .noProductsFound: return "No In-App Purchases were found."
        case .productRequestFailed: return "Unable to fetch available In-App Purchase products at the moment."
        case .paymentWasCancelled: return "In-App Purchase process was cancelled."
        }
    }
}

class IAPManager: NSObject {
    static let shared = IAPManager()
    var onReceiveProductsHandler: ((Result<[SKProduct], IAPManagerError>) -> Void)?
    var onBuyProductHandler: ((Result<Bool, Error>) -> Void)?
    
    enum IAPManagerError: Error {
        case noProductIDsFound
        case noProductsFound
        case paymentWasCancelled
        case productRequestFailed
    }
 
    private override init() {
        super.init()
    }
    
    fileprivate func getProductIDs() -> [String]? {
        guard let url = Bundle.main.url(forResource: "IAPProductIDs", withExtension: "plist") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let productIDs = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String] ?? []
            return productIDs
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func getProducts(withHandler productsReceiveHandler: @escaping (_ result: Result<[SKProduct], IAPManagerError>) -> Void) {
        // Keep the handler (closure) that will be called when requesting for
        // products on the App Store is finished.
        onReceiveProductsHandler = productsReceiveHandler
     
        // Get the product identifiers.
        guard let productIDs = getProductIDs() else {
            productsReceiveHandler(.failure(.noProductIDsFound))
            return
        }
     
        // Initialize a product request.
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
     
        // Set self as the its delegate.
        request.delegate = self
     
        // Make the request.
        request.start()
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transaction) in
             switch transaction.transactionState {
             case .purchased:
                     onBuyProductHandler?(.success(true))
                     SKPaymentQueue.default().finishTransaction(transaction)
              
             case .restored:
                guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
                
                   print("restore... \(productIdentifier)")
                   SKPaymentQueue.default().finishTransaction(transaction)
              
             case .failed:
             if let error = transaction.error as? SKError {
                 if error.code != .paymentCancelled {
                     onBuyProductHandler?(.failure(error))
                 } else {
                     onBuyProductHandler?(.failure(IAPManagerError.paymentWasCancelled))
                 }
                 print("IAP Error:", error.localizedDescription)
             }
             SKPaymentQueue.default().finishTransaction(transaction)
              
             case .deferred, .purchasing: break
             @unknown default: break
             }
        }
    }
    
    func startObserving() {
        SKPaymentQueue.default().add(self)
    }
     
     
    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
    
    public func restorePurchases() {
      SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func buy(product: SKProduct, withHandler handler: @escaping ((_ result: Result<Bool, Error>) -> Void)) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
     
        // Keep the completion handler.
        onBuyProductHandler = handler
    }
}

extension IAPManager: SKProductsRequestDelegate {
     func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
         // Get the available products contained in the response.
         let products = response.products
      
         // Check if there are any products available.
         if products.count > 0 {
             // Call the following handler passing the received products.
            onReceiveProductsHandler!(.success(products))
         } else {
             // No products were found.
            onReceiveProductsHandler!(.failure(.noProductsFound))
         }
     }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        onReceiveProductsHandler!(.failure(.productRequestFailed))
    }
}
