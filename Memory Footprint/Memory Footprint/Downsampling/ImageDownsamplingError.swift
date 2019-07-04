//
//  ImageDownsamplingError.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 7/3/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import Foundation

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
