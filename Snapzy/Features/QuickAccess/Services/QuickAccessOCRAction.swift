//
//  QuickAccessOCRAction.swift
//  Snapzy
//
//  Local OCR copy action for Quick Access screenshot cards.
//

import AppKit
import CoreGraphics
import Foundation

enum QuickAccessOCRActionError: LocalizedError, Equatable {
  case unsupportedItem
  case imageUnavailable
  case imageConversionFailed
  case noContentFound
  case unsupportedQRPayloads

  var errorDescription: String? {
    switch self {
    case .unsupportedItem:
      return L10n.QuickAccess.ocrUnsupportedItem
    case .imageUnavailable:
      return L10n.QuickAccess.ocrImageUnavailable
    case .imageConversionFailed:
      return L10n.OCR.imageConversionFailed
    case .noContentFound:
      return L10n.OCR.noTextFound
    case .unsupportedQRPayloads:
      return L10n.OCR.qrTextOnlyUnsupported
    }
  }
}

@MainActor
enum QuickAccessOCRAction {
  struct Dependencies {
    var imageLoader: (QuickAccessItem) -> NSImage?
    var textRecognizer: (CGImage) async throws -> String?
    var qrDetector: (CGImage) async -> QRCodeDetectionResult
    var pasteboardWriter: (String) -> Void

    static let live = Dependencies(
      imageLoader: { item in
        let access = SandboxFileAccessManager.shared.beginAccessingURL(item.url)
        defer { access.stop() }
        return NSImage(contentsOf: item.url) ?? item.thumbnail
      },
      textRecognizer: { image in
        do {
          return try await OCRService.shared.recognizeText(
            from: image,
            preferredLanguageIdentifier: AppLanguageManager.shared.activeOCRLanguageIdentifier,
            contentType: .interfaceText
          )
        } catch OCRError.noTextFound {
          return nil
        } catch {
          DiagnosticLogger.shared.logError(.ocr, error, "Quick access OCR text recognition failed")
          return nil
        }
      },
      qrDetector: { image in
        do {
          return try await QRCodeService.shared.detect(in: image)
        } catch {
          DiagnosticLogger.shared.logError(.ocr, error, "Quick access OCR QR detection failed")
          return .empty
        }
      },
      pasteboardWriter: { text in
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
      }
    )
  }

  @discardableResult
  static func copyRecognizedContent(
    from item: QuickAccessItem,
    dependencies: Dependencies = .live
  ) async throws -> String {
    guard !item.isVideo else {
      throw QuickAccessOCRActionError.unsupportedItem
    }

    guard let image = dependencies.imageLoader(item) else {
      throw QuickAccessOCRActionError.imageUnavailable
    }

    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      throw QuickAccessOCRActionError.imageConversionFailed
    }

    let recognizedText = try await dependencies.textRecognizer(cgImage)
    let qrResult = await dependencies.qrDetector(cgImage)
    guard let clipboardText = OCRQRPayloadComposer.compose(
      recognizedText: recognizedText,
      qrDetections: qrResult.detections,
      qrSectionTitle: L10n.OCR.qrCodesLabel
    ) else {
      if qrResult.unsupportedPayloadCount > 0 {
        throw QuickAccessOCRActionError.unsupportedQRPayloads
      }
      throw QuickAccessOCRActionError.noContentFound
    }

    dependencies.pasteboardWriter(clipboardText)
    return clipboardText
  }
}
