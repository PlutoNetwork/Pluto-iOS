/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import QuartzCore

open class AnimatedULogoView: UIView {
 
  fileprivate let strokeEndTimingFunction   = CAMediaTimingFunction(controlPoints: 1.00, 0.0, 0.35, 1.0)
  fileprivate let circleLayerTimingFunction   = CAMediaTimingFunction(controlPoints: 0.65, 0.0, 0.40, 1.0)
  
  fileprivate let radius: CGFloat = 23.5
  fileprivate let startTimeOffset = 0.7 * kAnimationDuration
  
  fileprivate var circleLayer: CAShapeLayer!
  
  var beginTime: CFTimeInterval = 0
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    circleLayer = generateCircleLayer()
    
    layer.addSublayer(circleLayer)
  }
  
  open func startAnimating() {
    beginTime = CACurrentMediaTime()
    
    layer.anchorPoint = CGPoint.zero
    
    animateCircleLayer()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

extension AnimatedULogoView {
  
  fileprivate func generateCircleLayer() -> CAShapeLayer {
    
    let layer = CAShapeLayer()
    layer.lineWidth = radius
    layer.path = UIBezierPath(arcCenter: CGPoint.zero, radius: radius/2, startAngle: -CGFloat(M_PI_2), endAngle: CGFloat(3*M_PI_2), clockwise: true).cgPath
    layer.strokeColor = UIColor.white.cgColor
    layer.fillColor = UIColor.clear.cgColor
    return layer
  }
}

extension AnimatedULogoView {

  fileprivate func animateCircleLayer() {
    
    // strokeEnd
    let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
    strokeEndAnimation.timingFunction = strokeEndTimingFunction
    strokeEndAnimation.duration = kAnimationDuration - kAnimationDurationDelay
    strokeEndAnimation.values = [0.0, 1.0]
    strokeEndAnimation.keyTimes = [0.0, 1.0]
    
    // transform
    let transformAnimation = CABasicAnimation(keyPath: "transform")
    transformAnimation.timingFunction = strokeEndTimingFunction
    transformAnimation.duration = kAnimationDuration - kAnimationDurationDelay
    
    var startingTransform = CATransform3DMakeRotation(-CGFloat(M_PI_4), 0, 0, 1)
    startingTransform = CATransform3DScale(startingTransform, 0.25, 0.25, 1)
    transformAnimation.fromValue = NSValue(caTransform3D: startingTransform)
    transformAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
    
    // Group
    let groupAnimation = CAAnimationGroup()
    groupAnimation.animations = [strokeEndAnimation, transformAnimation]
    groupAnimation.repeatCount = Float.infinity
    groupAnimation.duration = kAnimationDuration
    groupAnimation.beginTime = beginTime
    groupAnimation.timeOffset = startTimeOffset
    
    circleLayer.add(groupAnimation, forKey: "looping")
  }
}
