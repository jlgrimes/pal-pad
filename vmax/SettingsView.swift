//
//  SettingsView.swift
//  Pal Pad
//
//  Created by Jared Grimes on 1/5/20.
//  Copyright © 2020 Jared Grimes. All rights reserved.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Binding var showAds: Bool
    @Binding var leaksMode: Bool
    @State var products: [SKProduct] = []
    
    func purchase(product: SKProduct) -> Bool {
        if !IAPManager.shared.canMakePayments() {
            return false
        } else {
             IAPManager.shared.buy(product: product) { (result) in
                 switch result {
                 case .success(_):
                    if product.productIdentifier == "com.jaredgrimes.palpad.removeads" {
                                    self.showAds = false
                                    let defaults = UserDefaults.standard
                                    if (!defaults.bool(forKey: "adsRemoved")) {
                                        defaults.set(true, forKey: "adsRemoved")
                                    }
                                }
                            if product.productIdentifier == "com.jaredgrimes.palpad.leakspackage" {
                                    self.leaksMode = false
                                    let defaults = UserDefaults.standard
                                    if (!defaults.bool(forKey: "leaksMode")) {
                                        defaults.set(true, forKey: "leaksMode")
                                    }
                                }
                    
                 case .failure(let error): print("oh no")
                 }
             }
        }
     
        return true
    }
    
    var body: some View {
            
       IAPManager.shared.getProducts { (result) in
    
           DispatchQueue.main.async {
               switch result {
               case .success(let products): self.products = products;
               case .failure(let error): print(error.localizedDescription)
               }
           }
       }
        
        return
            ScrollView {
            VStack {
                Group {
                    Image(uiImage: UIImage(named: "AppIcon")!)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    Text("Pal Pad")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Made by Jared Grimes")
                        .font(.title)
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
            Group {
                Text("In-App Purchases")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Help out ya boy to support development of this app! More DLC coming soon ;)")
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                
                Divider()
                
                ForEach (0..<self.products.count, id: \.self) { p in
                    Group {
                        Text(self.products[p].localizedTitle)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if self.products[p].productIdentifier == "com.jaredgrimes.palpad.leakspackage" {
                            Text("No leaks? Nah. You gotta leak to your homies. Even if there is no HeyFonte. Which is why I made a seamless way to do so - right from the Export view in your deck. You can export your deck as an image, either in portrait or landscape mode! Save this image to your phone, send it to anyone you want, or even upload it to Facebook - your choice.")
                                .fixedSize(horizontal: false, vertical: true)
                                .padding()
                        }
                        else {
                            Text(self.products[p].localizedDescription)
                                .padding()
                        }
                        
                        Button(action: {
                            self.purchase(product: self.products[p])
                        }) {
                            self.showAds ? Text("Buy - " + String(describing: self.products[p].price)) :
                            Text("Bought ✅").foregroundColor(Color.green)
                        }
                        Divider()
                    }
                }
                }
                
                Group {
                    Text("Credits")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Thanks to the Pokestats gang, Val Chang, and Rahul Reddy for beta testing. All card assets belong to The Pokemon Company Interational. All information shown in the Limitless Import view was compiled by the folks over at Limitless TCG.")
                        .padding()
                    .fixedSize(horizontal: false, vertical: true)
                }
                }
            }
        }
    }