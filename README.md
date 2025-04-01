# BookHub

A Flutter application for managing books, transactions, and user interactions.

## Features

- User Authentication (Login/Register)
- Email Verification
- Book Management
- Transaction Tracking
- Category Management
- User Recommendations

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/BookHub.git
```

2. Navigate to the project directory
```bash
cd BookHub
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── models/         # Data models
├── providers/      # State management
├── screens/        # UI screens
├── services/       # API services
└── main.dart       # App entry point
```

## API Endpoints

The app connects to a Laravel backend with the following base URL:
```
http://10.0.2.2:8000/api
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 