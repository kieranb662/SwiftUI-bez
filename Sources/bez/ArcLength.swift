//
//  File.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import CoreGraphics
import Accelerate
import simd 


// MARK: Arc Length



/// # Calculate Arc Length Of Quadratic Bézier Curve
///
///    Numerically integrate the arc length of the quadratic bézier segment between `from` and `to`
///    Their is infact a closed form solution for this type of curve. Good luck typing it in without fucking it up .
///
/// - parameters:
///     - start: The starting location of the curve
///     - control: The control point of the curve
///     - endPoint: The ending location of the curve
///     - from: The lower bound of the segment. Should be between `[0, 1)` .
///     - to: The upper bound of the segment . Should be between `(0, 1]`.
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func quadBezierLength(start: CGPoint, control: CGPoint , end: CGPoint, from: Float, to: Float) -> Double? {
    let quadrature = Quadrature(integrator: .qags(maxIntervals: 10),
                                absoluteTolerance: 1.0e-8,
                                relativeTolerance: 1.0e-2)
    let range: ClosedRange<Double> = Double(from)...Double(to)
    
    let result = quadrature.integrate(over: range) { (x) in
        sqrt(quadBezierDerivative(t: Float(x), start: start, control: control, end: end).magnitudeSquared)
    }
    
    switch result {
    case .success(let integralResult, let estimatedAbsoluteError):
        print("quadrature success:", integralResult,
              estimatedAbsoluteError)
        return integralResult
    case .failure(let error):
        print("quadrature error:", error.errorDescription)
        return nil
    }
    
}



/// # Calculate Arc Length of Cubic Bézier Curve
///
///  Uses the `Quadrature` framework to calculate the approximate arc length of the cubic Bézier curve
///  Because this is a parametric curve the arclength calculated by taking the derivative of the curve with
///  respect to the parameter `t`,  and then integrating the length of the derivate.`∫ √([dx]² + [dy]²)dt`.
///  Try your hardest and you will never find a closed form solution for this specific integral. You could potentially
///  make use of elliptic integral functions specifically tailored to this case but using quadrature is fine.
///
/// - parameters:
///     - start: The starting point for the Bézier curve
///     - end: The end point of the cubic Bézier
///     - control1: The first control point of the cubic bézier
///     - control2: The second control point of the cubic bézier
///     - from: The lower bound of the segment. Should be between `[0, 1)` .
///     - to: The upper bound of the segment . Should be between `(0, 1]`.
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public func cubicBezierLength(start: CGPoint, control1: CGPoint, control2: CGPoint , end: CGPoint, from: Float, to: Float) -> Double? {
    let quadrature = Quadrature(integrator: .qags(maxIntervals: 10),
                                absoluteTolerance: 1.0e-8,
                                relativeTolerance: 1.0e-2)
    let range: ClosedRange<Double> = Double(from)...Double(to)
    
    let result = quadrature.integrate(over: range) { (x) in
        sqrt(cubicBezierDerivative(t: Float(x), start: start, control1: control1, control2: control2, end: end).magnitudeSquared)
    }
    
    switch result {
    case .success(let integralResult, let estimatedAbsoluteError):
        print("quadrature success:", integralResult,
              estimatedAbsoluteError)
        return integralResult
    case .failure(let error):
        print("quadrature error:", error.errorDescription)
        return nil
    }
    
}
