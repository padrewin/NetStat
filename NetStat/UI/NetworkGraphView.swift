import SwiftUI
import AppKit
import Foundation

struct NetworkGraphView: View {
    @State private var previousDownloads: [Double] = []
    @State private var previousUploads: [Double] = []
    
    let downloadSpeeds: [Double]
    let uploadSpeeds: [Double]
    let isOffline: Bool
    
    // Culori personalizate
    let downloadColor = Color(hex: "#158EFF") // Albastru pentru download
    let uploadColor = Color(hex: "#E779FF")   // Violet pentru upload
    
    // Culori pentru indicatorii de tip pill-shape
    let uploadBackgroundColor = Color(hex: "#663280") // Fundal violet închis pentru upload
    let downloadBackgroundColor = Color(hex: "#1B4C8C") // Fundal albastru închis pentru download
    
    // Graficul pentru background exact ca în Image 2
    var graphBackgroundColor: Color {
        Color(hex: "#232323") // Fundal gri închis
    }
    
    var graphGridColor: Color {
        Color(hex: "#3A3A3A") // Linii grid gri
    }
    
    // Monitorizare pentru schimbări în date
    private func updateHistory() {
        // Asigurăm că avem suficiente date pentru a umple întregul grafic
        let minDataPoints = 60 // Minim de puncte de date pentru a umple graficul
        
        // Logică pentru download - verificăm dacă există activitate reală
        let hasDownloadActivity = downloadSpeeds.last ?? 0 > 0.001 // Pragul pentru activitate reală
        
        if previousDownloads.isEmpty && !downloadSpeeds.isEmpty {
            if hasDownloadActivity {
                // Inițializăm cu valoarea actuală repetată pentru a umple graficul
                let initialValue = downloadSpeeds.last ?? 0
                previousDownloads = Array(repeating: initialValue, count: minDataPoints)
            } else {
                // Inițializăm cu zerouri dacă nu există activitate
                previousDownloads = Array(repeating: 0.0, count: minDataPoints)
            }
        } else if !downloadSpeeds.isEmpty {
            let newValue = hasDownloadActivity ? downloadSpeeds.last! : 0.0
            // Adăugăm valoarea nouă la începutul array-ului și păstrăm istoricul suficient de lung
            previousDownloads = [newValue] + previousDownloads.prefix(minDataPoints - 1)
        }
        
        // Logică pentru upload - verificăm dacă există activitate reală
        let hasUploadActivity = uploadSpeeds.last ?? 0 > 0.001 // Pragul pentru activitate reală
        
        if previousUploads.isEmpty && !uploadSpeeds.isEmpty {
            if hasUploadActivity {
                // Inițializăm cu valoarea actuală repetată pentru a umple graficul
                let initialValue = uploadSpeeds.last ?? 0
                previousUploads = Array(repeating: initialValue, count: minDataPoints)
            } else {
                // Inițializăm cu zerouri dacă nu există activitate
                previousUploads = Array(repeating: 0.0, count: minDataPoints)
            }
        } else if !uploadSpeeds.isEmpty {
            let newValue = hasUploadActivity ? uploadSpeeds.last! : 0.0
            // Adăugăm valoarea nouă la începutul array-ului și păstrăm istoricul suficient de lung
            previousUploads = [newValue] + previousUploads.prefix(minDataPoints - 1)
        }
        
        // Debug - verificăm valorile
        if !previousDownloads.isEmpty {
            print("Download activity: \(hasDownloadActivity), value: \(downloadSpeeds.last ?? 0)")
        }
        if !previousUploads.isEmpty {
            print("Upload activity: \(hasUploadActivity), value: \(uploadSpeeds.last ?? 0)")
        }
    }
    
    // Funcție pentru logaritm în baza 10
    func log10(_ x: Double) -> Double {
        return log(x) / log(10)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Indicatoare tip pill-shape în partea de sus
            HStack(spacing: 0) {
                // Indicator upload (stânga)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isOffline ? .red : uploadColor)
                    
                    Text(isOffline ? "Offline" : formatSpeed(uploadSpeeds.last ?? 0.0))
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.trailing, 8)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(uploadBackgroundColor)
                )
                
