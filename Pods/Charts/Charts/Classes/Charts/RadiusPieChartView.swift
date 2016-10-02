//
//  RadiusPieChartView.swift
//  Pods
//
//  Created by Wojciech Rutkowski on 02/10/2016.
//
//

import UIKit

open class RadiusPieChartView: PieChartView {
    override func initialize() {
        super.initialize()
        
        renderer = RadiusPieChartRenderer(chart: self, animator: self._animator, viewPortHandler: self._viewPortHandler)
    }
}
