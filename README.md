# My Portfolio

A modern web portfolio application built with Flutter, showcasing my projects, skills, and professional experience.

## Features

- **Web-optimized**: Responsive design built for modern web browsers
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
- VS Code with Flutter extensions
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
   # - firebase.json (automatically ignored by git)
   ```

4. Run the web application:
   ```bash
   flutter run -d chrome
   ```

### Firebase Setup

This project uses Firebase for backend services. To set up your own Firebase project:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Enable the services you need (Firestore, Authentication, etc.)
4. Run `flutterfire configure` to generate the configuration file
5. The generated `firebase_options.dart` file will be automatically added to `.gitignore`

### Database Setup (Firestore)

This portfolio uses Firestore to store project data and about information. You'll need to create the following collections and documents:

#### 1. Create Collections

In your Firebase Console, go to **Firestore Database** and create these collections:

- `static` - Contains static content like about information
- `projects` - Contains individual project documents

#### 2. Static Collection - About Document

Create a document with ID `about` in the `static` collection:

```json
{
  "avatar": "https://your-avatar-url.com/image.jpg",
  "bio": "Your professional bio and introduction text",
  "mainSkills": [
    "Flutter",
    "Dart", 
    "Firebase",
    "UI/UX Design"
  ],
  "skillCategories": [
    {
      "name": "Frontend Development",
      "skills": ["Flutter", "Dart", "React", "JavaScript", "TypeScript"]
    },
    {
      "name": "Backend Development", 
      "skills": ["Firebase", "Node.js", "Python", "PostgreSQL"]
    },
    {
      "name": "Design",
      "skills": ["UI/UX Design", "Figma", "Adobe Creative Suite", "Prototyping"]
    }
  ]
}
```

#### 3. Projects Collection

Create individual documents for each project. Use any document ID (e.g., `project-1`, `my-flutter-app`, etc.):

```json
{
  "title": "Project Name",
  "description": "Detailed description of your project, what it does, and why you built it.",
  "techStack": [
    "Flutter",
    "Firebase", 
    "Dart",
    "Material Design"
  ],
  "screenshots": [
    "https://your-domain.com/screenshot1.jpg",
    "https://your-domain.com/screenshot2.jpg",
    "https://your-domain.com/screenshot3.jpg"
  ],
  "background": "#FF6B6B",
  "foreground": "#FFFFFF"
}
```

**Color Format**: Use hex color codes (e.g., `#FF6B6B` for background, `#FFFFFF` for foreground text)

#### 4. Security Rules

Set up Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to all documents
    match /{document=**} {
      allow read: if true;
    }
    
    // Only allow authenticated users to write
    match /{document=**} {
      allow write: if request.auth != null;
    }
  }
}
```

#### 5. Sample Data

Here's a complete example of what your Firestore should look like:

**Collection: `static`**
- Document: `about` (with the JSON structure above)

**Collection: `projects`**  
- Document: `portfolio-app` (with project JSON structure above)
- Document: `ecommerce-mobile` (another project)
- Document: `weather-app` (another project)

#### 6. Testing Your Setup

After setting up the database, run the app to verify everything works:

```bash
flutter run -d chrome
```

The app should successfully load your about information and display your projects.

### Building for Production

Build the web application for production:

```bash
flutter build web --release
```

The built files will be in the `build/web` directory, ready for deployment to any web hosting service.

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

- **Flutter Web**: Modern web UI framework
- **Dart**: Programming language
- **Firebase**: Backend services and database
- **Custom Animations**: Rive animations and custom Flutter animations

## About This Project

This portfolio showcases my development skills and projects. It's built with Flutter Web to demonstrate my ability to create modern web applications with excellent UI/UX design principles.

The application includes:
- Interactive project showcases
- Smooth animations and transitions
- Responsive design for all screen sizes
- Custom widgets and components
- Clean, maintainable code architecture
- Optimized web performance

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **GitHub**: [theogrillat](https://github.com/theogrillat)

## Acknowledgments

- Flutter team for the amazing framework
