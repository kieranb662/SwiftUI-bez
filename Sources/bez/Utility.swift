import CoreGraphics
import simd


extension CGPoint {
    func tosimd() -> simd_float2 {
        simd_float2(Float(x), Float(y))
    }
    
    
}

extension CGPoint: CustomStringConvertible {
    public var description: String {
        let sx = String(format: "%.0f", Double(x))
        let sy = String(format: "%.0f", Double(y))
        
       return sx + " " + sy
    }
}
