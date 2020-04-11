//
//  Derivatives.swift
//  
//
//  Created by Kieran Brown on 3/21/20.
//

import CoreGraphics
import simd


/// # Derivative of Quadratic Bézier at t
/// Calculates the value of the derivative of the curve at the value `t`
///
/// `B(t) = -2(1-t)P₀ + 2(1-2t)P₁ + 2tP₂ `
/// `           =    a     +     b     +   c `
///
/// - parameters:
///     - t: parametric variable of some value on [0,1]
///     - start: The starting location of the curve
///     - control: The control point of the curve
///     - endPoint: The ending location of the curve
public func quadBezierDerivative(t: Float, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
    let p0 = simd_float2(x: Float(start.x), y: Float(start.y))
    let p1 = simd_float2(x: Float(control.x), y: Float(control.y))
    let p2 = simd_float2(x: Float(end.x), y: Float(end.y))
    let a = -2*(1-t)*p0
    let b = 2*(1-2*t)*p1
    let c = 2*t*p2
    
    let point = a + b + c
    
    return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
    
}


/// # Derivative Of Cubic Bézier at t
///
///  Calculates the value of the derivative of the curve at the value `t`
///
///     `B'(t) = -3(1-t)²P₀ + 3(1-t)(1-3t)P₁ + 3t(2-3t)P₂ + 3t²P₃`
///     `             =    a     +         b        +     c      +  d`
///
/// - parameters:
///     - t: parametric variable of some value on [0,1]
///     - start: The starting location of the curve
///     - control1: The first control point of the curve
///     - control2: The second control point of the curve
///     - endPoint: The ending location of the curve
public func cubicBezierDerivative(t: Float, start: CGPoint, control1: CGPoint, control2: CGPoint , end: CGPoint) -> CGPoint {
    let p0 = simd_float2(x: Float(start.x), y: Float(start.y))
    let p1 = simd_float2(x: Float(control1.x), y: Float(control1.y))
    let p2 = simd_float2(x: Float(control2.x), y: Float(control2.y))
    let p3 = simd_float2(x: Float(end.x), y: Float(end.y))
    
    let a = -3*(1-t)*(1-t)*p0
    let b = 3*(1-t)*(1-3*t)*p1
    let c = 3*t*(2-3*t)*p2
    let d = 3*t*t*p3
    
    let point = a + b + c + d
    
    return CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
}

