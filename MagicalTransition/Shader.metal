//
//  Shader.metal
//  BrokenGlassEffect
//
//  Created by wang yang on 2017/8/21.
//  Copyright © 2017年 ocean. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    packed_float3  position;
    packed_float2  texcoord;
};

struct VertexOut
{
    float4  position [[position]];
    float2  texcoord;
};

struct Uniforms
{
    float animationElapsedTime;
    float animationTotalTime;
    packed_float3 gatherPoint;
};

vertex VertexOut passThroughVertex(uint vid [[ vertex_id ]],
                                   const device VertexIn* vertexIn [[ buffer(0) ]],
                                   const device Uniforms& uniforms [[ buffer(1) ]])
{
    VertexOut outVertex;
    VertexIn inVertex = vertexIn[vid];
    float animationPercent = uniforms.animationElapsedTime / uniforms.animationTotalTime;
    animationPercent = animationPercent > 1.0 ? 1.0 : animationPercent;
    
    // 求解缩放轴和移动轴
    float moveMaxDisplacement = 2.0; // 最远移动位移，带符号
    int scaleAxis = 0; // 默认缩放轴为X
    int moveAxis = 1;   // 默认移动轴为Y，即沿着y方向吸入的效果
    if (uniforms.gatherPoint[0] <= -1 || uniforms.gatherPoint[0] >= 1) {
        scaleAxis = 1;
        moveAxis = 0;
    }
    if (uniforms.gatherPoint[moveAxis] >= 0) {
        moveMaxDisplacement = uniforms.gatherPoint[moveAxis] + 1;
    } else {
        moveMaxDisplacement = uniforms.gatherPoint[moveAxis] - 1;
    }
    
    
    // 动画第一阶段的时间占比
    float animationFirstStagePercent = 0.4;
    
    // 移动轴的动画只有在第一阶段结束后才开始进行。
    float moveAxisAnimationPercent = (animationPercent - animationFirstStagePercent) / (1.0 - animationFirstStagePercent);
    moveAxisAnimationPercent = moveAxisAnimationPercent < 0.0 ? 0.0 : moveAxisAnimationPercent;
    moveAxisAnimationPercent = moveAxisAnimationPercent > 1.0 ? 1.0 : moveAxisAnimationPercent;
    
    // 用于缩放轴计算缩放量的因子
    float scaleAxisFactor = abs(uniforms.gatherPoint[moveAxis] - (inVertex.position[moveAxis] + moveMaxDisplacement * moveAxisAnimationPercent)) / abs(moveMaxDisplacement);
    float scaleAxisAnimationEndValue = 0.5 * 0.98 * cos(3.14 * scaleAxisFactor + 3.14) + 0.5 + 0.01;
    float scaleAxisCurrentValue = 0;
    if (animationPercent <= animationFirstStagePercent) {
        scaleAxisCurrentValue = 1 +  (scaleAxisAnimationEndValue - 1) * animationPercent / animationFirstStagePercent;
    } else {
        scaleAxisCurrentValue = scaleAxisAnimationEndValue;
    }
    
    float newMoveAxisValue = inVertex.position[moveAxis] + moveMaxDisplacement * moveAxisAnimationPercent;
    float newScaleAxisValue = inVertex.position[scaleAxis] - (inVertex.position[scaleAxis] - uniforms.gatherPoint[scaleAxis]) * (1 - scaleAxisCurrentValue);
    float3 newPosition = float3(0, 0, inVertex.position[2]);
    newPosition[moveAxis] = newMoveAxisValue;
    newPosition[scaleAxis] = newScaleAxisValue;
    
    outVertex.position = float4(newPosition, 1.0);
    outVertex.texcoord = inVertex.texcoord;
    return outVertex;
};

constexpr sampler s(coord::normalized, address::repeat, filter::linear);

fragment float4 passThroughFragment(VertexOut inFrag [[stage_in]],
                                     texture2d<float> diffuse [[ texture(0) ]],
                                    const device Uniforms& uniforms [[ buffer(0) ]])
{
    float4 finalColor = diffuse.sample(s, inFrag.texcoord);
    return finalColor;
};
