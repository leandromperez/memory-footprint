//
//  ImageRenderingIncrementalSource.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 7/3/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation
import ImageIO

public class ImageRenderingIncrementalSource: RenderingSource {
    private let data : Data
    private let increment: Int
    private let updateInterval : TimeInterval
    private let dispatchQueue: DispatchQueue

    private var callback : ((ImageRenderingIncrementalSource) -> Void)?
    private var loadDataTimer : Timer?
    private var progress: Int = 0

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

    func load(_ callback: @escaping (ImageRenderingIncrementalSource) -> Void) {
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

            self.cgSource.update(data: Data(chunk), isFinal: isFinal)

            DispatchQueue.main.async {
                self.callback?(self)
            }
        }
    }
}

extension CGImageSource {
    func update(data: Data, isFinal: Bool) {
        CGImageSourceUpdateData(self, data as CFData, isFinal)
    }
}

