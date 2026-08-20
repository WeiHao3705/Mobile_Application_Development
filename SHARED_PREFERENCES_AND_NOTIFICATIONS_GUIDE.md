# SharedPreferences Search History & Notification System Guide

## Table of Contents
1. [Overview](#overview)
2. [SharedPreferences - Food Search History](#sharedpreferences---food-search-history)
3. [Notification System](#notification-system)

---

## Overview

This guide explains two key features of the Mobile Application Development fitness app:
- **SearchHistoryService**: Manages user search history using SharedPreferences for persistent local storage
- **NotificationService**: Handles daily meal reminders using Flutter Local Notifications

---

## SharedPreferences - Food Search History

### What is SharedPreferences?

SharedPreferences is a lightweight, persistent key-value data storage system provided by Flutter. It stores data locally on the device and persists even after the app is closed. It's ideal for storing small amounts of data like user preferences, settings, and search history.

**Key Characteristics:**
- ✅ Persists data after app restart
- ✅ Fast local access (no network required)
- ✅ Simple key-value storage
- ✅ Device-specific storage
- ✅ Limited to small data sizes (not suitable for large datasets)

### SearchHistoryService Implementation

The `SearchHistoryService` class manages meal search history stored in SharedPreferences.

**File Location:** `lib/services/search_history_service.dart`

#### Storage Structure

```dart
static const String _searchHistoryKey = 'meal_search_history';
static const int _maxHistoryItems = 10;
```

- **Storage Key**: `'meal_search_history'` - The unique identifier for search history in SharedPreferences
- **Maximum Items**: `10` - Stores up to the 10 most recent searches

#### Key Methods

##### 1. **addSearchQuery(String query)**

Saves a search query to the history, maintaining most-recent-first ordering.

**How it works:**
```dart
Future<void> addSearchQuery(String query) async {
  if (query.trim().isEmpty) return;  // Skip empty queries
  
  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];
  
  // Remove duplicate if it exists (to move it to the top)
  history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
  
  // Insert at the beginning (most recent first)
  history.insert(0, query.trim());
  
  // Keep only the latest 10 items
  if (history.length > _maxHistoryItems) {
    history = history.sublist(0, _maxHistoryItems);
  }
  
  // Save back to SharedPreferences
  await prefs.setStringList(_searchHistoryKey, history);
}
```

**Example Flow:**
```
1. User searches for "Chicken"
   history = ['Chicken']

2. User searches for "Rice"
   history = ['Rice', 'Chicken']

3. User searches for "Chicken" again
   history = ['Chicken', 'Rice']  // Moved to top

4. After 10 searches, new ones push old ones out
   history contains only the latest 10 searches
```

##### 2. **getSearchHistory()**

Retrieves all saved search queries from SharedPreferences.

```dart
Future<List<String>> getSearchHistory() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_searchHistoryKey) ?? [];
}
```

**Returns:** List of search queries in chronological order (most recent first)

##### 3. **clearSearchHistory()**

Deletes all search history from SharedPreferences.

```dart
Future<void> clearSearchHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_searchHistoryKey);
}
```

##### 4. **removeSearchQuery(String query)**

Removes a specific search query from history.

```dart
Future<void> removeSearchQuery(String query) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];
  
  // Remove the query (case-insensitive)
  history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
  
  // If history is empty, remove the key entirely
  if (history.isEmpty) {
    await prefs.remove(_searchHistoryKey);
  } else {
    // Save the updated history
    await prefs.setStringList(_searchHistoryKey, history);
  }
}
```

### Integration in UI

The search history is integrated into the `AddNewMealPage` widget:

#### 1. **Loading Search History**

```dart
Future<void> _loadSearchHistory() async {
  final history = await _searchHistoryService.getSearchHistory();
  setState(() {
    _searchHistory = history;
  });
}
```

Called in `initState()` to load history when the page opens.

#### 2. **Displaying Search History Dropdown**

When the user clears the search field and has search history:
```dart
if (_showSearchHistory && _searchHistory.isNotEmpty)
  Container(
    // Shows list of previous searches
    child: ListView.builder(
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final query = _searchHistory[index];
        return GestureDetector(
          onTap: () => _selectSearchHistoryItem(query),
          child: /* History item UI */
        );
      },
    ),
  )
```

#### 3. **Selecting from History**

```dart
Future<void> _selectSearchHistoryItem(String query) async {
  setState(() {
    _searchCtrl.text = query;
    _searchQuery = query;
    _showSearchHistory = false;
  });
  
  // Re-save to history (moves to top)
  await _searchHistoryService.addSearchQuery(query);
  await _loadSearchHistory();
}
```

#### 4. **Saving New Searches**

```dart
onSubmitted: (value) async {
  if (value.trim().isNotEmpty) {
    await _searchHistoryService.addSearchQuery(value.trim());
    await _loadSearchHistory();
  }
}
```

#### 5. **Filtering Search History Based on User Input (NEW FEATURE)**

A new helper method `_getFilteredSearchHistory()` filters the search history based on the user's current input:

```dart
/// Get filtered search history based on current search input
List<String> _getFilteredSearchHistory() {
  final input = _searchCtrl.text.trim().toLowerCase();
  
  if (input.isEmpty) {
    return _searchHistory;  // Show all history if input is empty
  }
  
  // Filter history items that contain the user input (case-insensitive)
  return _searchHistory
      .where((item) => item.toLowerCase().contains(input))
      .toList();
}
```

**How it works:**
- As the user types in the search field, the history dropdown automatically filters to show only matching results
- **Empty input** → Shows all search history
- **With input** → Shows only history items that contain the user's input (case-insensitive)
- The filtered results appear in real-time as the user types

**Example:**
```
User's Search History:
['Chicken Breast', 'Rice', 'Broccoli', 'Chicken Thigh', 'Brown Rice']

User types "chick":
Filtered Results:
├─ Chicken Breast
└─ Chicken Thigh

User types "rice":
Filtered Results:
├─ Rice
└─ Brown Rice

User clears input:
All Results:
├─ Chicken Breast
├─ Rice
├─ Broccoli
├─ Chicken Thigh
└─ Brown Rice
```

#### 6. **Real-time Search History Display**

The search bar now dynamically updates the history dropdown as the user types:

```dart
TextField(
  controller: _searchCtrl,
  onChanged: (v) {
    setState(() {
      _searchQuery = v;
      // Show search history if field is empty or has matching history
      final input = v.trim().toLowerCase();
      final hasRelevantHistory = _searchHistory.any(
        (item) => item.toLowerCase().contains(input) || input.isEmpty
      );
      _showSearchHistory = hasRelevantHistory && _searchHistory.isNotEmpty;
    });
  },
  // ... rest of TextField configuration
)
```

The condition `_showSearchHistory && _getFilteredSearchHistory().isNotEmpty` ensures:
- History dropdown is shown only when there are matching results
- Automatically hides when no matches are found
- Shows all history when input field is empty

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    User Actions                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
                    ┌──────────────┐
                    │ Search Food  │
                    └──────────────┘
                           ↓
    ┌────────────────────────────────────────────────┐
    │     User Typing / Entering Search Text         │
    └────────────────────────────────────────────────┘
                           ↓
    ┌────────────────────────────────────────────────┐
    │  _onSearchChanged() Called on Each Keystroke   │
    └────────────────────────────────────────────────┘
                           ↓
    ┌────────────────────────────────────────────────────────┐
    │   _getFilteredSearchHistory() Filters Results:         │
    │   • If input empty → Show all history                 │
    │   • If input has text → Show matching items only      │
    │   • Case-insensitive matching                         │
    └────────────────────────────────────────────────────────┘
                           ↓
    ┌────────────────────────────────────────────────┐
    │   Has Matching Results?                        │
    └────────────────────────────────────────────────┘
         YES ↓                               ↓ NO
        Display                            Hide
      Filtered                          Dropdown
      Dropdown
         ↓
    ┌──────────────┐
    │ User Selects │
    │ From History │
    └──────────────┘
         ↓
    ┌──────────────────────┐
    │ Search Applied       │
    │ Query Moved to Top   │
    │ of History           │
    └──────────────────────┘
         ↓
    ┌──────────────────────┐
    │ Persist in           │
    │ SharedPreferences    │
    └──────────────────────┘
```

### Use Cases

| Scenario | Method Used | Result |
|----------|------------|--------|
| User types and submits search | `addSearchQuery()` | New search saved, moved to top if duplicate |
| User opens Add Meal page | `getSearchHistory()` | Previous searches displayed in dropdown |
| User clicks historical search | `addSearchQuery()` + `getSearchHistory()` | Search applied and moved to top |
| User removes a search | `removeSearchQuery()` | Single item removed from history |
| User wants fresh start | `clearSearchHistory()` | All history deleted |

---

## Notification System

### Overview

The `NotificationService` manages daily meal reminders to remind users to log their breakfast, lunch, and dinner. It uses **Flutter Local Notifications** plugin with **timezone** support to send scheduled notifications at specific times.

**File Location:** `lib/services/notification_service.dart`

### Key Features

- ✅ **Daily Reminders**: Automatically sends notifications at scheduled times
- ✅ **Smart Logic**: Only sends reminders for meals NOT yet logged
- ✅ **Timezone Support**: Set to Malaysia timezone (Asia/Kuala_Lumpur)
- ✅ **Android & iOS Support**: Works on both platforms
- ✅ **Exact Timing**: Uses exact alarm scheduling
- ✅ **Permission Handling**: Requests necessary permissions

### Initialization

#### 1. **init() Method**

Called once when the app starts to set up notifications.

```dart
static Future<void> init() async {
  try {
    tz.initializeTimeZones();
    
    // Set timezone to Malaysia
    final malaysiaTimeZone = tz.getLocation('Asia/Kuala_Lumpur');
    tz.setLocalLocation(malaysiaTimeZone);
    
    // Configure Android and iOS settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(android: android, iOS: ios);
    
    // Initialize with notification tap handler
    await _notifications.initialize(settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
    
    // Request Android 13+ permissions
    final android_plugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (android_plugin != null) {
      await android_plugin.requestNotificationsPermission();
    }
  } catch (e) {
    developer.log('Error initializing notifications: $e');
  }
}
```

**Setup Steps:**
1. Initialize timezone system
2. Set local timezone to Malaysia
3. Configure Android notification icon
4. Configure iOS notification permissions
5. Initialize FlutterLocalNotificationsPlugin
6. Request Android 13+ notification permission

### Main Methods

#### 1. **scheduleDailyNotifications(String? userId)**

The main entry point for scheduling daily meal reminders.

```dart
static Future<void> scheduleDailyNotifications(String? userId) async {
  try {
    // Skip if user not logged in
    if (userId == null) {
      developer.log('User not logged in, skipping notification scheduling');
      return;
    }
    
    // Determine which meals are missing
    final missingMeals = await _getMissingMeals(userId);
    
    if (missingMeals.isEmpty) {
      // All meals logged today
      developer.log('User already logged all meals today');
      return;
    }
    
    // Schedule notifications only for missing meals
    if (missingMeals.contains('breakfast')) {
      await _scheduleDaily(0, 9, 0, 'Breakfast Reminder', 
        '🥣 Good morning! Don\'t forget your breakfast.');
    }
    
    if (missingMeals.contains('lunch')) {
      await _scheduleDaily(1, 13, 0, 'Lunch Reminder', 
        '🍽️ Lunch time! Have you logged your meal yet?');
    }
    
    if (missingMeals.contains('dinner')) {
      await _scheduleDaily(2, 19, 0, 'Dinner Reminder', 
        '🍖 Dinner time! Don\'t forget to log your meal.');
    }
  } catch (e) {
    developer.log('Error scheduling notifications: $e');
  }
}
```

**Reminder Times:**
- **Breakfast**: 9:00 AM
- **Lunch**: 1:00 PM (13:00)
- **Dinner**: 7:00 PM (19:00)

#### 2. **_getMissingMeals(String userId)**

Queries the database to determine which meals haven't been logged today.

```dart
static Future<List<String>> _getMissingMeals(String userId) async {
  try {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startOfDayIso = startOfDay.toIso8601String();
    final endOfDayIso = startOfDay.add(const Duration(days: 1)).toIso8601String();
    
    // Query MealLog table for today's meals
    final response = await Supabase.instance.client
        .from('MealLog')
        .select('meal_type')
        .eq('user_id', userId)
        .gte('meal_date', startOfDayIso)
        .lt('meal_date', endOfDayIso);
    
    // Extract meal types that were logged
    final loggedMealTypes = (response as List)
        .map((meal) => (meal['meal_type'] as String).toLowerCase())
        .toList();
    
    // Find missing meals
    final mealsToTrack = ['breakfast', 'lunch', 'dinner'];
    final missing = mealsToTrack
        .where((meal) => !loggedMealTypes.contains(meal))
        .toList();
    
    return missing;
  } catch (e) {
    developer.log('Error checking missing meals: $e');
    // Default to all meals if error (send all notifications)
    return ['breakfast', 'lunch', 'dinner'];
  }
}
```

**Database Query:**
- Fetches all meal logs for the current user
- Filters for meals logged **today**
- Compares against the standard meals (breakfast, lunch, dinner)
- Returns only the missing ones

#### 3. **_scheduleDaily(int id, int hour, int minute, String title, String body)**

Schedules a single daily notification at a specific time.

```dart
static Future<void> _scheduleDaily(
    int id, int hour, int minute, String title, String body) async {
  try {
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    
    await _notifications.zonedSchedule(
      id,  // Notification ID
      title,  // Notification title
      body,   // Notification body
      scheduledTime,  // When to trigger
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          channelDescription: 'Daily nutrition reminders',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: 
        UILocalNotificationDateInterpretation.absoluteTime,
    );
  } catch (e) {
    developer.log('Error scheduling notification $id: $e');
  }
}
```

**Parameters:**
- `id`: Unique identifier (0=breakfast, 1=lunch, 2=dinner)
- `hour` & `minute`: Time in 24-hour format
- `title` & `body`: Notification content
- `androidScheduleMode`: Exact scheduling even if device is in low power mode

#### 4. **_nextInstanceOfTime(int hour, int minute)**

Calculates the next occurrence of a specific time.

```dart
static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final location = tz.getLocation('Asia/Kuala_Lumpur');
  final now = tz.TZDateTime.now(location);
  
  // Create scheduled time for today
  var scheduled = tz.TZDateTime(location, now.year, now.month, 
    now.day, hour, minute);
  
  // If time has passed, schedule for tomorrow
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  
  return scheduled;
}
```

**Logic:**
- Creates a TZDateTime for today at the specified time
- If that time has already passed, schedules for tomorrow instead
- Ensures notifications are never scheduled in the past

### Notification Timing

```
Today's Schedule (Malaysia Time):
├─ 09:00 → Breakfast Reminder (if not logged)
├─ 13:00 → Lunch Reminder (if not logged)
└─ 19:00 → Dinner Reminder (if not logged)

If time has passed today:
→ Reschedule for tomorrow
```

### Database Integration

The system queries the **MealLog** table structure:

```
MealLog Table:
├── user_id (INT) - User identifier
├── meal_type (TEXT) - 'Breakfast', 'Lunch', 'Dinner', 'Snacks'
├── meal_date (TIMESTAMP) - When the meal was logged
└── ... (other meal fields)
```

### Debug Methods

#### 1. **showTestNotification()**

Displays a test notification immediately (useful for debugging).

```dart
static Future<void> showTestNotification() async {
  await _notifications.show(
    999,
    'Test Notification',
    'This notification should appear immediately!',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}
```

#### 2. **debugPendingNotifications()**

Lists all pending notifications for debugging.

```dart
static Future<void> debugPendingNotifications() async {
  final pending = await _notifications.pendingNotificationRequests();
  for (var notif in pending) {
    developer.log('Pending: ID=${notif.id}, Title=${notif.title}');
  }
}
```

#### 3. **cancelAllNotifications()**

Cancels all scheduled notifications.

```dart
static Future<void> cancelAllNotifications() async {
  await _notifications.cancelAll();
  developer.log('All notifications cancelled');
}
```

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   App Launch / Login                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
         ┌────────────────────────────────┐
         │ Call init() to setup           │
         │ notifications system           │
         └────────────────────────────────┘
                           ↓
    ┌─────────────────────────────────────────┐
    │ scheduleDailyNotifications(userId)      │
    └─────────────────────────────────────────┘
                           ↓
    ┌─────────────────────────────────────────┐
    │ Query: Which meals logged today?        │
    │ (Database: MealLog table)               │
    └─────────────────────────────────────────┘
                           ↓
    ┌──────────────────────────────────────────────────┐
    │ Determine Missing Meals                          │
    │ (breakfast, lunch, dinner not yet logged)        │
    └──────────────────────────────────────────────────┘
                           ↓
    ┌──────────────────────────────────────────────────┐
    │ For Each Missing Meal: _scheduleDaily()          │
    │ • Calculate next occurrence of reminder time     │
    │ • Register with system notification service     │
    │ • Set to trigger at exact time                  │
    └──────────────────────────────────────────────────┘
                           ↓
    ┌──────────────────────────────────────────────────┐
    │ Scheduled Notifications Active Until:            │
    │ • Meal is logged (then remove notification)     │
    │ • Day ends (then run again tomorrow)            │
    │ • User explicitly cancels                       │
    └──────────────────────────────────────────────────┘
                           ↓
              ┌────────────────────────┐
              │ At Scheduled Time:     │
              │ Show Notification      │
              │ User can tap to open   │
              └────────────────────────┘
```

### Configuration Reference

```dart
// Notification Channels (Android)
daily_channel: 'Daily Reminders' - Main notification channel

// Reminder Times (Malaysia Time - Asia/Kuala_Lumpur)
Breakfast: 09:00
Lunch:     13:00
Dinner:    19:00

// History Limit (for search functionality)
Max History Items: 10
Storage Key: 'meal_search_history'

// Notification IDs
0: Breakfast
1: Lunch
2: Dinner
999: Test Notification
```

### Best Practices

#### For Notifications:
1. ✅ Always check if user is logged in before scheduling
2. ✅ Handle timezone differences for global apps
3. ✅ Check which meals are missing before sending reminders
4. ✅ Cancel notifications when meal is logged
5. ✅ Use test notifications during development

#### For Search History:
1. ✅ Limit history to prevent excessive storage
2. ✅ Make duplicates move to top (most recent first)
3. ✅ Clear history when switching users
4. ✅ Allow manual removal of specific searches
5. ✅ Handle empty/trimmed queries

---

## Troubleshooting

### Notifications Not Appearing?

**Possible Causes & Solutions:**
1. **Check Permissions**: Ensure `POST_NOTIFICATIONS` permission is granted (Android 13+)
2. **Check Timezone**: Verify Malaysia timezone is set correctly
3. **Debug Mode**: Use `debugPendingNotifications()` to verify scheduled notifications
4. **Test First**: Call `showTestNotification()` to test basic functionality
5. **Check Database**: Verify MealLog table has today's meal entries

### Search History Not Persisting?

**Possible Causes & Solutions:**
1. **SharedPreferences Issue**: Ensure `shared_preferences` package is installed
2. **Empty Queries**: Verify non-empty queries are being saved
3. **Storage Limits**: Check device storage isn't full
4. **Clear Cache**: Try clearing app cache and try again
5. **Test Save**: Call `addSearchQuery()` and then `getSearchHistory()` to debug

### Time Zone Issues?

**Solution:**
The system uses Malaysia timezone (`Asia/Kuala_Lumpur`). To change:

```dart
final newTimeZone = tz.getLocation('America/New_York');  // Or desired timezone
tz.setLocalLocation(newTimeZone);
```

---

## Summary

| Feature | Storage | Persistence | Purpose |
|---------|---------|-------------|---------|
| **Search History** | SharedPreferences | Yes (survives app restart) | Improve UX by suggesting previous searches |
| **Notifications** | System Scheduler | Yes (until triggered) | Remind users to log meals at scheduled times |

Both systems work together to create a more engaging and user-friendly fitness tracking experience!



