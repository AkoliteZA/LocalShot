//
//  OCRRecognitionTests.swift
//  SnapzyTests
//
//  Regression coverage for language-aware Vision OCR routing.
//

import Vision
import XCTest
@testable import LocalShot

@MainActor
final class OCRRecognitionTests: XCTestCase {

  func testVisionOCRProfile_routesReadmeSupportedLanguages() throws {
    let cases: [(language: String, primaryVisionLanguage: String?, profileID: String)] = [
      ("en", nil, "default-interface"),
      ("vi", "vi-VT", "vietnamese-interface"),
      ("zh-Hans", "zh-Hans", "simplified-chinese-interface"),
      ("zh-Hant", "zh-Hant", "traditional-chinese-interface"),
      ("es", "es-ES", "spanish-interface"),
      ("ja", "ja-JP", "japanese-interface"),
      ("ko", "ko-KR", "korean-interface"),
      ("ru", "ru-RU", "russian-interface"),
      ("fr", "fr-FR", "french-interface"),
      ("de", "de-DE", "german-interface"),
    ]

    for testCase in cases {
      let profile = VisionOCRProfile.resolve(
        for: OCRRequest(
          image: try OCRTestImageRenderer.renderImage(text: "LocalShot OCR"),
          preferredLanguageIdentifier: testCase.language
        )
      )

      XCTAssertEqual(profile.id, testCase.profileID, testCase.language)
      XCTAssertEqual(profile.recognitionLanguages.first, testCase.primaryVisionLanguage, testCase.language)
      XCTAssertEqual(profile.automaticallyDetectsLanguage, testCase.primaryVisionLanguage == nil, testCase.language)
      XCTAssertTrue(profile.usesLanguageCorrection, testCase.language)
    }
  }

  func testVietnameseOCR_preservesDiacriticsForShortIssuePhrase() async throws {
    try skipIfVisionLanguageUnavailable("vi-VT")

    let result = try await OCRService.shared.recognize(
      OCRRequest(
        image: try OCRTestImageRenderer.renderImage(text: "Tài sản"),
        preferredLanguageIdentifier: "vi",
        contentType: .interfaceText
      )
    )

    XCTAssertTrue(result.text.contains("Tài sản"), result.text)
    XCTAssertFalse(result.text.contains("Tai san"), result.text)
    XCTAssertEqual(result.profileID, "vietnamese-interface")
  }

  func testVietnameseOCR_preservesDiverseDiacriticsForCommonPhrases() async throws {
    try skipIfVisionLanguageUnavailable("vi-VT")

    let phrases = [
      "Tài sản cố định",
      "Số dư tài khoản",
      "Đường dẫn đã sao chép",
      "Ưu đãi đặc biệt",
      "Chỉnh sửa thủ công",
      "Cộng hòa xã hội"
    ]

    for phrase in phrases {
      let result = try await OCRService.shared.recognize(
        OCRRequest(
          image: try OCRTestImageRenderer.renderImage(text: phrase),
          preferredLanguageIdentifier: "vi",
          contentType: .interfaceText
        )
      )

      XCTAssertTrue(
        normalizedForDiacriticRegression(result.text).contains(normalizedForDiacriticRegression(phrase)),
        "expected \(phrase), got \(result.text)"
      )
    }
  }

  func testVietnameseOCR_reflowsSameRowWordFragments() async throws {
    try skipIfVisionLanguageUnavailable("vi-VT")

    let result = try await OCRService.shared.recognize(
      OCRRequest(
        image: try OCRTestImageRenderer.renderImage(textChunks: ["Ưu đãi", "đặc", "biệt"], horizontalGap: 100),
        preferredLanguageIdentifier: "vi",
        contentType: .interfaceText
      )
    )

    XCTAssertTrue(
      OCRBenchmarkMetrics.normalized(result.text).contains("Ưu đãi đặc biệt"),
      "expected same-row fragments to reflow, got \(result.text)"
    )
  }

