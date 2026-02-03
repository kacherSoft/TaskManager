# Research Report: macOS Photo Gallery UI for TaskManager App

**Date:** 2026-02-03
**Scope:** Photo gallery UI in task management apps with Liquid Glass design

---

## Executive Summary

Key findings for implementing photo attachments in TaskManager:

1. **SwiftUI APIs:** Use `PhotosPicker` (iOS 16+/macOS 13+) for selection, `QuickLook`/`QLPreviewPanel` for viewing, `TabView` for swipe navigation
2. **Thumbnail Pattern:** Horizontal scrollable strip with glass material, rounded corners, subtle shadows
3. **Photo Viewer:** Fullscreen overlay with left/right arrows, swipe gestures, pinch-to-zoom
4. **Dark Mode:** Automatic material adaptation, `.ultraThinMaterial` for thumbnails, `.regularMaterial` for viewer
5. **Liquid Glass:** Translucent materials matching OS 26 design language

---

## Research Methodology

- **Sources consulted:** 7
- **Date range:** 2020-2025 (prioritizing recent content)
- **Key search terms:** SwiftUI PhotoPicker, QuickLook, photo gallery UI, thumbnail design, dark mode

---

## Key Findings

### 1. SwiftUI APIs for Photos

| API | Purpose | Availability |
|-----|---------|--------------|
| `PhotosPicker` | Photo selection | macOS 13+ |
| `QuickLook` / `QLPreviewPanel` | Native preview | macOS 10.15+ |
| `TabView` | Swipe navigation | SwiftUI 1.0+ |
| `Image` + `GeometryReader` | Custom viewer | All versions |

### 2. Thumbnail UI Patterns

**Best practices from research:**

- **Layout:** Horizontal scrollable strip below task notes
- **Spacing:** 4-8pt between thumbnails
- **Size:** 60-80pt height, proportional width
- **Styling:** Rounded corners (8pt), subtle shadow, glass material background
- **Indicators:** Small badge showing count for "2+ more"

**Grid vs Strip:**
- **Strip** (recommended): Horizontal scroll, shows 3-4, scrollable
- **Grid:** 2x2 or 3x3, more visual but takes more space

### 3. Photo Viewer Design

**Required features:**
- Fullscreen overlay (`.fullScreenCover` or `.overlay`)
- Left/right arrow buttons (SF Symbols: `chevron.left`, `chevron.right`)
- Swipe gestures for navigation
- Pinch-to-zoom (optional)
- Close button (X)
- Page indicator (dots or "1/5" text)

**Navigation arrows:**
- Position: Vertically centered, 20pt from edges
- Style: Semi-transparent circles, `.ultraThinMaterial`
- Size: 44pt tap target, 24pt icon
- Auto-hide after 3 seconds of inactivity

### 4. Dark Mode Styling

**Materials for dark mode:**
- Thumbnails: `.ultraThinMaterial` (translucent, adapts to theme)
- Viewer background: `.regularMaterial` or `.ultraThickMaterial`
- Arrows/buttons: `.thinMaterial` with white icons

**Color considerations:**
- Use semantic colors (`.primary`, `.secondary`)
- Ensure contrast ratio 4.5:1 for text overlays
- Test in both light/dark modes

### 5. Task Management Integration

**UI placement recommendations:**
- Position: Below task notes, above tags
- Show when: Task has photos
- Trigger: Tap thumbnail to open viewer
- Visual hierarchy: Photos secondary to task content

**Space efficiency:**
- Collapsed: Show 3 thumbnails + "+2" badge
- Expanded: Show all thumbnails in scrollable strip

---

## Implementation Recommendations

### Quick Start: Photo Thumbnail Component

```swift
struct PhotoThumbnail: View {
    let imageURL: URL
    let isSelected: Bool

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.blue, lineWidth: 2)
            }
        }
    }
}
```

### Photo Viewer with Navigation

```swift
struct PhotoViewer: View {
    let photos: [URL]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Main photo
            TabView(selection: $selectedIndex) {
                ForEach(0..<photos.count, id: \.self) { index in
                    AsyncImage(url: photos[index]) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation arrows
            HStack {
                if selectedIndex > 0 {
                    Button { selectedIndex -= 1 } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }

                Spacer()

                if selectedIndex < photos.count - 1 {
                    Button { selectedIndex += 1 } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 20)

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
```

### Liquid Glass Thumbnail Strip

```swift
struct PhotoThumbnailStrip: View {
    let photos: [URL]
    @State private var selectedIndex = 0
    @State private var showViewer = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<min(photos.count, 4), id: \.self) { index in
                    PhotoThumbnail(imageURL: photos[index], isSelected: index == selectedIndex)
                        .onTapGesture {
                            selectedIndex = index
                            showViewer = true
                        }
                }

                if photos.count > 4 {
                    Text("+\(photos.count - 4)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 70)
        .fullScreenCover(isPresented: $showViewer) {
            PhotoViewer(photos: photos, selectedIndex: $selectedIndex)
        }
    }
}
```

---

## TaskItem Model Updates Required

Add photos property:

```swift
public struct TaskItem: Identifiable, Sendable {
    // ... existing properties ...
    public let photos: [URL]  // NEW

    public init(
        // ... existing params ...
        photos: [URL] = []  // NEW
    ) {
        // ... existing assignments ...
        self.photos = photos
    }
}
```

---

## Common Pitfalls

1. **AsyncImage caching:** iOS/macOS may not cache properly, consider custom caching
2. **Memory issues:** Loading many full-res photos can crash - use thumbnails
3. **Layout shift:** Pre-calculate thumbnail sizes to avoid UI jumping
4. **Gesture conflicts:** TabView swipe may conflict with scroll - test carefully
5. **Dark mode contrast:** Test overlay text on various photo backgrounds

---

## Resources & References

### Official Documentation
- [Apple Human Interface Guidelines - Image Views](https://developer.apple.com/design/human-interface-guidelines/image-views)
- [SwiftUI TabView Documentation](https://developer.apple.com/documentation/swiftui/tabview)
- [PhotosPicker Documentation](https://developer.apple.com/documentation/photokit/phpicker)

### Tutorials & Articles
- [Building a Photo Gallery app in SwiftUI Part 4](https://codewithchris.com/photo-gallery-app-swiftui-part-4/) (Code with Chris, 2024)
- [Building a Polished Image Viewer for iOS](https://medium.com/mateedevs/building-a-polished-image-viewer-for-ios-8e2f935222a6) (Medium)
- [Image Gallery with Swipe Gesture](https://designcode.io/swiftui-handbook-image-gallery-huerotation-and-swipe-gesture/) (DesignCode)

### Design References
- [Thumbnail Design Pattern](https://ui-patterns.com/patterns/Thumbnail)
- [Gallery UI Design Best Practices](https://mobbin.com/glossary/gallery)
- [7 Best Practices for Photography in UI](https://dribbble.com/stories/2020/05/05/7-best-practices-photography-ui-design)

### Liquid Glass Inspiration
- [MacOS Tahoe 26 Liquid Glass Hands On](https://www.youtube.com/watch?v=lHnuewNM5Pc) (YouTube)
- [macOS Tahoe 26 Walkthrough](https://www.youtube.com/watch?v=kUhT77FtpMw) (YouTube)

---

## Unresolved Questions

1. Photo storage strategy (local files vs cloud URLs vs bundled assets)?
2. Photo size limits/compression for optimal performance?
3. Should photos be editable/deletable from task row?
4. Do we need photo metadata (date taken, size, dimensions)?
5. Thumbnail generation strategy (automatic vs pre-generated)?

---

**Report Generated:** 2026-02-03
