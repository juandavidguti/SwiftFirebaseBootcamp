//
//  ProductCellViewBuilder.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 3/10/25.
//

import SwiftUI

struct ProductCellViewBuilder: View, Sendable {
    
    let productId: String
    @State private var product: Product? = nil
    
    var body: some View {
        ZStack {
            if let product {
                ProductCellView(product: product)
            }
        }
        .task {
            self.product = try? await ProductsManager.shared
                .getProduct(productId: productId)
        }
    }
}

#Preview {
    ProductCellViewBuilder(productId: "1")
}