  func testOCR_recognizesReadmeSupportedLanguageSamples() async throws {
    let cases: [(language: String, visionLanguage: String, text: String)] = [
      ("en", "en-US", "Copy text"),
      ("vi", "vi-VT", "Chính xác"),
      ("zh-Hans", "zh-Hans", "复制文本"),
      ("zh-Hant", "zh-Hant", "複製文字"),
      ("es", "es-ES", "Texto rápido"),
      ("ja", "ja-JP", "設定画面"),
      ("ko", "ko-KR", "설정 화면"),
      ("ru", "ru-RU", "Точные заметки"),
      ("fr", "fr-FR", "Texte précis"),
      ("de", "de-DE", "Überschriften"),
    ]
    let supportedLanguages = try supportedVisionLanguages()

    for testCase in cases {
      guard isVisionLanguageUsable(testCase.visionLanguage, supportedLanguages: supportedLanguages) else {
        continue
      }

      let result = try await OCRService.shared.recognize(
        OCRRequest(
          image: try OCRTestImageRenderer.renderImage(text: testCase.text),
          preferredLanguageIdentifier: testCase.language,
          contentType: .interfaceText
        )
      )

      XCTAssertTrue(
        OCRBenchmarkMetrics.normalized(result.text).contains(testCase.text),
        "\(testCase.language): expected \(testCase.text), got \(result.text)"
      )
    }
  }

  func testSimplifiedChineseOCR_recognizesVerticalStreetSignText() async throws {
    try XCTSkipIf(!supportedVisionLanguages().contains("zh-Hans"), "Vision Simplified Chinese OCR unavailable")

    let result = try await OCRService.shared.recognize(
      OCRRequest(
        image: try OCRTestImageRenderer.renderVerticalCJKImage(text: "龙沄路"),
        preferredLanguageIdentifier: "zh-Hans",
        contentType: .interfaceText
      )
    )

    XCTAssertTrue(
      normalizedForCJKRegression(result.text).contains("龙沄路"),
      "expected vertical Chinese text to be recognized in reading order, got \(result.text)"
    )
  }

  private func supportedVisionLanguages() throws -> Set<String> {
    Set(try VNRecognizeTextRequest().supportedRecognitionLanguages())
  }

  private func skipIfVisionLanguageUnavailable(_ visionLanguage: String) throws {
    let supportedLanguages = try supportedVisionLanguages()
    try XCTSkipIf(
      !isVisionLanguageUsable(visionLanguage, supportedLanguages: supportedLanguages),
      "Vision OCR language \(visionLanguage) unavailable or missing required local language model assets"
    )
  }

  private func isVisionLanguageUsable(
    _ visionLanguage: String,
    supportedLanguages: Set<String>
  ) -> Bool {
    guard supportedLanguages.contains(visionLanguage) else { return false }

    // Some macOS installs advertise Vietnamese OCR support while the local
    // linguistic asset is incomplete. Vision then logs a missing vi.lm/lm.dat
    // error and can terminate the test host during short-text recognition.
    guard visionLanguage == "vi-VT" else { return true }
    return hasInstalledLanguageModelData(languageCode: "vi")
  }

  private func hasInstalledLanguageModelData(languageCode: String) -> Bool {
    let fileManager = FileManager.default
    let roots = [
      "/System/Library/AssetsV2/com_apple_MobileAsset_LinguisticData",
      "/Library/AssetsV2/com_apple_MobileAsset_LinguisticData",
    ].map { URL(fileURLWithPath: $0, isDirectory: true) }

    for root in roots where fileManager.fileExists(atPath: root.path) {
      guard let enumerator = fileManager.enumerator(
        at: root,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      ) else { continue }

      for case let url as URL in enumerator where url.lastPathComponent == "\(languageCode).lm" {
        let dataURL = url.appendingPathComponent("lm.dat")
        if fileManager.fileExists(atPath: dataURL.path) {
          return true
        }
      }
    }

    return false
  }

  private func normalizedForDiacriticRegression(_ text: String) -> String {
    OCRBenchmarkMetrics.normalized(text).filter { !$0.isWhitespace }
  }

  private func normalizedForCJKRegression(_ text: String) -> String {
    OCRBenchmarkMetrics.normalized(text).filter { !$0.isWhitespace }
  }

}
