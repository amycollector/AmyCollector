//
//  AmeliaUITests.swift
//  AmeliaUITests
//
//  Created by Amy Collector on 06/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import XCTest

class AmeliaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        snapshot("01MainView")
        
        app.buttons["Animal Crossing"].firstMatch.tap()
        
        snapshot("02OwnedList")
        
        app.buttons["Amy"].tap()
        
        app.buttons["Pokemon"].tap()
        // app.cells.firstMatch.tap()
        
        snapshot("03WishList")
        
        // app.buttons["Pokemon"].tap()
        app.buttons["Amy"].tap()
        app.buttons["Ankha"].tap()
        
        snapshot("04Details")

        app.buttons["Amy"].tap()

        snapshot("05Sync")

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
