//
//  UIImage + rendering.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 7/3/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    static func rendered(from url: NSURL, size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        return try UIGraphicsRenderer.renderImageAt(url: url, size: size, scale: scale)
    }

    static func rendered(fromMultiple urls: [NSURL], size: CGSize, scale: CGFloat = 1) throws -> UIImage {
        return try UIGraphicsRenderer.renderImagesAt(urls: urls, size: size, scale: scale)
    }
}
