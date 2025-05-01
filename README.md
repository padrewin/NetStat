![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/padrewin/NetStat/total?logo=files&logoColor=white&label=Downloads&color=red)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/padrewin/NetStat/xcode-build.yml?logo=GitHub&label=GitHub%20Build)

# NetStat

**NetStat** is a sleek macOS menubar app that provides real-time insight into your current internet activity. With an elegant graph and connection awareness, it helps you stay informed about your upload/download performance without bloating your UI or Dock.

<details>
  <summary>Image Gallery</summary>

![CleanShot 2025-05-01 at 03 52 08@2x](https://github.com/user-attachments/assets/d9e8909e-b4fc-44a5-bef4-70cc79cdc68b)

</details>

## Features

- **Minimal Menubar App**  
  Runs as a background utility with no Dock icon.

- **Live Internet Speed Graph**  
  See your current upload/download activity with animated bars and real-time MB/s or KB/s display.

- **Idle Detection**  
  When no traffic is detected, a subtle yellow indicator signals idle state.

- **Offline Mode**  
  If no internet connection is detected, the graph turns red and values display `Offline`.

- **Wi-Fi or Ethernet Detection**  
  Displays current connection type and name (e.g., `Wi-Fi connection` or `Ethernet connection`).

- **Modern macOS Design**  
  Clean blur UI inspired by macOS Control Center, with subtle shadows and rounded corners.

- **Quit from Popup**  
  Easily quit NetStat from within the popup UI.

## Installation

Download the latest `.dmg` release from the [Releases](https://github.com/padrewin/NetStat/releases) page and move the app to `/Applications`.

To keep the app hidden from the Dock and running at login:
- Add it to Login Items in **System Settings > General > Login Items**

### Build from Source

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/padrewin/NetStat.git
   cd NetStat
   open NetStat.xcodeproj
