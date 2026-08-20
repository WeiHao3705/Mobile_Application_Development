# Nutrition Analysis Guide

## Overview

The Nutrition Analysis feature provides comprehensive tracking and visualization of nutritional data across three time periods: **Daily**, **Weekly**, and **Monthly**. Users can monitor their calorie intake, macro distribution, and progress toward their nutrition goals.

---

## Table of Contents

1. [Libraries & Dependencies](#libraries--dependencies)
2. [Architecture Overview](#architecture-overview)
3. [Daily Analysis](#daily-analysis)
4. [Weekly Analysis](#weekly-analysis)
5. [Monthly Analysis](#monthly-analysis)
6. [UI Components](#ui-components)
7. [Data Models](#data-models)
8. [Code Implementation](#code-implementation)

---

## Libraries & Dependencies

This project uses the following libraries and frameworks for visualization and data handling:

### Charting & Visualization Libraries

#### 1. **CustomPaint (Flutter Built-in)**
- **Purpose**: Creating custom donut charts and line charts
- **Library**: `flutter:ui` (Part of Flutter SDK)
- **Usage**:
  - `CustomPaint` widget with custom `CustomPainter` classes
  - `_DonutChartPainter`: Renders macro distribution donut charts
  - `_CalorieChartPainter`: Renders weekly calorie trend line charts
- **Why Used**: Provides full control over chart appearance and enables smooth animations and interactions
- **No External Dependency Required**: Built into Flutter framework

#### 2. **fl_chart (Flutter Package)**
- **Purpose**: Pre-built charting components for advanced analytics (optional alternative)
- **Library**: `fl_chart` package
- **Features**:
  - Line charts with smooth curves
  - Pie/Donut charts
  - Bar charts
  - Animated transitions
- **Installation**: Add to `pubspec.yaml`:
  ```yaml
  dependencies:
    fl_chart: ^0.65.0
  ```
- **Note**: Current implementation uses CustomPaint, but fl_chart can be used for enhanced chart features

#### 3. **charts_flutter (Google Charts for Flutter)**
- **Purpose**: Alternative charting library with Material Design
- **Library**: `charts_flutter` package
- **Features**:
  - Interactive charts
  - Tooltips and legends
  - Responsive design
- **Installation**: Add to `pubspec.yaml`:
  ```yaml
  dependencies:
    charts_flutter: ^0.12.0
  ```

### Core Dependencies

#### 4. **Provider (State Management)**
- **Purpose**: Managing nutrition aggregation state and UI state
- **Library**: `provider` package
- **Installation**:
  ```yaml
  dependencies:
    provider: ^6.0.0
  ```
- **Usage**: Notifies UI when aggregation data changes

#### 5. **Supabase (Database & Real-time)**
- **Purpose**: Fetching meal logs, daily goals, and food database
- **Library**: `supabase_flutter` package
- **Installation**:
  ```yaml
  dependencies:
    supabase_flutter: ^1.10.0
  ```

#### 6. **Intl (Internationalization)**
- **Purpose**: Date formatting and localization
- **Library**: `intl` package
- **Installation**:
  ```yaml
  dependencies:
    intl: ^0.19.0
  ```
- **Usage**: Formatting dates as "Mon", "Tue", etc. and month names

### Complete pubspec.yaml Entry

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.0
  
  # Database
  supabase_flutter: ^1.10.0
  
  # Internationalization
  intl: ^0.19.0
  
  # Optional: Enhanced Charts (if using fl_chart)
  fl_chart: ^0.65.0
  
  # Optional: Google Charts (if using charts_flutter)
  charts_flutter: ^0.12.0
```

### Chart Implementation Details

#### CustomPaint Implementation (Current)
- **File Location**: `lib/views/nutrition/widgets/` (typically)
- **Classes**:
  - `_DonutChartPainter extends CustomPainter`
    - Draws donut chart segments
    - Renders macro percentages
  - `_CalorieChartPainter extends CustomPainter`
    - Draws line chart with Bezier curves
    - Renders interactive data points
    - Calculates scaling and positioning

#### Key Methods

```dart
// Donut Chart Painter
class _DonutChartPainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    // 1. Draw background circle
    // 2. Calculate segment angles
    // 3. Draw colored arcs for each macro
    // 4. Draw center text
  }
  
  bool shouldRepaint(_DonutChartPainter oldDelegate) => true;
}

// Calorie Chart Painter
class _CalorieChartPainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    // 1. Draw grid lines
    // 2. Calculate coordinate positions
    // 3. Draw Bezier curve through points
    // 4. Draw gradient fill
    // 5. Draw data point circles
    // 6. Draw axis labels
  }
  
  bool shouldRepaint(_CalorieChartPainter oldDelegate) => true;
}
```

#### Example Usage in Widget

```dart
// Donut Chart Widget
CustomPaint(
  painter: _DonutChartPainter(
    carbsPercentage: 0.50,
    proteinPercentage: 0.27,
    fatPercentage: 0.23,
    totalCalories: 2150,
  ),
  size: const Size(120, 120),
)

// Line Chart Widget
CustomPaint(
  painter: _CalorieChartPainter(
    dataPoints: [2100, 2340, 2150, 2450, 2300, 2200, 2400],
    selectedDay: _selectedWeeklyDay,
    calorieGoal: 2500,
  ),
  size: Size(double.maxFinite, 250),
)
```

---

## Architecture Overview

### Data Flow

```
┌─────────────────────────────────────────────────────────┐
│         NutritionScreen (Main Container)                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. User selects tab (Daily/Weekly/Monthly)            │
│  2. Load aggregation data via NutritionAggregationService
│  3. Fetch daily goals from DailyGoalsRepository         │
│  4. Aggregate meals and calculate nutrition            │
│  5. Render appropriate tab content                     │
│  6. Display visualizations (charts, progress bars)     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Key Services & Models

```
NutritionAggregationService
├─ getDailyAggregation()     → DailyAggregation
├─ getWeeklyAggregation()    → WeeklyAggregation
└─ getMonthlyAggregation()   → MonthlyAggregation
        ↓
Repository Layer
├─ DailyGoalsRepository      (Get user goals)
├─ MealLogRepository         (Get meals)
└─ MealFoodRepository        (Get food details)
```

---

## Daily Analysis

### Purpose
Tracks today's nutritional intake and progress toward daily goals.

### UI Layout

```
┌─────────────────────────────────────────────┐
│        DAILY ANALYSIS TAB                   │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ TODAY'S SUMMARY CARD                 │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │ Consumed          2,150 kcal        │  │
│  │ Goal: 2,500 kcal  86% of goal       │  │
│  │                                      │  │
│  │ [████████████████░░] Progress       │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ MACRO BREAKDOWN CARD                 │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │  [DONUT CHART]   Carbs: 280g        │  │
│  │      ◯           Protein: 120g      │  │
│  │                  Fat: 85g            │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ MEALS CONSUMED (3)                   │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │ 🥣 Breakfast         08:00           │  │
│  │    520 kcal  Protein: 18g  Carbs: 75g │
│  │                                      │  │
│  │ 🍽️ Lunch            12:30           │  │
│  │    680 kcal  Protein: 45g  Carbs: 85g │
│  │                                      │  │
│  │ 🍖 Dinner           19:00           │  │
│  │    950 kcal  Protein: 57g  Carbs: 120g│
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

### Features

#### 1. **Today's Summary Card**
- **Consumed**: Total calories logged today
- **Goal**: User's daily calorie goal
- **Percentage**: Visual representation of progress (0-200%)
- **Progress Bar**: Linear progress indicator

```dart
Example:
- Consumed: 2,150 kcal
- Goal: 2,500 kcal
- Percentage: 86%
- Status: On track (green bar)
```

#### 2. **Macro Breakdown**
- **Donut Chart**: Visual distribution of macronutrients
  - Carbs: Green segment
  - Protein: Purple segment
  - Fat: Cyan segment
- **Legend**: Exact values for each macro

```
Macro Distribution:
Carbs:    280g (50%)  [GREEN]
Protein:  120g (27%)  [PURPLE]
Fat:      85g  (23%)  [CYAN]
```

#### 3. **Meals Consumed List**
- Shows all meals logged today
- Displays:
  - Meal type (Breakfast, Lunch, Dinner, Snacks)
  - Time logged
  - Total calories
  - Individual macros (Protein, Carbs, Fat)

### Calculation Logic

```dart
Total Calories = SUM(all meal calories)
Total Carbs = SUM(meal.totalCarbs)
Total Protein = SUM(meal.totalProteins)
Total Fat = SUM(meal.totalFats)

PercentOfGoal = (totalCalories / calorieGoal) * 100

MacroPercentage:
  carbsPct = totalCarbs / (totalCarbs + totalProtein + totalFat)
  proteinPct = totalProtein / (totalCarbs + totalProtein + totalFat)
  fatPct = totalFat / (totalCarbs + totalProtein + totalFat)
```

---

## Weekly Analysis

### Purpose
Tracks nutritional trends over the past 7 days and shows average intake vs. goals.

### UI Layout

```
┌─────────────────────────────────────────────┐
│        WEEKLY ANALYSIS TAB                  │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ WEEKLY CALORIE TREND                 │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │ 2,340 kcal                           │  │
│  │ avg per day           [Clear] (if    │  │
│  │                       selected)      │  │
│  │                                      │  │
│  │      ↑ (Line chart with points)      │  │
│  │    ╱ ╲                               │  │
│  │   ╱   ╲  ╱                           │  │
│  │  ╱     ╲╱                            │  │
│  │                                      │  │
│  │ Mon Tue Wed Thu Fri Sat Sun          │  │
│  │ (Clickable to select specific day)   │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ AVERAGE MACRO DISTRIBUTION          │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │  [DONUT CHART]   Carbs: 265g        │  │
│  │      ◯           Protein: 110g      │  │
│  │                  Fat: 82g            │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ DAILY DEVIATION FROM GOAL            │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │ Mon [████████░░] -120 kcal          │  │
│  │ Tue [██████████] +45 kcal           │  │
│  │ Wed [████████████] +150 kcal        │  │
│  │ Thu [██████░░░░░] -280 kcal         │  │
│  │ Fri [██████████░] +20 kcal          │  │
│  │ Sat [████████░░░] -60 kcal          │  │
│  │ Sun [██████████░░] +80 kcal         │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

### Features

#### 1. **Weekly Calorie Trend Chart**
- **Interactive Line Chart**: Shows calorie progression
- **Data Points**: One point per day (7 points total)
- **Smooth Bezier Curves**: Connect points with smooth lines
- **Gradient Fill**: Semi-transparent fill under the curve
- **Selectable Points**: Click/tap to see specific day's data
- **Clear Button**: Reset selection to show average

```
Chart Interactions:
- Tap on any day → Shows that day's calories
- Display changes: "2,450 kcal" and "Monday calories"
- Tap "Clear" → Back to average view
- Display resets: "2,340 kcal" and "kcal avg per day"
```

#### 2. **Average Macro Distribution**
- Shows average daily macro intake across the week
- Same donut chart format as daily view
- Calculations based on 7-day average

#### 3. **Daily Deviation Card**
- Shows each day's variance from goal
- **Green bars**: Days under goal (negative deviation)
- **Red bars**: Days over goal (positive deviation)
- **Plus/Minus**: Visual indicator of over/under
- **Exact values**: Displayed on the right

```
Example:
Monday:   -120 kcal (120 below goal)    [GREEN]
Tuesday:  +45 kcal  (45 above goal)     [RED]
Wednesday: +150 kcal (150 above goal)   [RED]
```

### Calculation Logic

```dart
DailyCalories = [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
AvgDailyCalories = SUM(all days) / 7

AvgDailyMacros:
  avgCarbs = SUM(daily carbs) / 7
  avgProtein = SUM(daily protein) / 7
  avgFat = SUM(daily fat) / 7

DailyDeviation:
  deviation = dailyCalories - dailyGoal
  Status = deviation > 0 ? "Over" : "Under"
```

---

## Monthly Analysis

### Purpose
Provides long-term nutritional overview with nutrient insights and trends.

### UI Layout

```
┌─────────────────────────────────────────────┐
│       MONTHLY ANALYSIS TAB                  │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ MONTH NAVIGATION                     │  │
│  ├──────────────────────────────────────┤  │
│  │  [◄]  April 2026  [►]                │  │
│  │                                      │  │
│  │  (Click arrows to navigate months)   │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ MONTHLY SUMMARY CARD                 │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │ April 2026                           │  │
│  │ Total Consumed                       │  │
│  │ 62,500 kcal                          │  │
│  │ Goal: 75,000 kcal    83% of goal     │  │
│  │                                      │  │
│  │ [████████████░░] Progress            │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ AVERAGE DAILY MACROS                 │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │  [DONUT CHART]   Carbs: 268g        │  │
│  │      ◯           Protein: 115g      │  │
│  │                  Fat: 84g            │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ NUTRIENT INSIGHTS (Top 3)            │  │
│  ├──────────────────────────────────────┤  │
│  │                                      │  │
│  │ ┌──────────────────────────────────┐ │  │
│  │ │ Protein        +12%               │ │  │
│  │ │ Avg: 115g/day   Goal: 102g/day   │ │  │
│  │ └──────────────────────────────────┘ │  │
│  │                                      │  │
│  │ ┌──────────────────────────────────┐ │  │
│  │ │ Fiber          -8%                │ │  │
│  │ │ Avg: 22g/day    Goal: 24g/day    │ │  │
│  │ └──────────────────────────────────┘ │  │
│  │                                      │  │
│  │ ┌──────────────────────────────────┐ │  │
│  │ │ Sodium         +25%               │ │  │
│  │ │ Avg: 2,800mg/day Goal: 2,200mg   │ │  │
│  │ └──────────────────────────────────┘ │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

### Features

#### 1. **Month Navigation**
- **Previous Button**: Navigate to previous month
- **Month Display**: Shows current month and year
- **Next Button**: Navigate to next month
- **Auto-Load**: Fetches data when month changes

#### 2. **Monthly Summary Card**
- **Total Consumed**: All calories logged in the month
- **Monthly Goal**: 30 days × daily goal
- **Percentage**: Progress toward monthly goal
- **Progress Bar**: Visual indicator

```
Example (30-day month):
- Daily goal: 2,500 kcal
- Monthly goal: 75,000 kcal
- Consumed: 62,500 kcal
- Progress: 83%
```

#### 3. **Average Daily Macros**
- Shows average macros per day for the month
- Calculated by dividing monthly totals by number of days

#### 4. **Nutrient Insights**
- **Top 3 Nutrient Deviations**: Sorted by percentage difference
- **Color Coding**:
  - **Red**: Over goal (excessive intake)
  - **Green**: Under goal (insufficient intake)
- **Details**: Current average vs. goal
- **Percentage**: How far over/under the goal

```
Example Insights:
1. Protein: +12%
   Avg: 115g/day vs Goal: 102g/day
   Status: Exceeding goal ✓

2. Fiber: -8%
   Avg: 22g/day vs Goal: 24g/day
   Status: Below goal ✗

3. Sodium: +25%
   Avg: 2,800mg/day vs Goal: 2,200mg/day
   Status: Significantly over ✗✗
```

### Calculation Logic

```dart
MonthlyTotal = SUM(all daily totals for the month)
MonthlyGoal = dailyGoal × number_of_days_in_month
PercentOfGoal = (monthlyTotal / monthlyGoal) * 100

AvgDailyMacros = monthlyTotal / number_of_days

NutrientInsights:
  percentage_diff = ((actual - goal) / goal) * 100
  isOver = actual > goal
  
Sort insights by ABS(percentage_diff) descending
Show top 3
```

---

## UI Components

### 1. Tab Bar

```dart
Widget: Custom AnimatedContainer
Height: 42px
Tabs: Daily | Weekly | Monthly

States:
├─ Unselected: Transparent bg, subtle text
├─ Selected: Green bg, dark text
└─ Animation: 250ms smooth transition
```

**Visual:**
```
┌────────────────────────────────────┐
│ [Daily] [Weekly] [Monthly]         │
│  ↑
│  Selected shows as bright green
└────────────────────────────────────┘
```

### 2. Summary Cards

```dart
Widget: Container with BorderRadius
Padding: 18px all sides
Background: nutritionCardBg color
Border Radius: 18px
Shadow: Subtle elevation

Layout:
├─ Title (subtitle, 13px, 65% opacity)
├─ Main Value (large, 22-34px, bold)
├─ Supporting Text (12px, subtle)
└─ Progress Bar or Chart
```

### 3. Custom Charts

#### Donut Chart
```dart
CustomPaint Painter: _DonutChartPainter

Features:
├─ Center circle (empty)
├─ Colored segments (Carbs, Protein, Fat)
├─ Gap between segments (0.03 radians)
├─ Smooth rounded caps
├─ Center text display ("Total" + "100%")
└─ Size: 120x120px
```

#### Line Chart (Weekly Calorie Trend)
```dart
CustomPaint Painter: _CalorieChartPainter

Features:
├─ Smooth Bezier curves through points
├─ Gradient fill (green, semi-transparent)
├─ Stroke line (green, 2.5px)
├─ Interactive dots (4px normal, 7px selected)
├─ Y-axis: Auto-scale based on data
├─ X-axis: 7 days
└─ Interaction: Tap to select day
```

### 4. Progress Bars

```dart
Widget: ClipRRect + LinearProgressIndicator

Styling:
├─ Height: 6px
├─ Background: Dark gray (progressBg)
├─ Foreground: Green (normalcy) or Red (over)
├─ Border Radius: 6px
├─ Value: 0.0 to 1.0
└─ Animation: Smooth transition
```

### 5. Meal Tiles

```dart
Layout:
┌─────────────────────────────────────┐
│ [Meal Icon]                         │
│ Breakfast              08:00        │
│ 520 kcal               (calories)   │
│                                     │
│ [Protein] [Carbs] [Fat] (mini info) │
└─────────────────────────────────────┘
```

---

## Data Models

### DailyAggregation

```dart
class DailyAggregation {
  DateTime date;
  List<MealLog> meals;
  
  double totalCalories;
  double totalProteins;
  double totalCarbs;
  double totalFats;
  
  double calorieGoal;
}
```

### WeeklyAggregation

```dart
class WeeklyAggregation {
  DateTime endDate;
  
  // Per-day data
  List<double> caloriesList;           // 7 values
  List<DailyAggregation> dailyData;   // 7 days
  List<String> dayLabels;              // ["Mon", "Tue", ...]
  
  // Averages
  double avgDailyCalories;
  double avgDailyProteins;
  double avgDailyCarbs;
  double avgDailyFats;
}
```

### MonthlyAggregation

```dart
class MonthlyAggregation {
  DateTime startDate;
  DateTime endDate;
  
  double totalCalories;
  double totalProteins;
  double totalCarbs;
  double totalFats;
  
  double avgDailyCalories;
  double avgDailyProteins;
  double avgDailyCarbs;
  double avgDailyFats;
  
  double monthlyCalorieGoal;
  int daysInMonth;
  
  List<NutrientHighlight> getNutrientHighlights();
}
```

---

## Code Implementation

### Entry Point: NutritionScreen

```dart
class _NutritionScreenState extends State<NutritionScreen> {
  int _selectedTab = 1;              // 0=Daily, 1=Weekly, 2=Monthly
  int? _selectedWeeklyDay;           // For interactive weekly chart
  DateTime _selectedMonth;           // For monthly navigation
  
  NutritionAggregationService _aggregationService;
  
  DailyAggregation? _dailyAggregation;
  WeeklyAggregation? _weeklyAggregation;
  MonthlyAggregation? _monthlyAggregation;
}
```

### Load Data Process

```dart
Future<void> _loadAggregationData() async {
  1. Get user's daily goals from database
  2. Get all meals for the user
  3. Call aggregation service:
     - getDailyAggregation(now, meals, goals)
     - getWeeklyAggregation(now, meals, goals)
     - getMonthlyAggregation(selectedMonth, meals, goals)
  4. setState() to update UI
  5. Render appropriate content based on _selectedTab
}
```

### Tab Switching

```dart
User taps on "Weekly" tab
       ↓
_selectedTab = 1
       ↓
setState() → rebuild()
       ↓
Check: _selectedTab == 1
       ↓
_buildWeeklyContent()
       ↓
Render weekly UI
```

### Weekly Chart Interaction

```dart
User taps on chart
       ↓
onTapDown() callback triggered
       ↓
Calculate which day was tapped:
  dayIndex = (tapX / chartWidth) * 7
       ↓
_selectedWeeklyDay = dayIndex
       ↓
setState() → rebuild
       ↓
Display value for selected day
       ↓
Show "Clear" button to reset
```

---

## Color Scheme

```
Background:    #0A0E27 (nutritionDarkBg)
Cards:         #1A1F3A (nutritionCardBg)
Progress:      #0F1629 (nutritionProgressBg)
Text Primary:  White
Text Subtle:   #7A8BA8 (nutritionSubtleText)

Macros:
├─ Carbs:      #00FF88 (nutritionNeonGreen)
├─ Protein:    #B366FF (nutritionPurple)
├─ Fat:        #00E5FF (nutritionCyan)

Status:
├─ Over Goal:  #FF6B6B (red)
└─ On Track:   #00FF88 (green)
```

---

## Performance Considerations

### Data Aggregation
- **One-time load**: All calculations done at initialization
- **Efficient filtering**: Uses list comprehensions and folds
- **Caching**: Data stored in local variables
- **No repeated queries**: Goals fetched once

### Rendering
- **FadeTransition**: Smooth tab switching
- **CustomPaint**: Efficient chart rendering
- **ListView**: Only visible items rendered
- **Responsive**: Adapts to screen size

### Memory
- **Weekly chart**: 7 data points (minimal)
- **Daily meals**: Typically 3-5 meals
- **Monthly data**: 30 aggregated daily values
- **Overall**: Negligible memory footprint

---

## User Workflows

### Scenario 1: Check Today's Progress

```
1. User opens app
2. Sees Daily tab by default
3. Views "Today's Summary"
4. Sees consumed vs goal
5. Checks macro breakdown
6. Reviews meals logged
```

### Scenario 2: Analyze Weekly Trends

```
1. User switches to Weekly tab
2. Views calorie trend chart
3. Taps specific day to see details
4. Views average macros for week
5. Checks daily deviations
6. Identifies patterns
```

### Scenario 3: Monitor Monthly Progress

```
1. User switches to Monthly tab
2. Navigates to desired month
3. Views total calories consumed
4. Reviews average daily macros
5. Checks nutrient insights
6. Identifies areas needing improvement
```

---

## Summary

| Aspect | Daily | Weekly | Monthly |
|--------|-------|--------|---------|
| **Time Scope** | Today (1 day) | Past 7 days | Full month |
| **Main Metric** | Calories consumed | Calorie trend | Total progress |
| **Chart Type** | Progress bar | Line chart | Summary |
| **Details** | Individual meals | Daily averages | Nutrient insights |
| **Interaction** | View only | Select day | Navigate months |
| **Use Case** | Quick check | Trend analysis | Long-term monitoring |

---

**Status:** ✅ Complete & Production Ready


