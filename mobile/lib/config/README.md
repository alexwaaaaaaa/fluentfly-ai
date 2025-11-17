# FluentFly Theme and Configuration

This directory contains the theme configuration and constants for the FluentFly mobile application.

## Files

### theme.dart
Defines the complete theme system for the app including:
- **Brand Colors**: Primary (#00BFFF Sky Blue), Accent (#39FF14 Neon Green), Dark Background (#0A0E12)
- **Gradients**: Primary gradient (145deg linear), card gradient, success gradient
- **Typography**: Inter/Poppins font family with various weights
- **Component Themes**: AppBar, Card, Buttons, Input fields, etc.
- **Dark Theme**: Complete dark theme configuration (default)
- **Light Theme**: Complete light theme configuration

### constants.dart
Application-wide constants including:
- API configuration (base URL, timeouts)
- Cache settings (TTL, max cached items)
- Audio configuration (sample rate, format, bitrate)
- Gamification values (XP amounts, bonuses)
- UI constants (padding, border radius, elevation)
- Storage keys
- Error and success messages

## Usage

### Using Theme Colors

```dart
import 'package:mobile/config/theme.dart';

// Use predefined colors
Container(
  color: AppTheme.primaryColor,
  child: Text(
    'Hello',
    style: TextStyle(color: AppTheme.textPrimary),
  ),
)

// Use gradients
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### Using Theme from Context

```dart
// Access theme colors
final primaryColor = Theme.of(context).colorScheme.primary;
final textColor = Theme.of(context).textTheme.bodyLarge?.color;

// Use theme text styles
Text(
  'Title',
  style: Theme.of(context).textTheme.displayLarge,
)
```

### Toggling Theme

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/theme_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    return IconButton(
      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        ref.read(themeProvider.notifier).toggleTheme();
      },
    );
  }
}
```

### Using Constants

```dart
import 'package:mobile/config/constants.dart';

// API configuration
final apiUrl = AppConstants.apiBaseUrl;
final timeout = AppConstants.apiTimeout;

// Gamification
final xp = AppConstants.xpPerCorrectAnswer;

// UI
final padding = AppConstants.defaultPadding;
final borderRadius = AppConstants.defaultBorderRadius;
```

## Theme Persistence

The theme preference is automatically saved to SharedPreferences and restored on app launch. Users' theme choice persists across app restarts.

## Customization

To customize the theme:

1. Edit colors in `theme.dart`
2. Modify component themes as needed
3. Update gradients for different visual effects
4. Adjust typography settings

The theme system uses Material 3 (useMaterial3: true) for modern design patterns.
