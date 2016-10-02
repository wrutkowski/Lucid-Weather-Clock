//
//  RadiusPieChartRenderer.swift
//  Pods
//
//  Created by Wojciech Rutkowski on 02/10/2016.
//
//

import UIKit

class RadiusPieChartRenderer: PieChartRenderer {
    override func drawDataSet(context: CGContext, dataSet: IPieChartDataSet) {
        guard let chart = chart,
            let data = chart.data,
            let animator = animator
            else { return }
        
        var angle: CGFloat = 0.0
        let rotationAngle = chart.rotationAngle
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        let entryCount = dataSet.entryCount
        var drawAngles = chart.drawAngles
        let center = chart.centerCircleBox
        var radius = chart.radius
        let drawInnerArc = chart.drawHoleEnabled && !chart.drawSlicesUnderHoleEnabled
        let userInnerRadius = drawInnerArc ? radius * chart.holeRadiusPercent : 0.0
        
        var visibleAngleCount = 0
        for j in 0 ..< entryCount
        {
            guard let e = dataSet.entryForIndex(j) else { continue }
            if ((abs(e.value) > 0.000001))
            {
                visibleAngleCount += 1
            }
        }
        
        let sliceSpace = visibleAngleCount <= 1 ? 0.0 : dataSet.sliceSpace
        
        context.saveGState()
        
        for j in 0 ..< entryCount
        {
            let sliceAngle = drawAngles[j]
            var innerRadius = userInnerRadius
            
            guard let e = dataSet.entryForIndex(j) else { continue }
            
            if let radiusRatio = e.data as? Double {
                radius = chart.radius * CGFloat(radiusRatio)
            }
            
            // draw only if the value and radius is greater than zero
            if (abs(e.value) > 0.000001 && radius > 0)
            {
                if (!chart.needsHighlight(xIndex: e.xIndex,
                                          dataSetIndex: data.indexOfDataSet(dataSet)))
                {
                    let accountForSliceSpacing = sliceSpace > 0.0 && sliceAngle <= 180.0
                    
                    context.setFillColor(dataSet.colorAt(j).cgColor)
                    
                    let sliceSpaceAngleOuter = visibleAngleCount == 1 ?
                        0.0 :
                        sliceSpace / (ChartUtils.Math.FDEG2RAD * radius)
                    let startAngleOuter = rotationAngle + (angle + sliceSpaceAngleOuter / 2.0) * phaseY
                    var sweepAngleOuter = (sliceAngle - sliceSpaceAngleOuter) * phaseY
                    if (sweepAngleOuter < 0.0)
                    {
                        sweepAngleOuter = 0.0
                    }
                    
                    let arcStartPointX = center.x + radius * cos(startAngleOuter * ChartUtils.Math.FDEG2RAD)
                    let arcStartPointY = center.y + radius * sin(startAngleOuter * ChartUtils.Math.FDEG2RAD)
                    
                    let path = CGMutablePath()
                    
                    path.move(to: CGPoint(x: arcStartPointX, y: arcStartPointY))
                    
                    path.addRelativeArc(center: CGPoint(x: center.x, y: center.y),
                                        radius: radius,
                                        startAngle: startAngleOuter * ChartUtils.Math.FDEG2RAD,
                                        delta: sweepAngleOuter * ChartUtils.Math.FDEG2RAD)
                    
                    if drawInnerArc &&
                        (innerRadius > 0.0 || accountForSliceSpacing)
                    {
                        if accountForSliceSpacing
                        {
                            var minSpacedRadius = calculateMinimumRadiusForSpacedSlice(
                                center: center,
                                radius: radius,
                                angle: sliceAngle * phaseY,
                                arcStartPointX: arcStartPointX,
                                arcStartPointY: arcStartPointY,
                                startAngle: startAngleOuter,
                                sweepAngle: sweepAngleOuter)
                            if minSpacedRadius < 0.0
                            {
                                minSpacedRadius = -minSpacedRadius
                            }
                            innerRadius = min(max(innerRadius, minSpacedRadius), radius)
                        }
                        
                        let sliceSpaceAngleInner = visibleAngleCount == 1 || innerRadius == 0.0 ?
                            0.0 :
                            sliceSpace / (ChartUtils.Math.FDEG2RAD * innerRadius)
                        let startAngleInner = rotationAngle + (angle + sliceSpaceAngleInner / 2.0) * phaseY
                        var sweepAngleInner = (sliceAngle - sliceSpaceAngleInner) * phaseY
                        if (sweepAngleInner < 0.0)
                        {
                            sweepAngleInner = 0.0
                        }
                        let endAngleInner = startAngleInner + sweepAngleInner
                        
                        path.addLine(to: CGPoint(x: center.x + innerRadius * cos(endAngleInner * ChartUtils.Math.FDEG2RAD),
                                                 y: center.y + innerRadius * sin(endAngleInner * ChartUtils.Math.FDEG2RAD)))
                        path.addRelativeArc(center: CGPoint(x: center.x, y: center.y),
                                            radius: innerRadius,
                                            startAngle: endAngleInner * ChartUtils.Math.FDEG2RAD,
                                            delta: -sweepAngleInner * ChartUtils.Math.FDEG2RAD)
                    }
                    else
                    {
                        if accountForSliceSpacing
                        {
                            let angleMiddle = startAngleOuter + sweepAngleOuter / 2.0
                            
                            let sliceSpaceOffset =
                                calculateMinimumRadiusForSpacedSlice(
                                    center: center,
                                    radius: radius,
                                    angle: sliceAngle * phaseY,
                                    arcStartPointX: arcStartPointX,
                                    arcStartPointY: arcStartPointY,
                                    startAngle: startAngleOuter,
                                    sweepAngle: sweepAngleOuter)
                            
                            let arcEndPointX = center.x + sliceSpaceOffset * cos(angleMiddle * ChartUtils.Math.FDEG2RAD)
                            let arcEndPointY = center.y + sliceSpaceOffset * sin(angleMiddle * ChartUtils.Math.FDEG2RAD)
                            
                            path.addLine(to: CGPoint(x: arcEndPointX, y: arcEndPointY))
                        }
                        else
                        {
                            path.addLine(to: CGPoint(x: center.x, y: center.y))
                        }
                    }
                    
                    path.closeSubpath()
                    
                    context.beginPath()
                    context.addPath(path)
                    context.fillPath(using: .evenOdd)
                }
            }
            
            angle += sliceAngle * phaseX
        }
        
        context.restoreGState()
    }
}
