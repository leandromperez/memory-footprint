//
//  ViewController.swift
//  Memory Footprint
//
//  Created by Leandro Perez on 6/29/19.
//  Copyright © 2019 Leandro Perez. All rights reserved.
//

import UIKit

enum LoadingAlternative : String, CaseIterable {
    case displayP3
    case sRGB
    case downsample
    case uiGraphicsRenderer
    case incremental
}

class ViewController: UIViewController {

    @IBOutlet var containerView: UIView!
    @IBOutlet var alternativeLabel: UILabel!
    @IBOutlet var stackView : UIStackView!

    private var targetProxies:  [ButtonTargetProxy] = []

//    override func viewDidLoad() {
//        super.viewDidLoad()
//        for alternative in LoadingAlternative.allCases {
//            let button = UIButton()
//            let proxy = button.addTarget(for: .touchUpInside) { [unowned self] _ in self.load(alternative) }
//            targetProxies.append(proxy)
//            button.titleLabel?.text = alternative.rawValue
//            button.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
//            stackView.addSubview(button)
//        }
//        self.view.setNeedsLayout()
//        self.view.layoutSubviews()
//    }

    @IBAction func clearAll() {
        for child in children {
            child.willMove(toParent: nil)
            child.removeFromParent()
            child.view.removeFromSuperview()
        }
        loader?.stopLoading()
        loader = nil
        alternativeLabel.text = nil
    }

    @IBAction func loadIncremental() {
        self.load(.incremental)
    }

    @IBAction func loadDisplayP3() {
        self.load(.displayP3)
    }

    @IBAction func loadRGB() {
        self.load(.sRGB)
    }

    @IBAction func loadDownsampledImage() {
        self.load(.downsample)
    }

    @IBAction func loadUIGraphicsRenderer() {
        self.load(.uiGraphicsRenderer)
    }

    private func load(_ alternative: LoadingAlternative) {
        switch alternative {
        case .displayP3:
            self.show(image: UIImage(named: alternative.rawValue)!)
        case .sRGB:
            self.show(image: UIImage(named: alternative.rawValue)!)
        case .downsample:
            self.show(try downsampledImage(), errorMessage: "Unable to downsample image")
        case .uiGraphicsRenderer:
            self.show(try renderedImage(), errorMessage: "Unable to render image")
        case .incremental:
            self.loadIncrementally()
        }
        self.alternativeLabel.text = "Loaded: \(alternative.rawValue)"
    }


    private var loader : IncrementalImageLoader?
    private func loadIncrementally() {
        loader?.stopLoading()
        loader = try? IncrementalImageLoader(fileURL: catedralUrl)
        loader?.load{ [unowned self] cgImage in
            self.show(image: UIImage(cgImage: cgImage))
        }
    }

    private func show(_ generator : @autoclosure () throws -> UIImage, errorMessage: String) {
        do {
            let image = try generator()
            self.show(image: image)
        }
        catch let error {
            alternativeLabel.text = error.localizedDescription
        }
    }

    private func show(image:UIImage) {
        self.clearAll()

        let imageView = UIImageView()
        imageView.image = image

        let presented = UIViewController()
        presented.view.addSubview(imageView)
        let frame = CGRect.init(x: 0, y: 0, width: containerSize.width, height: containerSize.height)
        presented.view.frame = frame
        imageView.frame = frame

        self.containerView.addSubview(presented.view)

        self.addChild(presented)
        presented.didMove(toParent: self)
        
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
        return try downsample(imageAt: catedralUrl, to: containerSize, scale: 1)
    }

    private func renderedImage() throws -> UIImage {
        return try UIGraphicsRenderer.renderImageAt(url: catedralUrl as NSURL, size: containerSize, scale: 1)
    }

}


public class ButtonTargetProxy {
    var closure: (AnyObject) -> Void
    public init(closure: @escaping (AnyObject) -> Void) {
        self.closure = closure
    }
    @objc func execute(sender: AnyObject) {
        closure(sender)
    }
}

extension UIButton {
    func addTarget(for event: UIControl.Event, closure: @escaping (AnyObject) -> Void ) -> ButtonTargetProxy {
        let proxy = ButtonTargetProxy(closure: closure)
        self.addTarget(proxy, action: #selector(ButtonTargetProxy.execute(sender:)), for: event)
        return proxy
    }
}
