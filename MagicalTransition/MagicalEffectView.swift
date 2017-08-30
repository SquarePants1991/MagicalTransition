//
//  BrokenGlassEffectView.swift
//  BrokenGlassEffect
//
//  Created by wang yang on 2017/8/21.
//  Copyright © 2017年 ocean. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import UIKit
import GLKit

// 需要传递给Shader的全局变量
struct Uniforms {
    var animationElapsedTime: Float = 0.0
    var animationTotalTime: Float = 0.6
    var gatherPointX: Float = 0.8
    var gatherPointY: Float = -1.0
    var gatherPointZ: Float = 0.0
    
    func data() -> [Float] {
        return [animationElapsedTime, animationTotalTime, gatherPointX, gatherPointY, gatherPointZ];
    }
    
    static func sizeInBytes() -> Int {
        return 5 * MemoryLayout<Float>.size
    }
}

class MagicalEffectView: MetalBaseView {
    
    // 渲染
    var imageTexture: MTLTexture!
    var vertexArray: [Float]!
    var vertexBuffer: MTLBuffer!
    var uniforms: Uniforms!
    
    // 是否破碎
    var isBroking: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    func commonInit() {
        self.metalLayer.isOpaque = false
        self.metalLayer.contentsScale = UIScreen.main.scale
        self.backgroundColor = UIColor.clear
        setupRenderAssets()
        enableAniamtionTimer()
    }
    
    // 配置渲染相关资源
    func setupRenderAssets() {
        self.uniforms = Uniforms.init()
        
        // 构建顶点
        self.vertexArray = buildMesh()
        let vertexBufferSize = MemoryLayout<Float>.size * self.vertexArray.count
        self.vertexBuffer = device.makeBuffer(bytes: self.vertexArray, length: vertexBufferSize, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        
        self.imageTexture = nil;
    }
    
    func setImageForAnimation(image: UIImage) {
        self.imageTexture = createTexture(image: image)
    }
    
    // MARK: Metal View Basic Funcs
    // 更新逻辑
    override func update(deltaTime: TimeInterval, elapsedTime: TimeInterval) {
        uniforms.animationElapsedTime = Float(elapsedTime);
    }
    
    // 渲染
    override func draw(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(self.imageTexture, index: 0)
        
        let uniformBuffer = device.makeBuffer(bytes: self.uniforms.data(), length: Uniforms.sizeInBytes(), options: MTLResourceOptions.cpuCacheModeWriteCombined)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)

        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: self.vertexArray.count / 5)
    }
    
    // MARK: Private Methods
    private func buildMesh() -> [Float] {
        let viewWidth: Float = Float(UIScreen.main.bounds.width)
        let viewHeight: Float = Float(UIScreen.main.bounds.height)
        let meshCols: Int = 10;//Int(viewWidth / Float(meshUnitSizeInPixel.width));
        let meshRows: Int = meshCols * Int(viewHeight / viewWidth);//Int(viewHeight / Float(meshUnitSizeInPixel.height));
        let meshUnitSizeInPixel: CGSize = CGSize.init(width: CGFloat(viewWidth / Float(meshCols)), height: CGFloat(viewHeight / Float(meshRows))) // 每个mesh单元的大小

        let sizeXInMetalTexcoord = Float(meshUnitSizeInPixel.width) / viewWidth * 2;
        let sizeYInMetalTexcoord = Float(meshUnitSizeInPixel.height) / viewHeight * 2;
    
        var vertexDataArray: [Float] = []
        for row in 0..<meshRows {
            for col in 0..<meshCols {
                let startX = Float(col) * sizeXInMetalTexcoord - 1.0;
                let startY = Float(row) * sizeYInMetalTexcoord - 1.0;
                let point1: [Float] = [startX, startY, 0.0, Float(col) / Float(meshCols), Float(row) / Float(meshRows)];
                let point2: [Float] = [startX + sizeXInMetalTexcoord, startY, 0.0, Float(col + 1) / Float(meshCols), Float(row) / Float(meshRows)];
                let point3: [Float] = [startX + sizeXInMetalTexcoord, startY + sizeYInMetalTexcoord, 0.0, Float(col + 1) / Float(meshCols), Float(row + 1) / Float(meshRows)];
                let point4: [Float] = [startX, startY + sizeYInMetalTexcoord, 0.0, Float(col) / Float(meshCols), Float(row + 1) / Float(meshRows)];
                
                vertexDataArray.append(contentsOf: point3)
                vertexDataArray.append(contentsOf: point2)
                vertexDataArray.append(contentsOf: point1)
                
                vertexDataArray.append(contentsOf: point3)
                vertexDataArray.append(contentsOf: point1)
                vertexDataArray.append(contentsOf: point4)
            }
        }
        return vertexDataArray
    }
}
