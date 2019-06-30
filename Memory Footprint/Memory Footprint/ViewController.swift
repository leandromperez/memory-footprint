//
//  ViewController.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 6/29/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import UIKit

enum ImageAlternative {
    case regular
    case lossy
    case downsample
    case uiGraphicsRenderer
}

class ViewController: UIViewController {

    @IBOutlet var containerView: UIView!
    @IBOutlet var memoryConsumptionLabel: UILabel!
    @IBOutlet var alternativeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshConsumedMemory()
    }

    @IBAction func clearAll() {

        for child in children {
            child.willMove(toParent: nil)
            child.removeFromParent()
            child.view.removeFromSuperview()
        }
    }

    @IBAction func loadRegular() {
        self.load(.regular)
    }

    @IBAction func loadLossy() {
        self.load(.lossy)
    }

    @IBAction func loadDownsampledImage() {
        self.load(.downsample)
    }

    @IBAction func loadUIGraphicsRenderer() {
        self.load(.uiGraphicsRenderer)
    }

    private func refreshConsumedMemory() {
        memoryConsumptionLabel.text = memoryInMB().map{ "Using \($0) MB"} ?? "Unable to calculate MB"
    }

    private func load(_ alternative: ImageAlternative) {
        switch alternative {
        case .regular:
            self.show(image: UIImage(named: "regular-catedral")!)
        case .lossy:
            self.show(image: UIImage(named: "lossy-catedral")!)
        case .downsample:
            self.show(try downsampledImage(), errorMessage: "Unable to downsample image")
        case .uiGraphicsRenderer:
            self.show(try renderedImage(), errorMessage: "Unable to render image")
        }

        refreshConsumedMemory()
    }

    private func show(_ generator : @autoclosure () throws -> UIImage, errorMessage: String) {
        do {
            let image = try generator()
            self.show(image: image)
        }
        catch let error {
            print ("🐍 error: \n \(error)")
            alternativeLabel.text = error.localizedDescription
        }
    }

    private func show(image:UIImage) {
        clearAll()

        let imageView = UIImageView()
        imageView.image = image

        let presented = UIViewController()
        presented.view.addSubview(imageView)
        let frame = CGRect.init(x: 0, y: 0, width: containerSize.width, height: containerSize.height)
        presented.view.frame = frame
        imageView.frame = frame

        containerView.addSubview(presented.view)

        self.addChild(presented)
        presented.didMove(toParent: self)
        
    }

    //https://stackoverflow.com/questions/27556807/swift-pointer-problems-with-mach-task-basic-info
    private func memoryInMB() -> mach_vm_size_t? {
        var info = mach_task_basic_info()
        let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size / 1024 / 1024
        } else {
            return nil
        }
    }

    private var containerSize: CGSize {
        return self.containerView.frame.size
    }

    private var catedralUrl : URL {
        guard let imagePath = Bundle.main.path(forResource: "catedral", ofType: "jpg") else {fatalError()}
        let imageUrl = URL(fileURLWithPath: imagePath)
        return imageUrl
    }

    private func downsampledImage() throws -> UIImage {
        return try downsample(imageAt: catedralUrl, to: containerSize, scale: 4)
    }

    private func renderedImage() throws -> UIImage {
        return try UIGraphicsRenderer.renderImageAt(url: catedralUrl as NSURL, size: containerSize)
    }

}

