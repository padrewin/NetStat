import SwiftUI

struct NetworkGraphView: View {
    @State private var previousDownloads: [Double] = []
    @State private var previousUploads: [Double] = []
    let downloadSpeeds: [Double]
    let uploadSpeeds: [Double]
    let isOffline: Bool
    
    // Culorile personalizate
    let downloadColor = Color(hex: "#158EFF") // Albastru pentru download
    let uploadColor = Color(hex: "#E779FF")   // Violet pentru upload
    
    // Forme personalizate pentru barele cu partea plată la mijloc
    struct CustomPillTop: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let width = rect.width
            let height = rect.height
            let cornerRadius = min(width / 2, 6) // Raza de rotunjire redusă
            
            // Partea de sus rotunjită, partea de jos plată
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(180),
                       endAngle: .degrees(270),
                       clockwise: false)
            path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
            path.addArc(center: CGPoint(x: width - cornerRadius, y: cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(270),
                       endAngle: .degrees(0),
                       clockwise: false)
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
            
            return path
        }
    }

    struct CustomPillBottom: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let width = rect.width
            let height = rect.height
            let cornerRadius = min(width / 2, 4) // Raza de rotunjire redusă
            
            // Partea de jos rotunjită, partea de sus plată
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
            path.addArc(center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(0),
                       endAngle: .degrees(90),
                       clockwise: false)
            path.addLine(to: CGPoint(x: cornerRadius, y: height))
            path.addArc(center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                       radius: cornerRadius,
                       startAngle: .degrees(90),
                       endAngle: .degrees(180),
                       clockwise: false)
            path.closeSubpath()
            
            return path
        }
    }

    // Monitorizare pentru schimbări în date
    private func updateHistory() {
        // Inițializăm istoricul dacă este gol
        if previousDownloads.isEmpty && !downloadSpeeds.isEmpty {
            previousDownloads = downloadSpeeds
        } else if !downloadSpeeds.isEmpty {
            // Adăugăm noile valori la istoric și menținem doar ultimele maxBars
            let newDownloads = previousDownloads + [downloadSpeeds.last!]
            previousDownloads = Array(newDownloads.suffix(200)) // Păstrăm un istoric mai lung
        }
        
        if previousUploads.isEmpty && !uploadSpeeds.isEmpty {
            previousUploads = uploadSpeeds
        } else if !uploadSpeeds.isEmpty {
            // Adăugăm noile valori la istoric și menținem doar ultimele maxBars
            let newUploads = previousUploads + [uploadSpeeds.last!]
            previousUploads = Array(newUploads.suffix(200)) // Păstrăm un istoric mai lung
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Etichetă sus (upload)
            HStack {
                Text(isOffline ? "↑ Offline" : "↑ \(formatSpeed(uploadSpeeds.last ?? 0.0))")
                    .foregroundColor(isOffline ? .red : uploadColor)
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
                let barWidth: CGFloat = 6   // Lățimea barelor redusă
                let spacing: CGFloat = 3    // Spațiul redus pentru a permite mai multe bare
                let maxBars = Int(width / (barWidth + spacing))
                
                // Calculăm spațierea ajustată pentru a ocupa întreaga lățime disponibilă
                let adjustedSpacing = (width - CGFloat(maxBars) * barWidth) / max(1, CGFloat(maxBars - 1))

                // Actualizăm istoricul
                let filledDownload = Array(previousDownloads.suffix(maxBars))
                let filledUpload = Array(previousUploads.suffix(maxBars))

                // Calculăm valorile minime și maxime pentru o scală mai bună
                let recentMax = (filledDownload + filledUpload).suffix(maxBars).max() ?? 0.1
                let fallbackMax = (filledDownload + filledUpload).max() ?? 0.1
                // Folosim o valoare minimă pentru maxValue pentru a evita barele prea mici
                let maxValue = max(recentMax * 0.7 + fallbackMax * 0.3, 0.1)

                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(isOffline ? Color.red.opacity(0.25) : Color.secondary.opacity(0.2))
                        .frame(height: 1)
                        .position(x: width / 2, y: centerY)

                    ForEach(0..<maxBars, id: \.self) { i in
                        let reversedIndex = maxBars - i - 1
                        let download = reversedIndex < filledDownload.count ? filledDownload[reversedIndex] : 0
                        let upload = reversedIndex < filledUpload.count ? filledUpload[reversedIndex] : 0
                        let standardHeight: CGFloat = centerY * 0.8 // Înălțimea standard
                        
                        // Poziționăm barele de la dreapta la stânga
                        let xPos = width - (barWidth / 2 + CGFloat(i) * (barWidth + adjustedSpacing))

                        ZStack {
                            // Bara de upload (partea de sus)
                            ZStack {
                                // Conturul gri pentru fiecare bară
                                CustomPillTop()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: barWidth, height: standardHeight)
                                    .position(x: xPos, y: centerY - standardHeight / 2)
                                
                                // Bara colorată pentru traficul activ
                                // Afișăm întotdeauna o înălțime minimă vizibilă pentru orice valoare > 0
                                if upload > 0 {
                                    let fillHeight = CGFloat(upload / maxValue) * centerY
                                    // Înălțime minimă de 2 pixeli pentru a asigura vizibilitatea
                                    let adjustedHeight = max(min(fillHeight, standardHeight), 2)
                                    
                                    CustomPillTop()
                                        .fill(uploadColor)
                                        .frame(width: barWidth, height: adjustedHeight)
                                        .position(x: xPos, y: centerY - adjustedHeight / 2)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: adjustedHeight)
                                }
                            }
                            
                            // Bara de download (partea de jos)
                            ZStack {
                                // Conturul gri pentru fiecare bară
                                CustomPillBottom()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: barWidth, height: standardHeight)
                                    .position(x: xPos, y: centerY + standardHeight / 2)
                                
                                // Bara colorată pentru traficul activ
                                // Afișăm întotdeauna o înălțime minimă vizibilă pentru orice valoare > 0
                                if download > 0 {
                                    let fillHeight = CGFloat(download / maxValue) * centerY
                                    // Înălțime minimă de 2 pixeli pentru a asigura vizibilitatea
                                    let adjustedHeight = max(min(fillHeight, standardHeight), 2)
                                    
                                    CustomPillBottom()
                                        .fill(downloadColor)
                                        .frame(width: barWidth, height: adjustedHeight)
                                        .position(x: xPos, y: centerY + adjustedHeight / 2)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: adjustedHeight)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 90)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)
            // Adăugăm o tranziție pentru toată vedere graficului pentru animații fluide
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: downloadSpeeds)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: uploadSpeeds)

            // Etichetă jos (download)
            HStack {
                Text(isOffline ? "↓ Offline" : "↓ \(formatSpeed(downloadSpeeds.last ?? 0.0))")
                    .foregroundColor(isOffline ? .red : downloadColor)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.leading, 6)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 0)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .onAppear {
            // Inițializăm istoricul la prima apariție
            if previousDownloads.isEmpty && !downloadSpeeds.isEmpty {
                previousDownloads = downloadSpeeds
            }
            if previousUploads.isEmpty && !uploadSpeeds.isEmpty {
                previousUploads = uploadSpeeds
            }
        }
        .onChange(of: downloadSpeeds) { _ in
            updateHistory()
        }
        .onChange(of: uploadSpeeds) { _ in
            updateHistory()
        }
    }
}

// Extensie pentru a converti coduri hex la Color SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
