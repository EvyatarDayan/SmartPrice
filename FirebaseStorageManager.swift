//
//  FirebaseStorageManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import SwiftUI
import FirebaseStorage
import FirebaseAuth

class FirebaseStorageManager: ObservableObject {
    static let shared = FirebaseStorageManager()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let storage = Storage.storage()
    private let productImagesPath = "product_images"
    
    private init() {
        print("DEBUG: FirebaseStorageManager initialized")
    }
    
    // MARK: - Image Upload
    
    func uploadProductImage(_ imageData: Data, productId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "FirebaseStorageManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            completion(.failure(error))
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        // Create a unique filename for the image
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(productId)_\(timestamp).jpg"
        let imageRef = storage.reference().child("\(productImagesPath)/\(currentUser.uid)/\(filename)")
        
        print("DEBUG: Starting image upload for product \(productId) with filename \(filename)")
        
        // Upload the image
        let uploadTask = imageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    self?.errorMessage = "Error uploading image: \(error.localizedDescription)"
                    print("DEBUG: Error uploading image: \(error)")
                    completion(.failure(error))
                    return
                }
                
                // Get the download URL
                imageRef.downloadURL { url, error in
                    if let error = error {
                        self?.errorMessage = "Error getting download URL: \(error.localizedDescription)"
                        print("DEBUG: Error getting download URL: \(error)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        let error = NSError(domain: "FirebaseStorageManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("DEBUG: Image uploaded successfully. Download URL: \(downloadURL.absoluteString)")
                    completion(.success(downloadURL.absoluteString))
                }
            }
        }
        
        // Monitor upload progress
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                print("DEBUG: Upload progress: \(self?.uploadProgress ?? 0.0)")
            }
        }
    }
    
    // MARK: - Image Download
    
    func downloadProductImage(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "FirebaseStorageManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        print("DEBUG: Downloading image from URL: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG: Error downloading image: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    let error = NSError(domain: "FirebaseStorageManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    completion(.failure(error))
                    return
                }
                
                print("DEBUG: Image downloaded successfully. Size: \(data.count) bytes")
                completion(.success(data))
            }
        }.resume()
    }
    
    // MARK: - Image Deletion
    
    func deleteProductImage(urlString: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "FirebaseStorageManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        // Extract the path from the URL
        let path = url.path
        let imageRef = storage.reference().child(path)
        
        print("DEBUG: Deleting image at path: \(path)")
        
        imageRef.delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG: Error deleting image: \(error)")
                    completion(.failure(error))
                    return
                }
                
                print("DEBUG: Image deleted successfully")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Image Caching
    
    private let imageCache = NSCache<NSString, UIImage>()
    
    func getCachedImage(for urlString: String) -> UIImage? {
        return imageCache.object(forKey: urlString as NSString)
    }
    
    func cacheImage(_ image: UIImage, for urlString: String) {
        imageCache.setObject(image, forKey: urlString as NSString)
    }
    
    func downloadAndCacheImage(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Check cache first
        if let cachedImage = getCachedImage(for: urlString), let imageData = cachedImage.jpegData(compressionQuality: 1.0) {
            print("DEBUG: Using cached image for URL: \(urlString)")
            completion(.success(imageData))
            return
        }
        
        // Download from URL
        downloadProductImage(from: urlString) { [weak self] result in
            switch result {
            case .success(let data):
                // Cache the downloaded image if we can convert it to UIImage
                if let image = UIImage(data: data) {
                    self?.cacheImage(image, for: urlString)
                }
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Profile Image Management
    
    func uploadProfileImage(_ imageData: Data, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let profileImagePath = "profile_images/\(userId)/profile.jpg"
        let imageRef = storage.reference().child(profileImagePath)
        
        print("DEBUG: Uploading profile image for user: \(userId)")
        
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        let uploadTask = imageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    self?.errorMessage = "Error uploading profile image: \(error.localizedDescription)"
                    print("DEBUG: Error uploading profile image: \(error)")
                    completion(.failure(error))
                    return
                }
                
                // Get the download URL
                imageRef.downloadURL { url, error in
                    if let error = error {
                        self?.errorMessage = "Error getting profile image download URL: \(error.localizedDescription)"
                        print("DEBUG: Error getting profile image download URL: \(error)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        let error = NSError(domain: "FirebaseStorageManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get profile image download URL"])
                        completion(.failure(error))
                        return
                    }
                    
                    print("DEBUG: Profile image uploaded successfully. Download URL: \(downloadURL.absoluteString)")
                    completion(.success(downloadURL.absoluteString))
                }
            }
        }
        
        // Monitor upload progress
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                print("DEBUG: Profile image upload progress: \(self?.uploadProgress ?? 0.0)")
            }
        }
    }
    
    func downloadProfileImage(userId: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let profileImagePath = "profile_images/\(userId)/profile.jpg"
        let imageRef = storage.reference().child(profileImagePath)
        
        print("DEBUG: Downloading profile image for user: \(userId)")
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: profileImagePath as NSString) {
            print("DEBUG: Profile image found in cache")
            completion(.success(cachedImage))
            return
        }
        
        imageRef.downloadURL { url, error in
            if let error = error {
                print("DEBUG: Error getting profile image URL: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let url = url else {
                let error = NSError(domain: "FirebaseStorageManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile image not found"])
                completion(.failure(error))
                return
            }
            
            print("DEBUG: Profile image URL: \(url)")
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("DEBUG: Error downloading profile image: \(error)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let data = data, let image = UIImage(data: data) else {
                        let error = NSError(domain: "FirebaseStorageManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create image from data"])
                        completion(.failure(error))
                        return
                    }
                    
                    // Cache the image
                    self.imageCache.setObject(image, forKey: profileImagePath as NSString)
                    print("DEBUG: Profile image downloaded and cached successfully")
                    completion(.success(image))
                }
            }.resume()
        }
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetProgress() {
        uploadProgress = 0.0
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
        print("DEBUG: Image cache cleared")
    }
}
