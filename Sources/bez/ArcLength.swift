//
//  File.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import SwiftUI
import Accelerate
import simd 


// MARK: - Fast Arc Length

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
/// Returns that length of the Bézier elemnt
public func segmentLength(lastPoint: CGPoint, element: Path.Element) -> Double {
    switch element {
        
    case .move(_):
        return 0
    case .line(let to):
        return sqrt((to - lastPoint).magnitudeSquared)
    case .quadCurve(let to, let control):
        var tempTotal: Double = 0
        var tempLast: CGPoint = lastPoint
        for i in 1...20 {
            let new = quadraticBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control: control, end: to)
            tempTotal += sqrt((new-tempLast).magnitudeSquared)
            tempLast = new
        }
        return tempTotal
    case .curve(let to, let control1, let control2):
        var tempTotal: Double = 0
        var tempLast: CGPoint = lastPoint
        for i in 1...20 {
            let new = cubicBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control1: control1, control2: control2, end: to)
            tempTotal += sqrt((new-tempLast).magnitudeSquared)
            tempLast = new
        }
        return tempTotal
    case .closeSubpath:
        return 0
    }
}
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
/// Calculates the length of a `Path` using linear interpolation for speed. 
public func quickLengths(path: Path) -> [Double] {
    let elements = path.elements
    var lastPoint: CGPoint = .zero
    var startingPoint: CGPoint = .zero
    var segmentLengths: [Double] = []
    for element in elements {
        switch element {
            
        case .move(let to):
            startingPoint = to
            lastPoint = to
        case .line(let to):
            segmentLengths.append(sqrt((to - lastPoint).magnitudeSquared))
            lastPoint = to
        case .quadCurve(let to, let control):
            var tempTotal: Double = 0
            var tempLast: CGPoint = lastPoint
            for i in 1...20 {
                let new = quadraticBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control: control, end: to)
                tempTotal += sqrt((new-tempLast).magnitudeSquared)
                tempLast = new
            }
            segmentLengths.append(tempTotal)
            lastPoint = to
            
        case .curve(let to, let control1, let control2):
            var tempTotal: Double = 0
            var tempLast: CGPoint = lastPoint
            for i in 1...20 {
                let new = cubicBezierInterpolation(t: Float(i)/Float(20), start: lastPoint, control1: control1, control2: control2, end: to)
                tempTotal += sqrt((new-tempLast).magnitudeSquared)
                tempLast = new
            }
            segmentLengths.append(tempTotal)
            lastPoint = to
        case .closeSubpath:
            segmentLengths.append(sqrt((lastPoint - startingPoint).magnitudeSquared))
            lastPoint = startingPoint
        }
    }
    return segmentLengths
}

// MARK: - Accurate Arc Length

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
