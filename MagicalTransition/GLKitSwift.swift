//
//  GLKitSwift.swift
//  BrokenGlassEffect
//
//  Created by wang yang on 2017/8/21.
//  Copyright © 2017年 ocean. All rights reserved.
//

import Foundation

import GLKit

extension GLKMatrix4 {
    var raw: [Float] {
        return (0..<16).map { i in self[i] }
    }
    
    func toFloat4x4() -> matrix_float4x4    {
        return matrix_float4x4.init(
            float4.init([m00,m01,m02,m03]),
            float4.init([m10,m11,m12,m13]),
            float4.init([m20,m21,m22,m23]),
            float4.init([m30,m31,m32,m33])
        )
    }
    
    static func fromFloat4x4(_ float4x4: matrix_float4x4) -> GLKMatrix4 {
        return GLKMatrix4MakeWithColumns(
            GLKVector4Make(float4x4.columns.0.x, float4x4.columns.0.y, float4x4.columns.0.z, float4x4.columns.0.w),
            GLKVector4Make(float4x4.columns.1.x, float4x4.columns.1.y, float4x4.columns.1.z, float4x4.columns.1.w),
            GLKVector4Make(float4x4.columns.2.x, float4x4.columns.2.y, float4x4.columns.2.z, float4x4.columns.2.w),
            GLKVector4Make(float4x4.columns.3.x, float4x4.columns.3.y, float4x4.columns.3.z, float4x4.columns.3.w))
    }
}
