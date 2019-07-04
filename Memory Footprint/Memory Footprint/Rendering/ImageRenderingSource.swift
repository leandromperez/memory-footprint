//
//  ImageRenderingSource.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 7/3/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation
import ImageIO

public protocol ImageRenderingSource {
    var cgSource: CGImageSource {get}
}

extension ImageRenderingSource {
    static func url(_ url: NSURL) throws -> ImageRenderingSource {
        guard let source = CGImageSourceCreateWithURL(url, nil) else { throw ImageRenderingError.unableToCreateImageSource }
        return source
    }
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
