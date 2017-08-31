//
//  MetalBaseView.swift
//  BrokenGlassEffect
//
//  Created by wang yang on 2017/8/21.
//  Copyright © 2017年 ocean. All rights reserved.
//

import Foundation
import UIKit
import Metal
import MetalKit

class MetalBaseView: UIView {
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var pipelineStateDescriptor: MTLRenderPipelineDescriptor! = nil;
    
    var metalLayer: CAMetalLayer!
    
    private var displayLink: CADisplayLink!
    private var lastTickedTime: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initMetal()
        initPipline()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initMetal()
        initPipline()
    }
    
    deinit {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.metalLayer.frame = self.layer.bounds
    }
    
    // MARK: 辅助方法
    func createTexture(image: UIImage) -> MTLTexture? {
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let width:Int = Int(image.size.width)
        let height:Int = Int(image.size.height)
        let imageData = UnsafeMutableRawPointer.allocate(bytes: Int(width * height * bytesPerPixel), alignedTo: 8)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let imageContext = CGContext.init(data: imageData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: width * bytesPerPixel, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue )
        UIGraphicsPushContext(imageContext!)
        imageContext?.translateBy(x: 0, y: CGFloat(height))
        imageContext?.scaleBy(x: 1, y: -1)
        image.draw(in: CGRect.init(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        let texture = device.makeTexture(descriptor: descriptor)
        texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: imageData, bytesPerRow: width * bytesPerPixel)
        return texture
    }
    
    // 子类中覆盖这个方法实现绘制
    func draw(renderEncoder: MTLRenderCommandEncoder) {
       
    }
    
    // MARK: Metal相关方法
    func initMetal() {
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            return
        }
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = self.bounds
        self.layer.addSublayer(metalLayer)
    }
    
    func initPipline() {
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main metal command queue"
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "passThroughFragment")!
        let vertexProgram = defaultLibrary.makeFunction(name: "passThroughVertex")!
        
        self.pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    func render() {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor.init()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0);
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer.label = "Frame command buffer"
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.label = "render encoder"
        renderEncoder.pushDebugGroup("begin draw")
        renderEncoder.setRenderPipelineState(pipelineState)
        
        self.draw(renderEncoder: renderEncoder)
        
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: 刷新相关
    func enableAniamtionTimer() {
        if self.displayLink == nil {
            self.displayLink = CADisplayLink.init(target: self, selector: #selector(MetalBaseView.displayLinkTicked(sender:)))
            self.displayLink.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
            self.lastTickedTime = Date.init().timeIntervalSince1970
        }
    }
    
    @objc func displayLinkTicked(sender: CADisplayLink) {
        let nowTickedTime = Date.init().timeIntervalSince1970
        let deltaTime = nowTickedTime - self.lastTickedTime
        self.elapsedTime += deltaTime
        self.lastTickedTime = nowTickedTime
        update(deltaTime: deltaTime, elapsedTime: self.elapsedTime)
        render()
    }
    
    func update(deltaTime: TimeInterval, elapsedTime: TimeInterval) {
        
    }
    
    func destroy() {
        self.displayLink.remove(from: RunLoop.main, forMode: .defaultRunLoopMode)
        self.displayLink = nil
    }
}

