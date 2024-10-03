import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var brightness: Double = 1.0
    @State private var colorFilterIntensity: Double = 0.0
    @State private var selectedColor: FilterColor = .none
    @State private var showIntensitySlider: Bool = false
    @Namespace private var animation
    
    private let minimumBrightness: Double = 0.05 // 5% minimum brightness
    
    var body: some View {
        VStack(spacing: 16) {
            Section(header: 
                HStack {
                    Text("Display filter").font(.headline)
                    Spacer()
                    IconButton(icon: "arrow.counterclockwise", action: toggleFilter)
                    IconButton(icon: "xmark.circle", action: {
                        NSApplication.shared.terminate(nil)
                    })
                }
            ) {
                VStack(spacing: 8) {
                    FilterCard {
                        ModernFilterSlider(value: $brightness, label: "Brightness", icon: "sun.max.fill", range: minimumBrightness...1)
                            .onChange(of: brightness) { _, newValue in
                                applyAdjustments()
                            }
                    }
                    
                    FilterCard {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Color Filter")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                HStack(spacing: 4) {
                                    ForEach(FilterColor.allCases, id: \.self) { color in
                                        ColorDot(color: color, isSelected: selectedColor == color, namespace: animation)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    if selectedColor == color && color != .none {
                                                        selectedColor = .none
                                                        showIntensitySlider = false
                                                    } else {
                                                        selectedColor = color
                                                        showIntensitySlider = color != .none
                                                    }
                                                }
                                                applyAdjustments()
                                            }
                                    }
                                }
                            }
                            if showIntensitySlider {
                                ModernFilterSlider(value: $colorFilterIntensity, label: "Intensity", icon: "slider.horizontal.3", range: 0...1)
                                    .onChange(of: colorFilterIntensity) { _, newValue in
                                        applyAdjustments()
                                    }
                                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .scale.combined(with: .opacity)))
                                    .matchedGeometryEffect(id: "intensitySlider", in: animation)
                            }
                        }
                    }
                }
            }.padding(.horizontal, 8)
        }
        .padding(14)
        .frame(width: 300)
        .onAppear {
            updateCurrentValues()
        }
    }
    
    private func applyAdjustments() {
        guard let screen = NSScreen.main else { return }
        ColorAdjuster.shared.setAdjustments(
            brightness: Float(brightness),
            filterColor: selectedColor,
            filterIntensity: Float(colorFilterIntensity),
            for: screen
        )
        appState.isFilterActive = true
    }
    
    private func toggleFilter() {
        if appState.isFilterActive {
            resetFilter()
        } else {
            applyAdjustments()
        }
    }
    
    private func resetFilter() {
        guard let screen = NSScreen.main else { return }
        ColorAdjuster.shared.resetAdjustments(for: screen)
        appState.isFilterActive = false
        updateCurrentValues()
    }
    
    private func updateCurrentValues() {
        guard let screen = NSScreen.main else { return }
        brightness = Double(ColorAdjuster.shared.getCurrentBrightness(for: screen))
        selectedColor = ColorAdjuster.shared.getCurrentFilterColor(for: screen)
        colorFilterIntensity = Double(ColorAdjuster.shared.getCurrentFilterIntensity(for: screen))
        showIntensitySlider = selectedColor != .none
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ModernFilterSlider: View {
    @Binding var value: Double
    let label: String
    let icon: String
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            ModernSlider(value: $value, range: range)
                .frame(height: 36)
        }
    }
}

struct ModernSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: value, minValue: range.lowerBound, maxValue: range.upperBound, target: context.coordinator, action: #selector(Coordinator.valueChanged(_:)))
        slider.trackFillColor = NSColor.controlAccentColor
        slider.isContinuous = true
        return slider
    }
    
    func updateNSView(_ nsView: NSSlider, context: Context) {
        nsView.doubleValue = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ModernSlider
        
        init(_ parent: ModernSlider) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: NSSlider) {
            parent.value = sender.doubleValue
        }
    }
}

struct FilterCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(10)
            .background(
                ZStack {
                    VisualEffectView(material: .menu, blendingMode: .withinWindow)
                    Color(NSColor.controlBackgroundColor).opacity(0.3)
                }
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// New components

enum FilterColor: String, CaseIterable {
    case none, orange, red, green, blue
    
    var color: Color {
        switch self {
        case .none: return Color(NSColor.lightGray)
        case .orange: return .orange
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "arrow.counterclockwise.circle.fill"
        case .orange: return "sun.max.fill"
        case .red: return "eyeglasses"
        case .green: return "leaf.fill"
        case .blue: return "drop.fill"
        }
    }
}

struct ColorDot: View {
    let color: FilterColor
    let isSelected: Bool
    let namespace: Namespace.ID
    
    var body: some View {
        ZStack {
            if color == .none {
                Image(systemName: color.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            } else {
                Circle()
                    .fill(color.color)
                    .frame(width: 20, height: 20)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .matchedGeometryEffect(id: "selectedBorder_\(color.rawValue)", in: namespace)
                }
            }
        }
        .overlay(
            Circle()
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                .frame(width: 22, height: 22)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
