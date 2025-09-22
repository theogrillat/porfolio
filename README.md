# My Portfolio

A modern, cross-platform portfolio application built with Flutter, showcasing my projects, skills, and professional experience.

## Features

- **Cross-platform**: Runs on iOS, Android, Web, macOS, Windows, and Linux
- **Modern UI**: Clean, responsive design with smooth animations
- **Project Showcase**: Display my work with detailed project information
- **Interactive Elements**: Engaging user interactions and hover effects
- **Responsive Design**: Optimized for all screen sizes and devices

## Screenshots

*Add screenshots of my portfolio here*

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Xcode (for iOS development)
- Chrome (for web development)
- Firebase project setup

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/theogrillat/portfolio.git
   cd portfolio
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. **Set up Firebase configuration:**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase (generates all necessary config files)
   flutterfire configure
   
   # This will create:
   # - lib/firebase_options.dart
   # - android/app/google-services.json
   # - ios/Runner/GoogleService-Info.plist
   # - macos/Runner/GoogleService-Info.plist
   ```

4. Run the application:
   ```bash
   flutter run
   ```

### Firebase Setup

This project uses Firebase for backend services. To set up your own Firebase project:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Enable the services you need (Firestore, Authentication, etc.)
4. Run `flutterfire configure` to generate the configuration file
5. The generated `firebase_options.dart` file will be automatically added to `.gitignore`

### Building for Production

#### Web
```bash
flutter build web --release
```

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Desktop
```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── about.dart
│   └── project.dart
├── services/                 # Business logic
│   └── db.dart
├── shared/                   # Shared utilities
│   ├── grid.dart
│   └── styles.dart
├── views/                    # Screen components
│   ├── about/
│   ├── home/
│   ├── mouse/
│   └── project/
└── widgets/                  # Reusable UI components
    ├── animated_skew.dart
    ├── boxbutton.dart
    ├── cloud/
    ├── decrypted_text.dart
    ├── forge.dart
    ├── hover.dart
    ├── md_viewer.dart
    └── pressure_text.dart
```

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Firebase**: Backend services (if applicable)
- **Custom Animations**: Rive animations and custom Flutter animations

## About This Project

This portfolio showcases my development skills and projects. It's built with Flutter to demonstrate my ability to create cross-platform applications with modern UI/UX design principles.

The application includes:
- Interactive project showcases
- Smooth animations and transitions
- Responsive design for all devices
- Custom widgets and components
- Clean, maintainable code architecture

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **GitHub**: [theogrillat](https://github.com/theogrillat)
- **Email**: [Add your email here]
- **LinkedIn**: [Add your LinkedIn profile here]
- **Portfolio**: [Add your live portfolio URL here]

## Acknowledgments

- Flutter team for the amazing framework
- Contributors and open source community
- Design inspiration from modern portfolio websites
