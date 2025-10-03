//
//  ProductsViewModel.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 3/10/25.
//

import SwiftUI
import FirebaseFirestore
import Foundation

@MainActor
final class ProductsViewModel: ObservableObject {
    
    
    @Published private(set) var products: [Product] = []
    @Published var selectedFilter: FilterOption? = nil
    @Published var selectedCategory: CategoryOption? = nil
    private var lastDocument: DocumentSnapshot? = nil
//
//    func getAllProducts() async throws {
//        self.products = try await ProductsManager.shared.getAllProducts()
//    }
    
    enum FilterOption: String, CaseIterable {
        case priceHigh
        case priceLow
        case noFilter
        
        var priceDescending: Bool? {
            switch self {
                case .priceHigh: return true
                case .priceLow: return false
                case .noFilter: return nil
            }
        }
    }

    func filterSelected(option: FilterOption) async throws {
        self.selectedFilter = option
        self.products = []
        self.lastDocument = nil
        self.getProducts()
    }
    
    enum CategoryOption: String, CaseIterable {
        case beauty
        case furniture
        case groceries
        case noCategory
        
        var categoryKey: String? {
            if self == .noCategory {
                return nil
            }
            return self.rawValue
        }
    }
    
    func categorySelected(option: CategoryOption) async throws {
        self.selectedCategory = option
        self.products = []
        self.lastDocument = nil
        self.getProducts()
        
    }
    func getProducts() {
        Task {
            let (newProducts, lastDocument) = try await ProductsManager.shared
                .getAllProducts(priceDescending: selectedFilter?.priceDescending,
                                forCategory: selectedCategory?.categoryKey, count: 10, lastDocument: lastDocument)
            self.products.append(contentsOf: newProducts)
            if let lastDocument {
                self.lastDocument = lastDocument
            }
        }
    }
    
    
    func addUserFavoriteProduct(productId: Int) {
        Task {
            let authDataResults = try AuthenticationManager.shared.getAuthenticatedUser()
            try? await UserManager.shared
                .addUserFavoriteProduct(
                    userId: authDataResults.uid,
                    productId: productId
                )
        }
    }
    
    // pagination of data
//    func getProductsByRating() {
//        Task {
////            let newProducts = try await ProductsManager.shared
////                .getProductByRating(
////                    count: 3,
////                    lastRating: self.products.last?.rating
////                )
//            let (newProducts, lastDocument) = try await ProductsManager.shared.getProductByRating(count: 3,lastDocument: lastDocument)
//            self.products.append(contentsOf: newProducts)
//            self.lastDocument = lastDocument
//        }
//    }
    
//    func getProductCount() {
//        Task {
//            let count = try await ProductsManager.shared.getAllProductsCount()
//            print("ALL PRODUCT COUNT: \(count)")
//        }
//    }
    
}
