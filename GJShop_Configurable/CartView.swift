//
//  CartView.swift
//  GJShop_Configurable
//

import SwiftUI
struct CartView: View {
    @Binding var cartItems: [Item]
    var body: some View {
        ScrollView {
            Spacer()
            if (!self.cartItems.isEmpty) {
                ForEach(self.cartItems, id: \.id) { item in
                    HStack {
                        HStack {
                            AsyncImage(url: URL(string: item.imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30)
                            } placeholder: {
                                Image(systemName: "image")
                            }
                            Text(item.name)
                        }
                        .frame(width: 260, alignment: .leading)

                        HStack {
                            Text("$" + item.price.description)
                        }
                        .frame(width: 75, alignment: .trailing)
                    }
                    .frame(width: 350)
                }
                HStack {
                    HStack {
                        Text("Total")
                            .bold()
                    }
                    .frame(width: 260, alignment: .leading)

                    HStack {
                        Text("$" + self.cartItems.reduce(0, {$0 + $1.price}).description)
                            .bold()
                            .padding(.top)
                    }
                    .frame(width: 75, alignment: .trailing)
                }
                .frame(width: 350)
            }
            else {
                Text("Your cart is empty!")
            }
        }
        .navigationTitle("Cart Summary")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: ShippingView(cartItems: self.$cartItems),
                    label: {
                        HStack {
                            Text("Checkout")
                            Image(systemName: "cart.fill")
                        }
                    }
                )
            }
        }
    }
}
