# Lion Circuits (8HRPCB) - Project Specifications

This document outlines the technical specifications, architecture, and feature set of the **Lion Circuits (8HRPCB)** project based on the source code configuration.

## 1. General Project Details
- **App Name**: 8HRPCB (Internal Code Name: `lion_circuits`)
- **Framework**: Flutter
- **Language**: Dart (SDK `^3.12.2`)
- **Primary Platform**: Web/Mobile (Constructed as a scrolling single-page web app layout)
- **Core Domain**: Printed Circuit Board (PCB) Manufacturing Quotation and Visualization.
- **Theme**: Premium Dark Mode UI (`Color(0xFF07070A)`) with Cyan (`#00E5FF`) and Yellow (`#FFD54F`) accents.

## 2. Core Features & Capabilities
### 2.1 Gerber Processing Engine (Local to Client)
The most complex part of the application is the local Dart implementation of a PCB analysis engine.
- **`gerber_parser.dart`**: Parses standard RS-274X Gerber format and Excellon drill files. It reads zip archives to extract and map individual manufacturing layers (copper, soldermask, silkscreen, mechanical, etc.).
- **`gerber_drc_validator.dart`**: Performs Design Rule Checking (DRC). It analyzes the parsed coordinates and flashes to ensure the design is manufacturable (e.g., checking minimum trace widths and clearance gaps).
- **`gerber_renderer.dart`**: Translates the parsed Gerber coordinates into a visual representation using Flutter's custom painting/canvas capabilities or 3D modeling interfaces to render the PCB.

### 2.2 Instant Quotation System
- **`gerber_upload_section.dart`**: A UI component that allows users to drag & drop or select `.zip` archives containing their Gerber files.
- **`quote_result_section.dart`**: A complex UI state that displays the parsed PCB specifications, renders the board visually, presents any DRC warnings, and calculates a final manufacturing cost based on variables like board quantity, surface finish, and copper weight.

### 2.3 Authentication & Backend
- Uses **Firebase** as the backend-as-a-service.
- Supports user login and registration (`auth/login_page.dart`, `auth/signup_page.dart`) managed by `AuthService`.
- Uses Cloud Firestore (`firebase_service.dart`) to presumably store user orders, quotes, or metadata.

## 3. Application Architecture (Directory Structure)
The `lib/` directory employs a feature-first architectural split:

- `lib/main.dart` - Entry point and main UI layout orchestrator (scrolling single-page application).
- `lib/auth/` - Screens and controllers for Firebase Authentication.
- `lib/config/` - Environment variables and API configurations (`api_config.dart`, `firebase_options.dart`).
- `lib/sections/` - The modular UI blocks comprising the website:
  - `hero_section.dart` (Top banner)
  - `about_us_section.dart`
  - `services_section.dart`
  - `why_choose_us_section.dart`
  - `process_section.dart`
  - `testimonials_section.dart`
  - `contact_section.dart`
  - `gerber_upload_section.dart` (Upload UI)
  - `quote_result_section.dart` (Calculations & results UI)
  - `footer_section.dart`
- `lib/services/` - External integrations:
  - `firebase_service.dart` (Firestore database)
  - `gerber_api_service.dart` (External backend fallback for Gerber parsing)
  - `local_storage_*.dart` (Cross-platform persistent storage implementations)
- `lib/utils/` - Core logic engines:
  - `gerber_parser.dart`
  - `gerber_renderer.dart`
  - `gerber_drc_validator.dart`
  - `password_validator.dart`

## 4. Third-Party Dependencies
Defined in `pubspec.yaml`:
- **UI & Theming**: `cupertino_icons` (^1.0.8), `google_fonts` (^8.1.0)
- **File & Archive Handling**: `file_picker` (^11.0.2), `archive` (^4.0.9) - Used to open and extract user Gerber `.zip` files.
- **Network & Cryptography**: `http` (^1.6.0), `crypto` (^3.0.3)
- **Visuals**: `model_viewer_plus` (^1.10.0) - Likely used in conjunction with the Gerber renderer to show a 3D view of the PCB.
- **Firebase Services**:
  - `firebase_core` (^4.12.1)
  - `firebase_auth` (^6.5.6)
  - `cloud_firestore` (^6.7.1)
