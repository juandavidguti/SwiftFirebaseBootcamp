//
//  StorageManager.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 5/10/25.
//

import Foundation
@preconcurrency import FirebaseStorage
import UIKit

final class StorageManager: Sendable {
    static let shared = StorageManager()
    private init() {}
    
    private let storage = Storage.storage().reference()
    
    private var imagesReference: StorageReference {
        storage.child("images")
    }
    
    private func userReference(userId: String) -> StorageReference {
        storage.child("users").child(userId)
    }
    
    func getPathForImage(path: String) -> StorageReference {
        storage.storage.reference(withPath: path)
    }
    
    func getUrlForImage(path: String) async throws -> URL {
        return try await getPathForImage(path: path).downloadURL()
    }
    
    func getData(userId: String, path: String) async throws -> Data {
//        try await userReference(userId: userId).child(path).data(maxSize: 3 * 1024 * 1024)
        try await storage.child(path).data(maxSize: 3 * 1024 * 1024)
    }
    
    func getImage(userId: String, path: String) async throws -> UIImage {
        let data = try await getData(userId: userId, path: path)
        guard let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        return image
    }
    
        // save in the server
    func saveImage(data: Data, userId: String) async throws -> (Path: String, Name: String) {
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        let path = "\(UUID().uuidString).jpeg"
        let returnedMetadata = try await userReference(userId: userId).child(path).putDataAsync(data, metadata: meta)
        
//        let returnedPath = returnedMetadata.path
//        let returnedName = returnedMetadata.name
        
        guard let returnedName = returnedMetadata.name, let returnedPath = returnedMetadata.path else {
            throw URLError(.badServerResponse)
        }
        
        return (returnedName, returnedPath)
    }
    
    func saveImage(image: UIImage, userId: String) async throws -> (Path: String, Name: String) {
        // image.pngData() we should compress images, does not make sense to have full size pics for profile pics downloaded in million users. probably a thumbnail is better. compression is good to save. Resize extensions helps.
        guard let data = image.jpegData(compressionQuality: 1) else {
            throw URLError(.badServerResponse)
        }
        
        return try await saveImage(data: data, userId: userId)
    }
    
    func deleteImage(path: String) async throws {
        try await getPathForImage(path: path).delete()
    }
}
