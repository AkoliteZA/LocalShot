//
//  HistoryDetailThumbnailView.swift
//  Snapzy
//
//  Thumbnail preview used by history detail panes.
//

import SwiftUI

struct HistoryDetailThumbnailView: View {
  let record: CaptureHistoryRecord

  @Environment(\.colorScheme) private var colorScheme
  @State private var thumbnailImage: NSImage?

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(previewBackground)

      if let thumbnailImage {
        Image(nsImage: thumbnailImage)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Image(systemName: record.captureType.systemIconName)
          .font(.system(size: 28, weight: .medium))
          .foregroundColor(.secondary.opacity(0.62))
      }

      if let duration = record.formattedDuration, record.captureType != .screenshot {
        Text(duration)
          .font(.caption2.weight(.semibold))
          .padding(.horizontal, 7)
          .padding(.vertical, 4)
          .background(Color.black.opacity(0.7), in: Capsule())
          .foregroundColor(.white)
          .padding(8)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(previewBorder, lineWidth: 1)
    )
    .task(id: record.id) {
      thumbnailImage = loadThumbnail()
    }
  }

  private var previewBackground: Color {
    colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.86)
  }

  private var previewBorder: Color {
    colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
  }

  private func loadThumbnail() -> NSImage? {
    if let thumbnailURL = record.thumbnailURL,
       let image = NSImage(contentsOf: thumbnailURL) {
      return image
    }

    guard record.captureType != .video,
          FileManager.default.fileExists(atPath: record.filePath) else {
      return nil
    }

    return NSImage(contentsOf: record.fileURL)
  }
}
