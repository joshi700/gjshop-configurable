//
//  ContentView.swift
//  GJShop_Configurable
//

import SwiftUI

struct ContentView: View {
    @State private var items = [Item]()
    @Binding var cartItems: [Item]
    @Binding var currentPage: String?

    func loadItems() {
        self.items = [Item]()

        self.items.append(
            Item(
                name: "Professional skateboard",
                imageUrl: "https://raw.githubusercontent.com/joshi700/SessionBackend1/refs/heads/main/skateboard.png",
                price: 56.56,
                description: "Professional complete skateboard with 7-ply maple deck, featuring high-quality trucks and smooth-rolling wheels perfect for street and park riding."
            )
        )
        self.items.append(
            Item(
                name: "Premium skateboard bearings",
                imageUrl: "https://raw.githubusercontent.com/joshi700/SessionBackend1/refs/heads/main/bearing.png",
                price: 56.56,
                description: "Premium skateboard bearings with single, non-contact removable rubber shield for easy cleaning and maximum performance on any terrain."
            )
        )
        self.items.append(
            Item(
                name: "Classic Sneakers",
                imageUrl: "https://raw.githubusercontent.com/joshi700/SessionBackend1/refs/heads/main/sneakers.png",
                price: 56.56,
                description: "Iconic skate shoes with durable suede and canvas uppers, reinforced toecaps, and signature waffle outsole for superior grip and board feel."
            )
        )
        self.items.append(
            Item(
                name: "Apple Pay Test",
                imageUrl: "https://raw.githubusercontent.com/joshi700/SessionBackend1/refs/heads/main/skateboarding.png",
                price: 56.56,
                description: "Apple Pay integration test item. Only one can be added to cart.",
                maxQuantity: 1
            )
        )
    }

    var body: some View {
        ScrollView {
            ForEach(self.items, id: \.id) { item in
                NavigationLink(
                    destination: ItemView(selectedItem: item, cartItems: self.$cartItems),
                    label: {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                AsyncImage(url: URL(string: item.imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                } placeholder: {
                                    Image(systemName: "cart")
                                }
                            }
                            .padding(.leading)

                            VStack(alignment: .leading, spacing: 10) {
                                Text(item.name)
                                    .bold()
                                Text("$" + item.price.description)
                                Text(item.description)
                                    .lineLimit(2)
                                    .font(.footnote)
                            }
                            .padding(.trailing)
                        }
                        .frame(width: 355, height: 150)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.black.withAlphaComponent(0.12)), lineWidth: 1)
                                .shadow(color: Color(UIColor.white.withAlphaComponent(0.12)), radius: 0.5, x: 0, y: 1)
                        )
                        .shadow(color: Color(UIColor.black.withAlphaComponent(0.12)), radius: 8, x: 0, y: 8)
                    }
                )
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Select Items")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(
                    destination: SettingsView(),
                    label: {
                        Image(systemName: "gearshape")
                    }
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: CartView(cartItems: self.$cartItems),
                    label: {
                        Image(systemName: "cart.badge.plus")
                    }
                )
            }
        }
        .onAppear {
            self.loadItems()
        }
    }
}
