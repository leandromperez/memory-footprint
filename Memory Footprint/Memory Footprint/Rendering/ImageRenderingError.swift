//
//  ImageRenderingError.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 7/3/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation

public enum ImageRenderingError : Error {
    case fileNotFound
    case unableToGetDataProvider
    case unableToCreateCGImage
    case unableToCreateImageSource
    case unableToCreateThumbnail
}
