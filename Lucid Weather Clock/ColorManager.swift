//
//  ColorManager.swift
//  Lucid Weather Clock
//
//  Created by Wojciech Rutkowski on 09/12/15.
//  Copyright © 2015 Wojciech Rutkowski. All rights reserved.
//

import Foundation

struct ColorMapSegment {
    var temp: Float
    var color: Color
}

struct Color {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    
    var toUIColor: UIColor {
        return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1.0)
    }
}

class ColorManager {
    static let colorMap: [ColorMapSegment] = [
        ColorMapSegment(temp: -30, color: Color(r: 38,  g: 84,  b: 114)),
        ColorMapSegment(temp: -7,  color: Color(r: 75,  g: 168, b: 231)),
        ColorMapSegment(temp: 0,   color: Color(r: 115, g: 209, b: 239)),
        ColorMapSegment(temp: 5,   color: Color(r: 67,  g: 205, b: 187)),
        ColorMapSegment(temp: 18,  color: Color(r: 251, g: 171, b: 48)),
        ColorMapSegment(temp: 27,  color: Color(r: 244, g: 119, b: 25)),
        ColorMapSegment(temp: 50,  color: Color(r: 254, g: 81,  b: 12))
    ]
    
    static func convertTemperatureToColor(temp: Float) -> Color {
        var color = Color(r: 0, g: 0, b: 0)
        
        for i in 0 ..< colorMap.count {
            if temp <= colorMap[i].temp {
                if i > 0 {
                    let bottomColorMap = colorMap[i - 1]
                    let topColorMap = colorMap[i]
            
                    color.r = bottomColorMap.color.r + ((topColorMap.color.r - bottomColorMap.color.r) / CGFloat(topColorMap.temp - bottomColorMap.temp)) * CGFloat(temp - bottomColorMap.temp)
                    color.g = bottomColorMap.color.g + ((topColorMap.color.g - bottomColorMap.color.g) / CGFloat(topColorMap.temp - bottomColorMap.temp)) * CGFloat(temp - bottomColorMap.temp)
                    color.b = bottomColorMap.color.b + ((topColorMap.color.b - bottomColorMap.color.b) / CGFloat(topColorMap.temp - bottomColorMap.temp)) * CGFloat(temp - bottomColorMap.temp)
                    break
                } else {
                    // lowest temp
                    color.r = colorMap[i].color.r
                    color.g = colorMap[i].color.g
                    color.b = colorMap[i].color.b
                    break
                }
            } else if i == colorMap.count - 1 {
                // highest temp
                color.r = colorMap[i].color.r
                color.g = colorMap[i].color.g
                color.b = colorMap[i].color.b
            }
        }
        return color
    }
}