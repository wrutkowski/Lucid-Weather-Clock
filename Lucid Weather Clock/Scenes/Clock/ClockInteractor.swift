//
//  ClockInteractor.swift
//  Lucid Weather Clock
//
//  Created by Wojciech Rutkowski on 04/10/2016.
//  Copyright (c) 2016 Wojciech Rutkowski. All rights reserved.
//

import UIKit

protocol ClockInteractorInput {
    func doSomething(request: ClockRequest)
}

protocol ClockInteractorOutput {
    func presentSomething(response: ClockResponse)
}

class ClockInteractor: ClockInteractorInput {
    var output: ClockInteractorOutput!
//    var worker: ClockWorker!

    // MARK: Business logic

    func doSomething(request: ClockRequest) {
        // NOTE: Create some Worker to do the work

//        worker = ClockWorker()
//        worker.doSomeWork()

        // NOTE: Pass the result to the Presenter

        let response = ClockResponse()
        output.presentSomething(response: response)
    }
}
