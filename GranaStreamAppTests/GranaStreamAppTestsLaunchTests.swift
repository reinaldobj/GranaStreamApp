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

    func testCurrencyValue_ParsesTextWithSpecialSpacing() {
        let withNonBreakingSpace = "R$\u{00A0}1.234,56"
        let withNarrowNoBreakSpace = "R$\u{202F}1.234,56"

        XCTAssertEqual(CurrencyTextField.value(from: withNonBreakingSpace) ?? 0, 1234.56, accuracy: 0.0001)
        XCTAssertEqual(CurrencyTextField.value(from: withNarrowNoBreakSpace) ?? 0, 1234.56, accuracy: 0.0001)
    }

    func testCurrencyInitialText_AlwaysKeepsCents() {
        XCTAssertEqual(CurrencyTextField.initialText(from: 9), "R$ 9,00")
        XCTAssertEqual(CurrencyTextField.initialText(from: 9.5), "R$ 9,50")
    }
}
