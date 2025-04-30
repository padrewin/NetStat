import SwiftUI

struct NetworkGraphView: View {
    let downloadSpeeds: [Double]
    let uploadSpeeds: [Double]
    let isOffline: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Etichetă sus (upload)
            HStack {
                Text(isOffline ? "↑ Offline" : "↑ \(formatSpeed(uploadSpeeds.last ?? 0.0))")
                    .foregroundColor(isOffline ? .red : .green)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.leading, 6)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 0)
                Spacer()
            }

            // Grafic
            GeometryReader { geometry in
                let height = geometry.size.height
                let width = geometry.size.width
                let centerY = height / 2
                let barWidth: CGFloat = 4
                let spacing: CGFloat = 2
                let maxBars = Int(width / (barWidth + spacing))

                let filledDownload = Array(downloadSpeeds.suffix(maxBars).reversed())
                let filledUpload = Array(uploadSpeeds.suffix(maxBars).reversed())

                let recentMax = (filledDownload + filledUpload).suffix(10).max() ?? 0.1
                let fallbackMax = (filledDownload + filledUpload).max() ?? 0.1
                let maxValue = max(recentMax * 0.7 + fallbackMax * 0.3, 1.0)

                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(isOffline ? Color.red.opacity(0.25) : Color.secondary.opacity(0.2))
                        .frame(height: 1)
                        .position(x: width / 2, y: centerY)

                    ForEach(0..<maxBars, id: \.self) { i in
                        let download = i < filledDownload.count ? filledDownload[i] : 0
                        let upload = i < filledUpload.count ? filledUpload[i] : 0
                        let dHeightRaw = CGFloat(download / maxValue) * centerY
                        let uHeightRaw = CGFloat(upload / maxValue) * centerY
                        let xPos = width - CGFloat(i) * (barWidth + spacing) - barWidth / 2

                        ZStack {
                            if upload > 0 {
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: barWidth, height: max(uHeightRaw, 1.5))
                                    .position(x: xPos, y: centerY - max(uHeightRaw, 1.5) / 2)
                                    .animation(.easeInOut(duration: 0.2), value: uHeightRaw)
                                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 0)
                            } else if download == 0 && !isOffline {
                                Rectangle()
                                    .fill(Color.yellow.opacity(0.4))
                                    .frame(width: barWidth, height: 0.5)
                                    .position(x: xPos, y: centerY - 0.25)
                                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 0)
                            }

                            if download > 0 {
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: barWidth, height: max(dHeightRaw, 1.5))
                                    .position(x: xPos, y: centerY + max(dHeightRaw, 1.5) / 2)
                                    .animation(.easeInOut(duration: 0.2), value: dHeightRaw)
                                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 0)
                            } else if upload == 0 && !isOffline {
                                Rectangle()
                                    .fill(Color.yellow.opacity(0.4))
                                    .frame(width: barWidth, height: 0.5)
                                    .position(x: xPos, y: centerY + 0.25)
                                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 0)
                            }
                        }
                    }
                }
            }
            .frame(height: 80)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(6)

            // Etichetă jos (download)
            HStack {
                Text(isOffline ? "↓ Offline" : "↓ \(formatSpeed(downloadSpeeds.last ?? 0.0))")
                    .foregroundColor(isOffline ? .red : .blue)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.leading, 6)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 0)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
}

func formatSpeed(_ speed: Double) -> String {
    if speed < 0.001 {
        return "Idle"
    } else if speed >= 1_000 {
        return String(format: "%.1f Gbps", speed / 1_000)
    } else if speed < 1 {
        return String(format: "%.0f Kbps", speed * 1_000)
    } else {
        return String(format: "%.1f Mbps", speed)
    }
}
