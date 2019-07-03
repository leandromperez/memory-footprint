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

public enum RenderingError : Error {
    case fileNotFound
    case unableToGetDataProvider
    case unableToCreateCGImage
    case unableToCreateImageSource
    case unableToCreateThumbnail
}

public protocol ImageRenderingSource {
    var cgSource: CGImageSource {get}
}

extension CGImageSource : ImageRenderingSource {
    public var cgSource: CGImageSource {
        return self
    }
}

public class RenderingSource : ImageRenderingSource {
    public var cgSource: CGImageSource
    public init(cgSource: CGImageSource) {
        self.cgSource = cgSource
    }
}
extension ImageRenderingSource {
    static func url(_ url: NSURL) throws -> ImageRenderingSource {
        guard let source = CGImageSourceCreateWithURL(url, nil) else { throw RenderingError.unableToCreateImageSource }
        return source
    }
}

public class IncrementalRenderingSource: RenderingSource {
    private let data : Data
    private let increment: Int
    private let updateInterval : TimeInterval
    private let dispatchQueue: DispatchQueue

    private var callback : ((IncrementalRenderingSource) -> Void)?
    private var loadDataTimer : Timer?
    var progress: Int = 0

    public init?(fileURL: URL,
                 timeInterval: TimeInterval = 0.1,
                 increment:Int = 500,
                 dispatchQueue:DispatchQueue = .global(qos: .userInitiated)) throws {
        assert(fileURL.isFileURL)
        self.dispatchQueue = dispatchQueue
        self.increment = increment
        self.updateInterval = timeInterval
        self.data = try Data(contentsOf: fileURL)
        super.init(cgSource:CGImageSourceCreateIncremental(nil))
    }

    func load(_ callback: @escaping (IncrementalRenderingSource) -> Void) {
        self.callback = callback
        loadDataTimer = Timer.scheduledTimer(timeInterval: updateInterval,
                                             target: self,
                                             selector: #selector(loadMoreData),
                                             userInfo: nil,
                                             repeats: true)
    }

    func stopLoading() {
        loadDataTimer?.invalidate()
        loadDataTimer = nil
        callback = nil
    }

    @objc private func loadMoreData() {
        dispatchQueue.async {
            self.progress += self.increment
            let chunk = self.data.prefix(self.progress)

            let isFinal = chunk.count == self.data.count
            if isFinal {
                self.stopLoading()
            }

            self.update(Data(chunk), isFinal: isFinal)

            DispatchQueue.main.async {
                self.callback?(self)
            }
        }
    }

    private var cgImageSource : CGImageSource = CGImageSourceCreateIncremental([ : ] as CFDictionary)

    private func update(_ data: Data, isFinal: Bool) {
        CGImageSourceUpdateData(cgImageSource, data as CFData, isFinal)
    }
}



public struct ImageRenderingOptions {
    public let createThumbnailFromImageAlways : Bool = true
    public let shouldAllowFloat: Bool = false
    public let shouldCache: Bool = true
    public let createThumbnailFromImageIfAbsent: Bool = false

    public init() {}

    var cgOptions: [NSString: Any] {
        return [
            kCGImageSourceShouldAllowFloat : shouldAllowFloat,
            kCGImageSourceShouldCache : shouldCache,
            kCGImageSourceCreateThumbnailFromImageIfAbsent : createThumbnailFromImageIfAbsent,
            kCGImageSourceCreateThumbnailFromImageAlways : createThumbnailFromImageAlways
        ]
    }

    public static var defaults : ImageRenderingOptions {
        return ImageRenderingOptions()
    }
}

public extension UIGraphicsRenderer {
    static func renderImageAt(url: NSURL, size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        return try renderImagesAt(urls: [url], size: size, scale: scale)
    }

    static func renderImagesAt(urls: [NSURL], size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        return try renderImage(size: size, sources: urls.map(RenderingSource.url), options: .defaults)
    }

    static func renderImageIncrementally(size: CGSize,
                                         scale: CGFloat = 1,
                                         fileURL: URL,
                                         options: ImageRenderingOptions = .defaults,
                                         timeInterval: TimeInterval = 0.1,
                                         increment:Int = 500,
                                         dispatchQueue:DispatchQueue = .global(qos: .userInitiated),
                                         callback: @escaping (UIImage) -> Void) throws -> IncrementalRenderingSource {

        guard let source = try IncrementalRenderingSource(fileURL: fileURL,
                                                          timeInterval: timeInterval,
                                                          increment: increment,
                                                          dispatchQueue: dispatchQueue) else {throw RenderingError.unableToCreateImageSource}

        renderImageIncrementally(size: size, scale: scale,
                                 source: source,
                                 options: options,
                                 callback: callback)

        return source
    }

    static func renderImageIncrementally(size: CGSize,
                                         scale: CGFloat = 1,
                                         source: IncrementalRenderingSource,
                                         options: ImageRenderingOptions,
                                         callback: @escaping (UIImage) -> Void) {
        source.load { source in
            guard let image = try? renderImage(size: size, sources: [source], options: options) else {return}
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
                throw RenderingError.unableToCreateThumbnail
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


