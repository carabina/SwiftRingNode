import UIKit

protocol SwiftRingNodeDelegate {
    func didTapSwiftRingNode(_ swiftRingNode: SwiftRingNode)
}

@IBDesignable
class SwiftRingNode: UIView {
    
    var delegate: SwiftRingNodeDelegate? = nil
    var firstDraw: Bool = true // first draw is for storyboard display, subsequent draws involve animation
    var tapGestureSetup: Bool = false
    var ringShapeLayer: CAShapeLayer? = nil
    
    @IBInspectable var title: String = "Title"
    @IBInspectable var titleColor: UIColor = UIColor.white
    @IBInspectable var titleFontName: String = UIFont.systemFont(ofSize: 0).fontName
    @IBInspectable var titleFontSize: CGFloat = 10
    @IBInspectable var titleNumberOfLines: Int = 0
    @IBInspectable var nodeColor: UIColor = UIColor.green
    @IBInspectable var ringProgress: Double = 75
    @IBInspectable var ringColor: UIColor = UIColor.blue
    @IBInspectable var ringThickness: CGFloat = 10
    @IBInspectable var ringAnimationSpeed: CGFloat = 1
    
    // ----------------------------------------------------------------------------------------------------
    // MARK: View Methods
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        setupTapGestureRecognizer()
    }
    
    override func draw(_ rect: CGRect) {
        self.drawNode(inRect: rect)
        self.drawRing(inRect: rect)
    }
    
    // ----------------------------------------------------------------------------------------------------
    // MARK: Gesture Methods
    
    func setupTapGestureRecognizer() {
        if tapGestureSetup == false {
            let tapFrame = getSquare(centeredInRect: self.bounds, withMargin: 0)
            let tapView = UIView(frame: tapFrame)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapRingNode(_:)))
            tapView.addGestureRecognizer(tapGesture)
            self.addSubview(tapView)
            self.tapGestureSetup = true
        }
    }
    
    @objc func didTapRingNode(_ sender: UITapGestureRecognizer) {
        if let delegate = delegate {
            delegate.didTapSwiftRingNode(self)
        }
    }
    
    // ----------------------------------------------------------------------------------------------------
    // MARK: Draw Node Methods
    
    func drawNode(inRect rect: CGRect) {
        let nodeCenterBounds = getSquare(centeredInRect: rect, withMargin: ringThickness / 2)
        let titleLabelFrame = getSquare(centeredInRect: rect, withMargin: ringThickness * 1.25)
        drawNodeCenter(inSquare: nodeCenterBounds)
        drawNodeTitle(withFrame: titleLabelFrame)
    }
    
    func drawNodeCenter(inSquare square: CGRect) {
        let path = UIBezierPath(ovalIn: square)
        nodeColor.setFill()
        path.fill()
    }
    
    func drawNodeTitle(withFrame frame: CGRect) {
        let label = UILabel(frame: frame)
        label.text = title
        label.textColor = titleColor
        label.font = UIFont(name: titleFontName, size: titleFontSize)
        label.numberOfLines = titleNumberOfLines
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        self.addSubview(label)
    }
    
    // ----------------------------------------------------------------------------------------------------
    // MARK: Draw Ring Methods
    
    func drawRing(inRect rect: CGRect) {
        let ringBounds = getSquare(centeredInRect: rect, withMargin: 0)
        drawRing(inSquare: ringBounds)
    }
    
    func drawRing(inSquare square: CGRect) {
        if firstDraw {
            drawRingDummy(inSquare: square)
            firstDraw = false
        } else {
            drawRingActual(inSquare: square)
        }
    }
    
    func drawRingDummy(inSquare square: CGRect) { // for storyboard
        let path = getRingPath(inSquare: square)
        path.lineWidth = ringThickness
        ringColor.setStroke()
        path.stroke()
    }
    
    func drawRingActual(inSquare square: CGRect) {
        let path = getRingPath(inSquare: square)
        let animations = getRingAnimations()
        let layer = getRingLayer(forPath: path.cgPath, withAnimations: animations)
        displayRing(layer)
    }
    
    func getRingPath(inSquare square: CGRect) -> UIBezierPath {
        let center = getCenter(ofRect: square)
        let radius: CGFloat = max(square.width, square.height)
        let startAngle: CGFloat = .pi / 2
        let endAngle: CGFloat = startAngle + 2 * .pi * CGFloat(ringProgress) / 100
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius/2 - ringThickness/2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        return path
    }
    
    func getRingAnimations() -> CAAnimationGroup {
        
        let pathStartPointAnimation = CABasicAnimation(keyPath: "strokeStart")
        pathStartPointAnimation.fromValue = 0
        pathStartPointAnimation.toValue = 0
        pathStartPointAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let pathEndPointAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathEndPointAnimation.fromValue = 0
        pathEndPointAnimation.toValue = 1.0
        pathEndPointAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let animation = CAAnimationGroup()
        animation.animations = [pathStartPointAnimation, pathEndPointAnimation]
        animation.duration = 1 * ringProgress / 100 * Double(ringAnimationSpeed) // 1 sec for full ring animation
        return animation
    }
    
    func getRingLayer(forPath path: CGPath, withAnimations animations: CAAnimationGroup?) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.path = path
        layer.backgroundColor = UIColor.clear.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = ringColor.cgColor
        layer.lineWidth = ringThickness
        if let animations = animations {
            layer.add(animations, forKey: "RingAnimation")
        }
        return layer
    }
    
    func displayRing(_ layer: CAShapeLayer) {
        if let existingLayer = ringShapeLayer {
            existingLayer.removeFromSuperlayer()
        }
        self.ringShapeLayer = layer
        self.layer.addSublayer(layer)
    }
    
    // ----------------------------------------------------------------------------------------------------
    // MARK: Helper Methods
    
    func getSquare(centeredInRect rect: CGRect, withMargin margin: CGFloat) -> CGRect {
        let minDim: CGFloat = min(rect.width, rect.height)
        let side: CGFloat = minDim - margin * 2
        let center: CGPoint = getCenter(ofRect: rect)
        let originX: CGFloat = center.x - side / 2
        let originY: CGFloat = center.y - side / 2
        let origin: CGPoint = CGPoint(x: originX, y: originY)
        let size: CGSize = CGSize(width: side, height: side)
        return CGRect(origin: origin, size: size)
    }
    
    func getCenter(ofRect rect: CGRect) -> CGPoint {
        let centerX: CGFloat = (rect.maxX - rect.minX) / 2 + rect.minX
        let centerY: CGFloat = (rect.maxY - rect.minY) / 2 + rect.minY
        return CGPoint(x: centerX, y: centerY)
    }
    
}