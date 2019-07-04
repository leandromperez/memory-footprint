//
//  ImageRenderingOptions.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 7/3/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation
import ImageIO

public struct ImageRenderingOptions {
    public let createThumbnailFromImageAlways : Bool
    public let createThumbnailFromImageIfAbsent: Bool
    public let shouldAllowFloat: Bool
    public let shouldCache: Bool
    public var shouldCacheImmediately: Bool? = nil
    public var thumbnailMaxPixelSize : CGFloat? = nil
    public var thumbnailWithTransform : Bool? = nil

    public var cgOptions: [NSString: Any] {
        var result : [NSString: Any] =  [
            kCGImageSourceShouldAllowFloat : shouldAllowFloat,
            kCGImageSourceShouldCache : shouldCache,
            kCGImageSourceCreateThumbnailFromImageIfAbsent : createThumbnailFromImageIfAbsent,
            kCGImageSourceCreateThumbnailFromImageAlways : createThumbnailFromImageAlways
        ]

        if let shouldCacheImmediately = shouldCacheImmediately {
            result[kCGImageSourceShouldCacheImmediately] = shouldCacheImmediately
        }
        if let thumbnailMaxPixelSize = thumbnailMaxPixelSize {
            result[kCGImageSourceThumbnailMaxPixelSize] = thumbnailMaxPixelSize
        }
        if let thumbnailWithTransform = thumbnailWithTransform {
            result[kCGImageSourceCreateThumbnailWithTransform] = thumbnailWithTransform
        }

        return result
    }

    public static var defaults : ImageRenderingOptions {
        return ImageRenderingOptions(createThumbnailFromImageAlways : true,
                                     createThumbnailFromImageIfAbsent:  false,
                                     shouldAllowFloat: false,
                                     shouldCache: true,
                                     shouldCacheImmediately: nil,
                                     thumbnailMaxPixelSize: nil,
                                     thumbnailWithTransform: nil)
    }

    public static var incremental : ImageRenderingOptions {
        return ImageRenderingOptions(createThumbnailFromImageAlways: true,
                                     createThumbnailFromImageIfAbsent: false,
                                     shouldAllowFloat: true,
                                     shouldCache: false,
                                     shouldCacheImmediately: true,
                                     thumbnailMaxPixelSize: nil,
                                     thumbnailWithTransform: nil)
    }

    public static func downsampling(maxDimensionInPixels: CGFloat) -> ImageRenderingOptions {
        return ImageRenderingOptions(createThumbnailFromImageAlways: true,
                                     createThumbnailFromImageIfAbsent: false,
                                     shouldAllowFloat: true,
                                     shouldCache: true,
                                     shouldCacheImmediately: true,
                                     thumbnailMaxPixelSize: maxDimensionInPixels,
                                     thumbnailWithTransform: true)

    }
}
