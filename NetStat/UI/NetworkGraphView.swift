import SwiftUI
import AppKit
import Foundation

// MARK: – Shape for flat base + rounded top/bottom corners
struct RoundedCorners: Shape {
    var topLeft: CGFloat = 0, topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height

        path.move(to: CGPoint(x: topLeft, y: 0))
        path.addLine(to: CGPoint(x: w - topRight, y: 0))
        path.addArc(center: CGPoint(x: w - topRight, y: topRight),
                    radius: topRight,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - bottomRight))
        path.addArc(center: CGPoint(x: w - bottomRight, y: h - bottomRight),
                    radius: bottomRight,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: bottomLeft, y: h))
        path.addArc(center: CGPoint(x: bottomLeft, y: h - bottomLeft),
                    radius: bottomLeft,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: topLeft))
        path.addArc(center: CGPoint(x: topLeft, y: topLeft),
                    radius: topLeft,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        return path
    }
}

// MARK: – Data model with per-point frozen scale
struct NetworkDataPoint: Equatable {
    let download: Double
    let upload: Double
    let maxDownloadAtInsert: Double
    let maxUploadAtInsert: Double

    static func == (lhs: NetworkDataPoint, rhs: NetworkDataPoint) -> Bool {
        return abs(lhs.download - rhs.download) < 0.001 &&
               abs(lhs.upload - rhs.upload) < 0.001 &&
               abs(lhs.maxDownloadAtInsert - rhs.maxDownloadAtInsert) < 0.001 &&
               abs(lhs.maxUploadAtInsert - rhs.maxUploadAtInsert) < 0.001
    }
}

// MARK: – Graph view
struct NetworkGraphView: View {
    @State private var dataHistory: [NetworkDataPoint] = []
    @State private var animationTimer: Timer?
    @State private var currentDownloadSpeed: Double = 0
    @State private var currentUploadSpeed: Double = 0
    @State private var observedMaxDownload: Double = 0
    @State private var observedMaxUpload: Double = 0

    let downloadSpeeds: [Double]
    let uploadSpeeds: [Double]
    let isOffline: Bool

    let downloadColor = Color(hex: "#007AFF")
    let uploadColor   = Color(hex: "#AF52DE")

