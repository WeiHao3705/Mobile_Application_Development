# Fitness App - UI Structure

## Overview
This fitness tracking app has been restructured with a clean navigation system and theming support.

## App Structure

### Main Navigation (`lib/views/main_navigation.dart`)
- Bottom navigation bar with 4 tabs:
  - **Home** - Dashboard with activity stats
  - **Exercise** - Placeholder (ready for teammate implementation)
  - **Diet** - Placeholder (ready for teammate implementation)
  - **Profile** - User profile and settings

### Pages

#### 1. Home Page (`lib/views/home_page.dart`)
Features:
- Welcome message
- Daily activity stats (Calories, Steps, Workouts)
- Quick action cards (Start Workout, Log Meal)
- Recent workouts list

#### 2. Profile Page (`lib/views/profile_page.dart`)
Features:
- User profile header with avatar
- Personal stats (Weight, Height, BMI)
- Fitness goals section
- Account settings options
- Logout functionality

#### 3. Exercise & Diet Pages
Currently showing placeholder screens with "Coming soon..." message.
These are ready for your teammates to implement.

## Theming

### Color System (`lib/theme/app_colors.dart`)
- **Primary**: #EBFF45 (Yellow-green)
- **Secondary**: #896CFE (Purple)
- **Tertiary**: #B3A0FF (Light purple) - Used for bottom nav
- Light/Dark backgrounds and text colors defined

### Theme Files
- `lib/theme/app_theme.dart` - Defines light and dark themes
- Supports automatic system theme switching
- All UI components use theme colors (no hardcoded colors)

### Dark Mode Support
The app automatically switches between light and dark themes based on system settings:
```dart
themeMode: ThemeMode.system,
```

To test dark mode:
- Change your device/emulator to dark mode
- The app will automatically adapt

## Adding New Features

### For Exercise Tab
Edit `lib/views/main_navigation.dart` and replace:
```dart
const _PlaceholderPage(title: 'Exercise'),
```
with your exercise page widget.

### For Diet Tab
Replace:
```dart
const _PlaceholderPage(title: 'Diet'),
```
with your diet page widget.

## Design Guidelines

### Using Theme Colors
Always use theme colors instead of hardcoded colors:

```dart
// ✅ Good - Uses theme color
color: theme.colorScheme.primary

// ❌ Bad - Hardcoded color
color: Color(0xFFEBFF45)
```

### Common Theme Properties
```dart
theme.colorScheme.primary      // Yellow-green
theme.colorScheme.secondary    // Purple
theme.colorScheme.tertiary     // Light purple
theme.scaffoldBackgroundColor  // Background
theme.textTheme.bodyMedium     // Default text style
```

## Running the App

```bash
flutter run
```

The app will start with the Home tab selected and fully functional navigation.

## Next Steps

1. **Exercise Tab**: Add workout tracking, exercise library, workout plans
2. **Diet Tab**: Add meal logging, calorie tracking, nutrition info
3. **Backend Integration**: Connect to Supabase for data persistence
4. **User Authentication**: Add login/signup flow
5. **Data Models**: Create models for User, Workout, Meal, etc.

## File Structure
```
lib/
├── config/
│   └── supabase_config.dart
├── controllers/
│   └── user_controller.dart
├── models/
│   └── app_user.dart
├── services/
│   ├── supabase_service.dart
│   └── user_repository.dart
├── theme/
│   ├── app_colors.dart
│   └── app_theme.dart
├── views/
│   ├── home_page.dart
│   ├── main_navigation.dart
│   ├── profile_page.dart
│   └── user_list_view.dart
└── main.dart
```

