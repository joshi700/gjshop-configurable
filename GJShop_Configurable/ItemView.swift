//
//  ItemView.swift
//  GJShop_Configurable
//

import SwiftUI

struct ItemView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var selectedItem: Item
    @Binding var cartItems: [Item]

    private var quantityInCart: Int {
        cartItems.filter { $0.name == selectedItem.name }.count
    }

    private var canAddToCart: Bool {
        selectedItem.maxQuantity == 0 || quantityInCart < selectedItem.maxQuantity
    }

    var body: some View {
        ScrollView {
            AsyncImage(url: URL(string: self.selectedItem.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            } placeholder: {
                Image(systemName: "image")
            }

            Text(self.selectedItem.name)
                .font(.title2)
                .padding(.top)
                .bold()
            Text("$" + self.selectedItem.price.description)
            Text(self.selectedItem.description)
                .multilineTextAlignment(.center)
                .padding()

            if selectedItem.maxQuantity > 0 {
                Text("Limit: \(selectedItem.maxQuantity) per order")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            HStack {
                Image(systemName: canAddToCart ? "cart.fill.badge.plus" : "xmark.circle.fill")
                    .padding(.trailing)
                    .foregroundColor(Color.white)
                Text(canAddToCart ? "Add to cart" : "Already in cart")
                    .foregroundColor(Color.white)
            }
            .frame(width: 355, height: 40)
            .background(canAddToCart ? Color.indigo : Color.gray)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(UIColor.black.withAlphaComponent(0.12)), lineWidth: 1)
                    .shadow(color: Color(UIColor.white.withAlphaComponent(0.12)), radius: 0.5, x: 0, y: 1)

            )
            .shadow(color: Color(UIColor.black.withAlphaComponent(0.12)), radius: 24, x: 0, y: 8)
            .onTapGesture {
                if canAddToCart {
                    self.cartItems.append(self.selectedItem)
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
