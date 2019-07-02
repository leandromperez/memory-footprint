//
//  Incremental.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 7/1/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation
import ImageIO

enum IncrementalImageSourceError: Error {
    case fileNotFound
}

typealias Callback = (CGImage) -> Void
class IncrementalImageLoader {

    private let data : Data
    private let increment: Int
    private let updateInterval : TimeInterval
    private let dispatchQueue: DispatchQueue
    private let options : ImageSourceOptions

    private var callback : Callback?
    private var loadDataTimer : Timer?
    private var progress: Int = 0

    public init?(fileURL: URL,
                 options: ImageSourceOptions = .defaults,
                 timeInterval: TimeInterval = 0.1,
                 increment:Int = 500,
                 dispatchQueue:DispatchQueue = .global(qos: .userInitiated)) throws {
        assert(fileURL.isFileURL)
        self.dispatchQueue = dispatchQueue
        self.increment = increment
        self.updateInterval = timeInterval
        self.options = options
        self.data = try Data(contentsOf: fileURL)
    }

    func load(_ callback: @escaping (CGImage) -> Void) {
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
                guard let image = self.cgImage(at: self.progress) else { return }
                self.callback?(image)
            }
        }
    }

    private var cgImageSource : CGImageSource = CGImageSourceCreateIncremental([ : ] as CFDictionary)

    private func update(_ data: Data, isFinal: Bool) {
        CGImageSourceUpdateData(cgImageSource, data as CFData, isFinal)
    }

    private func cgImage(at index: Int = 0) -> CGImage? {
        return CGImageSourceCreateImageAtIndex(cgImageSource, index, options.dictionary)
    }
}


public struct ImageSourceOptions {
    public var shouldAllowFloat: Bool = false
    public var shouldCache: Bool = true
    public var createThumbnailFromImageIfAbsent: Bool = false
    public var createThumbnailFromImageAlways: Bool = false
    public var thumbnailMaxPixelSize: CGFloat? = 500

    public init() {}

    public var dictionary: CFDictionary {
        var options: [CFString:Any] = [:]
        options[kCGImageSourceShouldAllowFloat] = shouldAllowFloat
        options[kCGImageSourceShouldCache] = shouldCache
        options[kCGImageSourceCreateThumbnailFromImageIfAbsent] = createThumbnailFromImageIfAbsent
        options[kCGImageSourceCreateThumbnailFromImageAlways] = createThumbnailFromImageAlways

        if let thumbnailMaxPixelSize = thumbnailMaxPixelSize {
            options[kCGImageSourceThumbnailMaxPixelSize] = thumbnailMaxPixelSize
        }

        return options as CFDictionary
    }

    public static var defaults : ImageSourceOptions {
        return ImageSourceOptions()
    }
}
