//
//  ImageDownloadService.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation
import UIKit

class ImageDownloadService: ObservableObject {
    static let shared = ImageDownloadService()
    
    private let session = URLSession.shared
    private var imageCache: [String: UIImage] = [:]
    
    private init() {}
    
    func downloadImage(from urlString: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache[urlString] {
            return cachedImage
        }
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            // Cache the image
            imageCache[urlString] = image
            
            return image
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
    
    func downloadImageData(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            return data
        } catch {
            print("Error downloading image data: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        imageCache.removeAll()
    }
}

