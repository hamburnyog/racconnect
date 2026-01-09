# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.3] - 2026-01-09

### Added
- **Year Filtering**: Added year filtering functionality to Holiday, Leave, Suspension, and Travel pages.

### Changed
- **Icon Update**: Changed the travel icon in the sidebar.
- **DTR Generation**: Refactored the excel generation for DTR.

### Fixed
- **Previous Year Issues**: Fixed issues related to fetching data from the previous year.
- **Minor Bugs**: Fixed some minor bugs.

## [1.1.2] - 2025-11-04

### Added
- **Platform-specific Update Links**: Added custom links for iOS, Android, macOS, and Windows platforms for version updates
- **CTO Leave Type**: Added Compensatory Time-off as a specific leave type option
- **Custom Leave Specification**: Added ability to specify custom leave types when selecting "Others"

### Changed
- **Undertime/Late Calculation Logic**: Improved DTR computation algorithm using flexitime system approach - now uses maximum of late or undertime instead of sum to avoid double-penalizing employees
- **Accomplishment Report Export**: Allowed permanent employees to export accomplishment reports with new selection options
- **Dress Code Display**: Improved formatting and layout of uniform/dress code reminder card with better text organization
- **PDF Report Formatting**: Enhanced accomplishment report generation with rich text support for formatting (bullets, newlines) and reduced font size for better page utilization

### Fixed
- **AM PM Arrival on Half Day**: Corrected AM/PM display for half-day attendance
- **OIC Designation**: Fixed wrong designation for Officer-in-Charge in reports
- **Org Chart URL**: Fixed organizational chart URL on Android platform
- **URL Launcher**: Fixed URL launcher functionality issues
- **UI Overflow Issues**: Fixed overflow issues on dress code display

### Security
- **Link Security**: Improved security for platform-specific download links

## [1.1.1] - 2025-10-28

### Added
- **Version Checker**: Implemented version checking functionality to compare current app version with published version in PocketBase
- **Update Notifications**: Added animated banner that appears when a new app version is available with download link
- **Uniform/Dress Code Reminder**: Added expandable card that displays gender-appropriate uniform images and guidelines based on user profile
- **Search Functionality**: Added search fields to Holiday, Leave, Section, Suspension, and Travel pages for improved filtering
- **Password Visibility Toggle**: Added visibility icon to sign-in screen password field
- **Remember Email Checkbox**: Added functionality to remember user's email address on sign-in screen

### Changed
- **DTR Computation**: Multiple improvements to DTR late/undertime calculation algorithms for accurate time tracking
- **iOS Export Fix**: Resolved issues with exporting on newer iOS versions and improved code formatting compliance
- **WFH and BIO Log Handling**: Enhanced processing of Work From Home and Bio logs for accurate attendance tracking
- **Supervisor Designation**: Updated supervisor designation text in accomplishment reports
- **Sign-in Form**: Improved validation and user experience on sign-in screen with minimum 8-character password requirement
- **Code Formatting**: Applied Dart formatting standards across multiple files for consistency
- **Asset Management**: Removed unused orgchart2025 directory and organized image resources

### Fixed
- **Suspension Row Issue**: Resolved issues with suspension display on attendance page
- **Last Day Accomplishment**: Fixed processing of last day accomplishment records
- **OIC Signatory**: Adjusted signatory handling for Officer-in-Charge
- **Warning Messages**: Cleared iOS build warnings and updated Podfile.lock
- **Accomplishment Report**: Fixed bold labels and improved layout in accomplishment reports

### Security
- **Password Validation**: Enhanced sign-in security with minimum 8-character password requirement and improved validation

### Assets
- Added uniform images for both male and female employees
- Added new UI components for version checking and uniform reminders

## [1.1.0] - 2025-08-31

### Added
- **Accomplishment Tracking**: Employees can now log daily targets and accomplishments
- **Leave Management**: Comprehensive leave tracking system with multiple leave types
- **Suspension Management**: System for managing employee suspensions (full-day and half-day)
- **Travel Order Management**: Tracking of employee travel assignments
- **Personnel Directory**: Enhanced employee directory with search and filtering capabilities
- **Time Tampering Detection**: Security feature to detect and prevent time manipulation
- **Enhanced Reporting**: Improved export capabilities including COS-specific reporting periods
- **Profile Management**: Completely redesigned profile system with avatar support and account settings
- **Role-Based Access Control**: More granular permissions with new roles like "Unit Head"
- **Organizational Chart Viewer**: Built-in viewer for organizational structure

### Changed
- **UI/UX Overhaul**: Responsive design improvements, skeleton loading states, and better mobile support
- **Data Models**: Improved data models and repositories for better data management
- **State Management**: Enhanced state management with new cubits for each feature area
- **Error Handling**: Better error handling and user feedback throughout the application

### Security
- **Password Storage**: Enhanced security for password storage in profile management

### Dependencies Added
- pdf: ^3.8.1
- image_picker: ^1.0.0
- yaml: ^3.1.0
- printing: ^5.12.0
- skeletonizer: ^2.1.0+1
- ntp: ^2.0.0

### Dependencies Updated
- flutter_launcher_icons: ^0.14.4

## [1.0.0] - 2025-08-31

### Added
- **Initial Release**: Initial release of the official RACCONNECT App for the Regional Alternative Child Care Office IV-A (RACCO IV-A Calabarzon)
- **Daily Time Records (DTR)**: Generate and download Daily Time Records (DTR) for WFH and on-site attendance
- **Cross-platform Support**: Optimized for both desktop (Windows/macOS) and Android devices
- **Foundation Features**: Serves as the foundation for upcoming modules and expanded features
