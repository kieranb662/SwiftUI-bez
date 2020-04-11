//
//  Interpolation.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import CoreGraphics
import simd 



/// # Linear Interpolation
///
/// Calculates and returns the point at the value `t` on the line defined by the start and end points
///
/// - parameters:
///     - t: parametric variable of some value on [0,1]
///     - start: The starting location of the line
///     - end: The ending location of the line
public func linearInterpolation(t: Float, start: CGPoint, end: CGPoint) -> CGPoint {
    let p0 = start.tosimd()
    let p1 = end.tosimd()
    let point = mix(p0, p1, t: t)
    return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
}



/// # Quadratic Bézier Interpolation
///
/// Calculates and returns  the point at the value `t` on the quadratic Bézier curve
/// `B(t) = (1-t)²P₀ + 2t(1-t)P₁ + t²P₂ `
/// `           =    a     +     b     +   c `
///
/// - parameters:
///     - t: parametric variable of some value on [0,1]
///     - start: The starting location of the curve
///     - control: The control point of the curve
///     - endPoint: The ending location of the curve
public func quadraticBezierInterpolation(t: Float, start: CGPoint, control: CGPoint , end: CGPoint) -> CGPoint {
    let p0 = start.tosimd()
    let p1 = control.tosimd()
    let p2 = end.tosimd()

    // Splitting up the expression for the quadratic Bézier curve to keep in a human readable form
    let a = (1-t)*(1-t)*p0
    let b = 2*(1-t)*t*p1
    let c = t*t*p2
    
    let point = a + b + c
    
    return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
}




/// # Cubic Bézier Interpolation
///
/// Calculates and returns the point at the value `t` on the cubic Bézier curve.
///  `B(t) = (1-t)³P₀ + 3t(1-t)²P₁ + 3t²(1-t)P₂ + t³P₃`
///  `           =    a     +     b      +     c      +  d`
///
/// - parameters:
///     - t: parametric variable of some value on [0,1]
///     - start: The starting location of the curve
///     - control1: The first control point of the curve
///     - control2: The second control point of the curve
///     - endPoint: The ending location of the curve
public func cubicBezierInterpolation(t: Float, start: CGPoint, control1: CGPoint, control2: CGPoint , end: CGPoint) -> CGPoint {
    
    let p0 = start.tosimd()
    let p1 = control1.tosimd()
    let p2 = control2.tosimd()
    let p3 = end.tosimd()
    
    // Splitting up the expression for the cubic Bézier curve to keep in a human readable form
    let a = powf((1-t), 3)*p0
    let b = 3*(1-t)*(1-t)*t*p1
    let c = 3*(1-t)*t*t*p2
    let d = powf(t, 3)*p3
    
    let point = a + b + c + d
    
    return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
}

