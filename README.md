# RACCOnnect

**Regional Alternative Child Care Office IV-A Calabarzon Companion App**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform](https://img.shields.io/badge/platform-windows%20%7C%20macos%20%7C%20android%20%7C%20ios-lightgrey)
![Flutter](https://img.shields.io/badge/flutter-3.0+-blue)

## 📱 Overview

RACConnect is a comprehensive employee management system developed for the **National Authority for Child Care - Regional Alternative Child Care Office IV-A Calabarzon**. The application streamlines attendance tracking, DTR and accomplishment reporting, through a modern, cross-platform interface. 

### 🎯 Key Features
- **Work From Home (WFH) Tracking** 🏠
- **Daily Accomplishment Logging** ✅
- **Personnel Directory** 👥
- **Time Tampering Detection** ⏰
- **Automated Report Generation** 📊
- **Role-Based Access Control** 🔐

## 🖥️ Platform Availability

| Platform | Status | Requirements |
|----------|--------|--------------|
| **Windows** | ✅ Available | Windows 11 or higher |
| **macOS** | ✅ Available | macOS Sonoma or higher |
| **Android** | ✅ Available | Android 11 or higher |
| **iOS** | 🔜 Planned | Future release pending developer subscription |

## 🛠️ Technology Stack

### Frontend
- **Flutter 3+** - Cross-platform UI framework
- **Dart** - Programming language
- **Bloc/Cubit** - State management
- **PocketBase SDK** - Backend integration

### Backend
- **PocketBase** - Backend-as-a-Service
- **Nginx** - Reverse proxy server
- **Docker** - Containerization
- **Let's Encrypt** - SSL certificates

### Infrastructure
- **Ubuntu 24.04 LTS** - Server OS
- **1 vCPU / 1 GiB RAM / 20 GiB Storage**

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Docker (for backend setup)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/racconnect.git
cd racconnect
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the application**
```bash
flutter run
```

## 🔧 Local Development Setup

For local development and testing, you can set up a LAN instance:

### Requirements
- Local PocketBase instance
- Same network connectivity
- Flutter development environment

### Steps
1. Set up PocketBase on your local network
2. Configure the app to connect to your local PocketBase IP (Hardcoded for now)
3. **Note**: Some online functionalities will be unavailable in LAN mode

## 🤝 Contribution

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

### Communication
For contributions, assistance, or inquiries:
- 📧 **Email**: [owen@codecarpentry.com](mailto:owen@codecarpentry.com)
- 📧 **Official**: [wponce@nacc.gov.ph](mailto:wponce@nacc.gov.ph)

## ⚠️ Important Disclaimer

> **Ownership Notice**: This codebase is the property of the **National Authority for Child Care - Regional Alternative Child Care Office IV-A Calabarzon**. The repository serves as a temporary safekeeping solution until an official centralized git server becomes available.

> **License Notice**: While this project is currently under the MIT License, the National Authority for Child Care retains all rights to the codebase and its intellectual property.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**MIT License Summary**:
- ✅ Free to use, modify, and distribute
- ✅ Forking is allowed
- ✅ Commercial use permitted
- ❗ Codebase ownership remains with NACC-RACCO IV-A

## 🛡️ Security Features

- **Time Tampering Detection** - Prevents manipulation of system time
- **Role-Based Access Control** - Granular permissions per user role
- **Encrypted Communications** - SSL/TLS enforced
- **File Upload Validation** - Secure file handling

## 📊 System Requirements

### Server (Minimal)
- **CPU**: 1 vCPU
- **RAM**: 1 GiB
- **Storage**: 20 GiB
- **Bandwidth**: 200 Mbps
- **OS**: Ubuntu 24.04 LTS

### Client
- **Windows**: Windows 11 or higher
- **macOS**: macOS Ventura or higher
- **Android**: Android 10 or higher
- **iOS**: Coming soon™

## 📞 Support

For technical support and inquiries:
- 📧 **Development Support**: [owen@codecarpentry.com](mailto:owen@codecarpentry.com)
- 📧 **Official Inquiries**: [wponce@nacc.gov.ph](mailto:wponce@nacc.gov.ph)

## 🙏 Acknowledgments

- **National Authority for Child Care** - For their continued support
- **Regional Alternative Child Care Office IV-A Calabarzon** - For the opportunity to develop this system
- **Open Source Community** - For the amazing tools and libraries

---

*Made with ❤️ for the dedicated staff of RACCO IV-A Calabarzon* 🇵🇭
