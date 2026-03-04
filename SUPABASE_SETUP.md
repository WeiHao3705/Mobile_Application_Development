# Supabase Setup Guide for Flutter

## ✅ What Has Been Done

1. **Supabase dependency added** to `pubspec.yaml`
   - `supabase_flutter: ^2.0.0`
   - All dependencies fetched successfully

2. **Supabase initialization** in `main.dart`
   - Configured with error handling
   - Checks connection status on app startup

3. **UI Enhanced** with:
   - Supabase connection status indicator
   - "Save to Supabase" button
   - Integration with counter app

4. **SupabaseService created** (`lib/services/supabase_service.dart`)
   - Centralized database operations
   - Methods for CRUD operations
   - Error handling and logging

---

## 🚀 Getting Started with Supabase

### Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in the project details and create it
5. Wait for the project to initialize (takes a few minutes)

### Step 2: Get Your Credentials

1. In your Supabase project, go to **Settings** → **API**
2. Copy your:
   - **Project URL** (e.g., `https://xxxxxx.supabase.co`)
   - **Anon Key** (public API key)

### Step 3: Update main.dart with Your Credentials

Open `lib/main.dart` and replace:

```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual Supabase credentials:

```dart
const String supabaseUrl = 'https://xxxxxx.supabase.co';
const String supabaseKey = 'your_anon_key_here';
```

### Step 4: Create a Database Table

1. In Supabase console, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste this SQL to create the `counters` table:

```sql
CREATE TABLE counters (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  value INT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE counters ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to insert
CREATE POLICY "Allow inserts" ON counters
  FOR INSERT
  WITH CHECK (true);

-- Create a policy that allows anyone to select
CREATE POLICY "Allow selects" ON counters
  FOR SELECT
  USING (true);

-- Create a policy that allows anyone to update
CREATE POLICY "Allow updates" ON counters
  FOR UPDATE
  USING (true);

-- Create a policy that allows anyone to delete
CREATE POLICY "Allow deletes" ON counters
  FOR DELETE
  USING (true);
```

4. Click "Run" to execute the query

### Step 5: Test the Connection

1. Run your Flutter app: `flutter run`
2. You should see:
   - ✅ "Connected to Supabase" status in the green badge
   - The counter app working normally

3. Click "Save to Supabase" to save your counter value
4. Check the Supabase console → Table Editor → `counters` table to see your saved data!

---

## 📚 Using the SupabaseService

Instead of calling Supabase methods directly, you can use the `SupabaseService` class:

```dart
import 'package:mobile_application_development/services/supabase_service.dart';

final supabaseService = SupabaseService();

// Save a counter
await supabaseService.saveCounter(10);

// Get all counters
final counters = await supabaseService.getAllCounters();

// Get latest counter
final latestValue = await supabaseService.getLatestCounter();

// Update a counter
await supabaseService.updateCounter(1, 20);

// Delete a counter
await supabaseService.deleteCounter(1);
```

---

## 🔒 Security Note

⚠️ **DO NOT commit your credentials to version control!**

For production, use environment variables or a secure configuration file:

```dart
// Example using flutter_dotenv package
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const MyApp());
}
```

---

## 🐛 Troubleshooting

### "Supabase credentials not configured" Error
- Make sure you've replaced `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` in `main.dart`

### "Table 'counters' does not exist" Error
- Run the SQL query from Step 4 to create the table

### Connection Timeout
- Check your internet connection
- Verify your Supabase URL is correct
- Make sure your Supabase project is running

### Row Level Security (RLS) Errors
- Ensure the RLS policies are created as shown in Step 4
- Or temporarily disable RLS for testing (not recommended for production)

---

## 📖 Additional Resources

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/installing)
- [Supabase Getting Started](https://supabase.com/docs/getting-started/quickstarts/flutter)
- [Flutter Documentation](https://flutter.dev/docs)

---

## ✨ Next Steps

1. ✅ Create Supabase account and project
2. ✅ Add your credentials to `main.dart`
3. ✅ Create the `counters` table in Supabase
4. ✅ Run the app and test saving to database
5. 📊 Expand with more database operations
6. 🔐 Implement user authentication (optional)
7. 🚀 Deploy your app

Enjoy building with Flutter + Supabase! 🎉

