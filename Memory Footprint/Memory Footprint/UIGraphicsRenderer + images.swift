//
//  Rendering.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 6/30/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation
import ImageIO
import UIKit

enum RenderingError : Error {
    case fileNotFound
    case unableToGetDataProvider
    case unableToCreateCGImage
    case unableToCreateImageSource
    case unableToCreateThumbnail
}

public extension UIGraphicsRenderer {

    static func renderImageAt(url: NSURL, size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        return try renderImagesAt(urls: [url], size: size, scale: scale)
    }

    static func renderImagesAt(urls: [NSURL], size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width * scale, size.height * scale),
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]

        let thumbnails = try urls.map { url -> CGImage in
            guard let imageSource = CGImageSourceCreateWithURL(url, nil) else { throw RenderingError.unableToCreateImageSource }

            guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {  throw RenderingError.unableToCreateThumbnail }
            return scaledImage
        }

        // Translate Y-axis down because cg images are flipped and it falls out of the frame (see bellow)
        let rect = CGRect(x: 0,
                          y: -size.height,
                          width: size.width,
                          height: size.height)

        let resizedImage = renderer.image { ctx in

            let context = ctx.cgContext
            context.scaleBy(x: 1, y: -1) //Flip it ( cg y-axis is flipped)

            for image in thumbnails {
                context.draw(image, in: rect)
            }
        }

        return resizedImage
    }
}
