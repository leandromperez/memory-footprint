//
//  Downsampling.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 6/29/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation
import UIKit

/// Creates a reduced to size and scale memory footprint image using core graphic buffers.
///
/// Use this to decrease memory usage when showing large images in smaller frames. Like in a collection view.
/// - Idea taken from https://developer.apple.com/videos/play/wwdc2018/219/
///
/// **How it works**
///
///     It uses core graphic to render the image using the desired size and scale, not caring about the original image size, that could potentially be quite large.
///     1. It creates a thumbnail object using the image data fetched from the given url.
///     2. It decodes immediately the image and place it in a buffer of the exact size received as parameter using the scale option too.
///     3. It creates a UIImage
///
/// - Parameters:
///
///     - imageData: it will be converted to CFData using UInt8 byte representation in an unsafe pointer
///     - frameSize: this is the size the resulting image will have if everythig goes well.
///     - scale: use this multiplier (0..1] to alter the content. 0.1 will result in a very pixelated image. 1 will result in the original image
///
/// - Return value: nil if something went wrong, or the UIImage if the downsampling was possible
public func downsample(imageData: Data, to frameSize: CGSize, scale: CGFloat) throws -> UIImage {
    try assertPreconditions(size: frameSize, scale: scale)

    //Tells CG to not go ahead and decode the image immediately. We will use this thumbnail object to fetch information from.
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

    return try imageData.withUnsafeBytes{ (unsafeRawBufferPointer: UnsafeRawBufferPointer) -> UIImage in
        let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
        guard let unsafePointer = unsafeBufferPointer.baseAddress else {throw DownsamplingError.unableToCreateData}

        let dataPtr = CFDataCreate(kCFAllocatorDefault, unsafePointer, imageData.count)
        guard let data = dataPtr else { throw DownsamplingError.unableToCreateData }
        guard let imageSource = CGImageSourceCreateWithData(data, imageSourceOptions) else { throw DownsamplingError.unableToCreateImageSource }

        return try createThumbnail(from: imageSource, size: frameSize, scale: scale)
    }
}

/// Creates a reduced to size and scale memory footprint image using core graphic buffers.
///
/// Use this to decrease memory usage when showing large images in smaller frames. Like in a collection view.
/// - Idea taken from https://developer.apple.com/videos/play/wwdc2018/219/
///
/// **How it works**
///
///     It uses core graphic to render the image using the desired size and scale, not caring about the original image size, that could potentially be quite large.
///     1. It creates a thumbnail object using the image data fetched from the given url.
///     2. It decodes immediately the image and place it in a buffer of the exact size received as parameter using the scale option too.
///     3. It creates a UIImage using
///
/// - Parameters:
///
///     - imageURL: the local disk url of the source image
///     - frameSize: this is the size the resulting image will have if everythig goes well.
///     - scale: use this multiplier (0..1] to alter the content. 0.1 will result in a very pixelated image. 1 will result in the original image
///
/// - Return value: throw an Error if something went wrong, or the UIImage if the downsampling was possible
public func downsample(imageAt imageURL: URL, to size: CGSize, scale: CGFloat) throws -> UIImage {
    assert(imageURL.isFileURL)
    try assertPreconditions(size: size, scale: scale)

    //Tells CG to not go ahead and decode the image immediately. We will use this thumbnail object to fetch information from.
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else { throw DownsamplingError.unableToCreateImageSource }

    return try createThumbnail(from: imageSource, size: size, scale: scale)
}

private func createThumbnail(from imageSource: CGImageSource, size: CGSize, scale:CGFloat) throws -> UIImage {
    let maxDimensionInPixels = max(size.width, size.height) * scale
    let options = [
        //kCGImageSourceShouldCacheImmediately is the most important option.
        //Tell CG that to decode the thumbnail it immediately.
        //At that exact moment, the decoded image buffer is created and the cpu hit for decoding is received.
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { throw DownsamplingError.unableToCreateThumbnail }
    return UIImage(cgImage: thumbnail)
}

private func assertPreconditions(size: CGSize, scale: CGFloat) throws {
    assert(scale > 0)
    guard scale > 0 else { throw DownsamplingError.invalidScale }

    assert(size.width > 0)
    assert(size.height > 0)
    guard size.height > 0, size.width > 0 else { throw DownsamplingError.invalidSize }
}

enum DownsamplingError : Error {
    case invalidScale
    case invalidSize
    case unableToCreateData
    case unableToCreateImageSource
    case unableToCreateThumbnail
}

extension DownsamplingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidScale : return "Scale must be in (0.. ?]"
        case .invalidSize: return "Height and Width must be greater than 0"
        case .unableToCreateData: return "Unable to create CF data from input data"
        case .unableToCreateThumbnail: return "Unable to create thumbnail   data from input data"
        case .unableToCreateImageSource: return "Unable to create image source using CGImageSourceCreateWithURL"
        }
    }
}
