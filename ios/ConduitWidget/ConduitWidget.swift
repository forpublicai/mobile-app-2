//
//  PublicAIWidget.swift
//  PublicAIWidget
//
//  Created by cogwheel on 07/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PublicAIEntry: TimelineEntry {
    let date: Date
}

// MARK: - Timeline Provider

struct PublicAIProvider: TimelineProvider {
    func placeholder(in context: Context) -> PublicAIEntry {
        PublicAIEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PublicAIEntry) -> Void) {
        let entry = PublicAIEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PublicAIEntry>) -> Void) {
        let entry = PublicAIEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Widget View

struct PublicAIWidgetEntryView: View {
    var entry: PublicAIProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    /// Adaptive text/icon color based on color scheme
    private var contentColor: Color {
        colorScheme == .dark ? .white : .black
    }

    /// Adaptive button background based on color scheme
    private var buttonBackground: Color {
        colorScheme == .dark
            ? .white.opacity(0.15)
            : .black.opacity(0.08)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Main "Ask Public AI" pill - ChatGPT style
            Link(destination: URL(string: "publicai://new_chat?homeWidget=true")!) {
                HStack(spacing: 12) {
                    Image("HubIcon")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(contentColor.opacity(0.85))
                    Text("Ask Public AI")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(contentColor.opacity(0.85))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(buttonBackground)
                )
            }
            .buttonStyle(.plain)

            // 4 circular icon buttons - ChatGPT style, fill width
            HStack(spacing: 8) {
                CircularIconButton(
                    symbol: "camera",
                    url: "publicai://camera?homeWidget=true",
                    contentColor: contentColor,
                    buttonBackground: buttonBackground
                )
                CircularIconButton(
                    symbol: "photo.on.rectangle.angled",
                    url: "publicai://photos?homeWidget=true",
                    contentColor: contentColor,
                    buttonBackground: buttonBackground
                )
                CircularIconButton(
                    symbol: "waveform",
                    url: "publicai://mic?homeWidget=true",
                    contentColor: contentColor,
                    buttonBackground: buttonBackground
                )
                CircularIconButton(
                    symbol: "doc.on.clipboard",
                    url: "publicai://clipboard?homeWidget=true",
                    contentColor: contentColor,
                    buttonBackground: buttonBackground
                )
            }
        }
        .padding(16)
    }
}

// MARK: - Circular Icon Button (ChatGPT Style)

struct CircularIconButton: View {
    let symbol: String
    let url: String
    let contentColor: Color
    let buttonBackground: Color

    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(contentColor.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(buttonBackground)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget Configuration

struct PublicAIWidget: Widget {
    let kind: String = "ConduitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PublicAIProvider()) { entry in
            if #available(iOS 17.0, *) {
                PublicAIWidgetEntryView(entry: entry)
                    .containerBackground(Color("WidgetBackground"), for: .widget)
            } else {
                PublicAIWidgetEntryView(entry: entry)
                    .background(Color("WidgetBackground"))
            }
        }
        .configurationDisplayName("Public AI")
        .description("Quick access to chat, camera, photos, and voice.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    PublicAIWidget()
} timeline: {
    PublicAIEntry(date: .now)
}

