//
//  GranaStreamAppTests.swift
//  GranaStreamAppTests
//
//  Created by Reinaldo Junior on 07/02/26.
//

import XCTest
@testable import GranaStreamApp

final class GranaStreamAppTests: XCTestCase {
    func testLoadingState_WhenReloading_KeepPreviousDataVisible() {
        let state: LoadingState<[Int]> = .loading(previousData: [10, 20, 30])

        XCTAssertTrue(state.isLoading)
        XCTAssertFalse(state.isInitialLoading)
        XCTAssertEqual(state.data, [10, 20, 30])
    }

    func testLoadingState_WhenInitialLoading_HasNoPreviousData() {
        let state: LoadingState<[Int]> = .loading()

        XCTAssertTrue(state.isLoading)
        XCTAssertTrue(state.isInitialLoading)
        XCTAssertNil(state.data)
    }
}
