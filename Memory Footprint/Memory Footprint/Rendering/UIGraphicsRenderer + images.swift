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

public extension UIGraphicsRenderer {
    static func renderImageAt(url: NSURL, size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        assert(url.isFileURL)
        return try renderImagesAt(urls: [url], size: size, scale: scale)
    }

    static func renderImagesAt(urls: [NSURL], size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        urls.forEach{ assert($0.isFileURL) }
        return try renderImage(size: size, sources: urls.map(RenderingSource.url), options: .defaults)
    }

    static func renderImageIncrementally(size: CGSize,
                                         scale: CGFloat = 1,
                                         fileURL: URL,
                                         options: ImageRenderingOptions = .incremental,
                                         timeInterval: TimeInterval = 0.1,
                                         increment:Int = 500,
                                         dispatchQueue:DispatchQueue = .global(qos: .userInitiated),
                                         callback: @escaping (UIImage) -> Void) throws -> ImageRenderingIncrementalSource {

        guard let source = try ImageRenderingIncrementalSource(fileURL: fileURL,
                                                          timeInterval: timeInterval,
                                                          increment: increment,
                                                          dispatchQueue: dispatchQueue) else {throw ImageRenderingError.unableToCreateImageSource}

        renderImageIncrementally(size: size, scale: scale,
                                 source: source,
                                 options: options,
                                 callback: callback)

        return source
    }

    static func renderImageIncrementally(size: CGSize,
                                         scale: CGFloat = 1,
                                         source: ImageRenderingIncrementalSource,
                                         options: ImageRenderingOptions,
                                         callback: @escaping (UIImage) -> Void) {
        source.load { source in
            guard let image = try? renderImage(size: size, sources: [source], options: options) else {fatalError()}
            callback(image)
        }
    }

    static func renderImage(size: CGSize,
                            scale: CGFloat = 1,
                            sources: [ImageRenderingSource],
                            options: ImageRenderingOptions) throws -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: size)

        var cgOptions: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width * scale, size.height * scale),
        ]
        cgOptions.merge(options.cgOptions, uniquingKeysWith: { a,b in b })

        let thumbnails = try sources.map { imageSource -> CGImage in
            guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource.cgSource, 0, cgOptions as CFDictionary) else {
                throw ImageRenderingError.unableToCreateThumbnail
            }
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