                Spacer()
                
                // Indicator download (dreapta)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isOffline ? .red : downloadColor)
                    
                    Text(isOffline ? "Offline" : formatSpeed(downloadSpeeds.last ?? 0.0))
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.trailing, 8)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(downloadBackgroundColor)
                )
            }
            .padding(.horizontal, 6)

            // Grafic integrat cu coloane "pill-shaped"
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let centerY = height / 2
                
                // Parametri pentru coloane
                let columnWidth: CGFloat = 4
                let spacing: CGFloat = 2.5
                let totalColumns = Int((width) / (columnWidth + spacing))
                
                // Calculăm padding-ul din partea stângă pentru a elimina spațiul gol
                let leftPadding: CGFloat = 2.0
                
                ZStack {
                    // Fundal
                    Rectangle()
                        .fill(graphBackgroundColor)
                        .frame(width: width, height: height)
                        .cornerRadius(5)
                    
                    // Linii verticale pentru grid - distribuție uniformă
                    ForEach(0..<totalColumns+1, id: \.self) { i in
                        Rectangle()
                            .fill(graphGridColor)
                            .frame(width: 1, height: height)
                            .position(x: leftPadding + (CGFloat(i) * (columnWidth + spacing)), y: centerY)
                    }
                    
                    // Linia centrală orizontală
                    Rectangle()
                        .fill(graphGridColor)
                        .frame(height: 1)
                        .position(x: width / 2, y: centerY)
                    
                    // Desenăm coloanele integrate "pill-shaped"
                    ForEach(0..<min(totalColumns, previousDownloads.count), id: \.self) { i in
                        // Obținem valorile pentru această coloană
                        let download = i < previousDownloads.count ? previousDownloads[i] : 0
                        let upload = i < previousUploads.count ? previousUploads[i] : 0
                        
                        // Calculăm înălțimile
                        let minHeight: CGFloat = 3 // Înălțime minimă pentru vizibilitate
                        let maxHeight = centerY - 3 // Înălțime maximă pentru a evita suprapunerea
                        
                        // Ajustăm scala pentru a obține efectul din imagine - factor mai mare pentru zoom-in
                        let maxDownload = previousDownloads.max() ?? 1
                        let maxUpload = previousUploads.max() ?? 1

                        let scaleDownload = max(download / maxDownload, 0.01) * maxHeight
                        let scaleUpload = max(upload / maxUpload, 0.01) * maxHeight
                        
                        let downloadHeight = download > 0 ? min(max(scaleDownload, minHeight), maxHeight) : 0
                        let uploadHeight = upload > 0 ? min(max(scaleUpload, minHeight), maxHeight) : 0
                        
                        // Calculăm poziția X - barele se desenează de la dreapta la stânga
                        let xPos = width - leftPadding - (columnWidth / 8) - (CGFloat(i) * (columnWidth + spacing))
                        
                        // Desenăm coloana integrată
                        ZStack(alignment: .center) {
                            // Partea de upload (partea de sus)
                            if upload > 0 {
                                // Pentru bare folosim întotdeauna forma de tip capsulă (pill)
                                Capsule()
                                    .fill(uploadColor)
                                    .frame(width: columnWidth, height: uploadHeight)
                                    .position(x: xPos, y: centerY - (uploadHeight / 2))
                            }
                            
                            // Partea de download (partea de jos)
                            if download > 0 {
                                // Pentru bare folosim întotdeauna forma de tip capsulă (pill)
                                Capsule()
                                    .fill(downloadColor)
                                    .frame(width: columnWidth, height: downloadHeight)
                                    .position(x: xPos, y: centerY + (downloadHeight / 2))
                            }
                        }
                    }
                }
            }
            .frame(height: 90)
            .animation(.easeInOut(duration: 0.3), value: downloadSpeeds)
            .animation(.easeInOut(duration: 0.3), value: uploadSpeeds)
            .onAppear {
                // Inițializăm istoricul la prima apariție
                updateHistory()
            }
            .onChange(of: downloadSpeeds) {
                updateHistory()
            }
            .onChange(of: uploadSpeeds) {
                updateHistory()
            }
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
