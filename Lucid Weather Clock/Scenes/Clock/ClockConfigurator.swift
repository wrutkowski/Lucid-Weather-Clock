//
//  ClockConfigurator.swift
//  Lucid Weather Clock
//
//  Created by Wojciech Rutkowski on 04/10/2016.
//  Copyright (c) 2016 Wojciech Rutkowski. All rights reserved.
//

import UIKit

// MARK: Connect View, Interactor, and Presenter

extension ClockViewController: ClockPresenterOutput {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.passDataToNextScene(segue: segue)
    }
}

extension ClockInteractor: ClockViewControllerOutput {

}

extension ClockPresenter: ClockInteractorOutput {

}

class ClockConfigurator {
    // MARK: Object lifecycle

    static let sharedInstance = ClockConfigurator()
    private init() { }

    // MARK: Configuration

    func configure(viewController: ClockViewController) {
        let router = ClockRouter()
        router.viewController = viewController

        let presenter = ClockPresenter()
        presenter.output = viewController

        let interactor = ClockInteractor()
        interactor.output = presenter

        viewController.output = interactor
        viewController.router = router
    }
}
