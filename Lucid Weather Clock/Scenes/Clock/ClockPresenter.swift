//
//  ClockPresenter.swift
//  Lucid Weather Clock
//
//  Created by Wojciech Rutkowski on 04/10/2016.
//  Copyright (c) 2016 Wojciech Rutkowski. All rights reserved.
//

import UIKit

protocol ClockPresenterInput {
    func presentSomething(response: ClockResponse)
}

protocol ClockPresenterOutput: class {
    func displaySomething(viewModel: ClockViewModel)
}

class ClockPresenter: ClockPresenterInput {
    weak var output: ClockPresenterOutput!

    // MARK: Presentation logic

    func presentSomething(response: ClockResponse) {
        // NOTE: Format the response from the Interactor and pass the result back to the View Controller

        let viewModel = ClockViewModel()
        output.displaySomething(viewModel: viewModel)
    }
}
