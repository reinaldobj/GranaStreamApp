//
//  GranaStreamAppTestsLaunchTests.swift
//  GranaStreamAppTests
//
//  Created by Reinaldo Junior on 07/02/26.
//

import XCTest
@testable import GranaStreamApp

final class GranaStreamAppTestsLaunchTests: XCTestCase {
    func testDateCoder_ParsesSupportedBackendFormats() {
        let samples = [
            "2026-02-10T12:30:45.1234567Z",
            "2026-02-10T12:30:45.123456Z",
            "2026-02-10T12:30:45.123Z",
            "2026-02-10T12:30:45Z",
            "2026-02-10T12:30:45.1234567"
        ]

        for sample in samples {
            XCTAssertNotNil(DateCoder.parseDate(sample), "Data inválida para formato: \(sample)")
        }
    }

    func testCurrencyFormatter_ReturnsFormattedText() {
        let formatted = CurrencyFormatter.string(from: 1234.56)
        XCTAssertFalse(formatted.isEmpty)
    }
}