    private let maxDataPoints = 60
    private let updateInterval: TimeInterval = 0.5

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statusPill(
                    icon: "arrow.up",
                    value: isOffline ? "Offline" : formatSpeed(currentUploadSpeed),
                    color: uploadColor,
                    isUpload: true
                )
                Spacer()
                statusPill(
                    icon: "arrow.down",
                    value: isOffline ? "Offline" : formatSpeed(currentDownloadSpeed),
                    color: downloadColor,
                    isUpload: false
                )
            }
            .padding(.horizontal, 4)
            .animation(.easeInOut(duration: 0.3), value: currentDownloadSpeed)
            .animation(.easeInOut(duration: 0.3), value: currentUploadSpeed)
            .animation(.easeInOut(duration: 0.3), value: isOffline)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.separator.opacity(0.5), lineWidth: 0.5)
                    )
                graphView.padding(8)
            }
            .frame(height: 100)
        }
        .onAppear {
            initializeData()
            updateSpeeds()
            startUpdateTimer()
        }
        .onDisappear {
            stopUpdateTimer()
        }
        .onChange(of: downloadSpeeds) {
            updateSpeeds()
        }
        .onChange(of: uploadSpeeds) {
            updateSpeeds()
        }
    }

    private func statusPill(icon: String, value: String, color: Color, isUpload: Bool) -> some View {
        Label {
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText(countsDown: false))
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.gradient)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .opacity(isOffline ? 0.6 : 1.0)
    }

    private var graphView: some View {
        GeometryReader { geometry in
            let width       = geometry.size.width
            let height      = geometry.size.height
            let centerY     = height / 2
            let barWidth: CGFloat = 6
            let spacing:   CGFloat = 2
            let maxBars     = Int(width / (barWidth + spacing))
            let displayData = Array(dataHistory.prefix(maxBars))
            let maxBarHeight = centerY - 6

            ZStack {
                // linia de mijloc
                Rectangle()
                    .fill(.separator.opacity(0.3))
                    .frame(height: 1)
                    .position(x: width / 2, y: centerY)

                ForEach(Array(displayData.enumerated()), id: \.offset) { index, data in
                    let xPosition = width - CGFloat(index) * (barWidth + spacing) - barWidth/2 - 6
                    let opacity   = calculateBarOpacity(for: index, totalBars: displayData.count)
                    let isIdle    = data.upload < 0.0005 && data.download < 0.0005

                    // Grupează condițiile fără return:
                    if isOffline {
                        // Disconnected → linie roșie
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: barWidth, height: 2)
                            .position(x: xPosition, y: centerY)
                    } else if isIdle {
                        // Idle → linie verde
                        Rectangle()
                            .fill(Color(hex: "#34C759"))
                            .frame(width: barWidth, height: 2)
                            .position(x: xPosition, y: centerY)
                    } else {
                        // Download/upload normale
                        let uploadHeight = max(
                            (data.upload / max(data.maxUploadAtInsert, 0.1)) * maxBarHeight,
                            4
                        )
                        let downloadHeight = max(
                            (data.download / max(data.maxDownloadAtInsert, 0.1)) * maxBarHeight,
                            4
                        )

                        if data.upload > 0 {
                            RoundedCorners(
                                topLeft: barWidth/3, topRight: barWidth/3,
                                bottomLeft: 0, bottomRight: 0
                            )
                            .fill(uploadColor.gradient)
                            .frame(width: barWidth, height: uploadHeight)
                            .position(x: xPosition, y: centerY - uploadHeight/2)
                            .opacity(opacity)
                            .scaleEffect(y: 1.0, anchor: .bottom)
                        }

                        if data.download > 0 {
                            RoundedCorners(
                                topLeft: 0, topRight: 0,
                                bottomLeft: barWidth/3, bottomRight: barWidth/3
                            )
                            .fill(downloadColor.gradient)
                            .frame(width: barWidth, height: downloadHeight)
                            .position(x: xPosition, y: centerY + downloadHeight/2)
                            .opacity(opacity)
                            .scaleEffect(y: 1.0, anchor: .top)
                        }
                    }
                }
            }
        }
        .drawingGroup()
        .animation(.easeInOut(duration: 0.3), value: dataHistory.count)
    }

    private func calculateBarOpacity(for index: Int, totalBars: Int) -> Double {
        let fadeStart = Double(totalBars) * 0.7
        guard Double(index) > fadeStart else { return 1.0 }
        let fadeProgress = (Double(index) - fadeStart) / (Double(totalBars) - fadeStart)
        return 1.0 - (fadeProgress * 0.4)
    }

    private func initializeData() {
        let initialDownload = downloadSpeeds.last ?? 0
        let initialUpload   = uploadSpeeds.last  ?? 0

        observedMaxDownload = initialDownload
        observedMaxUpload   = initialUpload
        currentDownloadSpeed = initialDownload
        currentUploadSpeed   = initialUpload

        let point = NetworkDataPoint(
            download:            initialDownload,
            upload:              initialUpload,
            maxDownloadAtInsert: initialDownload,
            maxUploadAtInsert:   initialUpload
        )
        dataHistory = Array(repeating: point, count: maxDataPoints)
    }

    private func startUpdateTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            updateDataPoint()
        }
    }

    private func stopUpdateTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func updateSpeeds() {
        let newDownload = max(downloadSpeeds.last ?? 0, 0)
        let newUpload   = max(uploadSpeeds.last   ?? 0, 0)

        withAnimation(.easeInOut(duration: 0.6)) {
            currentDownloadSpeed = newDownload
            currentUploadSpeed   = newUpload
        }
    }

    private func updateDataPoint() {
        let newDownload = currentDownloadSpeed
        let newUpload   = currentUploadSpeed

        observedMaxDownload = max(observedMaxDownload, newDownload)
        observedMaxUpload   = max(observedMaxUpload,   newUpload)

        let point = NetworkDataPoint(
            download:            newDownload,
            upload:              newUpload,
            maxDownloadAtInsert: observedMaxDownload,
            maxUploadAtInsert:   observedMaxUpload
        )
        dataHistory.insert(point, at: 0)

        if dataHistory.count > maxDataPoints {
            dataHistory.removeLast()
        }
    }
}

// MARK: – Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

func formatSpeed(_ speed: Double) -> String {
    if speed < 0.0005 {
        return "Idle"
    } else if speed >= 1_000 {
        return String(format: "%.1f Gbps", speed / 1_000)
    } else if speed < 1 {
        return String(format: "%.0f Kbps", speed * 1_000)
    } else {
        return String(format: "%.1f Mbps", speed)
    }
}
