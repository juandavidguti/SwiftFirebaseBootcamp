//
//  ProductPreviewView.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 30/09/25.
//

import SwiftUI

struct ProductCellView: View {
    
    let product: Product? // optional to support optional and UI placeholders regardless of product
    
    var body: some View {
        HStack(alignment: .top,spacing: 12) {
            AsyncImage(
                url: URL(string: product?.thumbnail ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 75)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 75, height: 75)
                .shadow(color: Color.black.opacity(0.3),radius: 4,x: 0,y: 2)
            VStack(alignment: .leading,spacing: 4) {
                Text(product?.title ?? "")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                Text("Price: $" + String(product?.price ?? 0.0))
                Text("Rating: " + String(product?.rating ?? 0))
                Text("Category: " + (product?.category ?? "n/a"))
                Text("Brand :" + (product?.brand ?? "n/a"))
            }
            .font(.callout)
            .foregroundStyle(Color.secondary)
        }
    }
}

#Preview {
    ProductCellView(
        product: Product(
            id: 1,
            title: "Title",
            description: "test",
            price: 55,
            discountPercentage: 55,
            rating: 55,
            stock: 55,
            brand: "asdf",
            category: "jol",
            thumbnail: "hola",
            images: ["asdf"]
        )
    )
}
