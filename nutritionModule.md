# FitTrack – Feature → Button → Controller → Service → Repository Map

This README documents how each feature is built (UI trigger → controller → service → repository), so teammates can quickly trace and modify functionality.

---

## Architecture (high level)

- **UI (Views)**: `lib/views/...` and `lib/views/widgets/...`
- **State/Controllers (Provider)**: `lib/controllers/...`
- **Business logic / orchestration**: `lib/services/...`
- **Database access (Supabase)**: `lib/repository/...`
- **Models**: `lib/models/...`

Providers are registered in:
- `lib/main.dart` (FoodController, MealController, AuthController)

---

# Meal Features

## 1) Add Meal (Log Meal)

### Where is the button?
- **Page**: `lib/views/add_new_meal.dart`
- **Button widget**: `_buildLogButton()`
- **Button label**: `Log Meal`
- **OnPressed**: `_logMeal()`

### Which controller does it use?
- `MealController`
  - Called from `_logMeal()` using:
    - `final mealController = context.read<MealController>();`
    - `mealController.logMealWithImage(...)`

### Which service does it use?
- `MealService`
  - Called internally by `MealController.logMealWithImage()`:
    - if image provided: `MealService.logMealWithImage(...)`
    - else: `MealService.logMeal(...)`

### Which repository does it use?
- Meal creation:
  - `MealLogRepository.createMeal(...)` → Supabase table `MealLog`
- Meal-food linking:
  - `MealFoodRepository.createMealFoods(...)` → Supabase table `MealFood`
- Nutrition calculations rely on:
  - `FoodRepository.getFoodsByUser(userId)` (used inside `MealService.logMeal`)

### Related UI pieces
- **Meal photo picker (optional)**:
  - Widget: `lib/views/widgets/meal_image_picker_widget.dart`
  - Controller: `MealController` (image selection + clear + upload)

---

## 2) Edit Meal

### Where is the button?
- **Page**: `lib/views/edit_meal.dart`
- The snippet shows the “Add Foods to Meal” section and macros calculation UI.
- (The exact “Save/Update meal” button location needs verification in the file; search for `updateMeal(` and/or a button like `Save` / `Update` in `edit_meal.dart`.)

### Which controller does it use?
- `MealController.updateMeal(...)`

### Which service does it use?
- `MealService.updateMeal(...)`

### Which repository does it use?
- Updates meal row:
  - `MealLogRepository.updateMeal(...)` (Supabase table `MealLog`)
- Replaces meal foods:
  - `MealFoodRepository.deleteMealFoodsByMealId(mealId)`
  - `MealFoodRepository.createMealFoods(...)`

---

## 3) Delete Meal

### Where is the button?
- Not confirmed from the limited search results.
- Likely located on a “meal log / list” UI page or a meal detail page.

### Which controller does it use?
- `MealController.deleteMeal(mealId)`

### Which service does it use?
- `MealService.deleteMeal(mealId)`

### Which repository does it use?
- Deletes all related foods first:
  - `MealFoodRepository.deleteMealFoodsByMealId(mealId)`
- Then deletes the meal:
  - `MealLogRepository.deleteMeal(mealId)`

---

## 4) Meal Log (Display all meals)

### Where is the button / entry point?
- Not confirmed from the limited search results.
- However, the **Nutrition Analysis** page displays meals in daily view, and expects `mealController.userMeals` to already be loaded.

### Which controller does it use?
- Data source is `MealController.userMeals`
- To fetch meals:
  - `MealController.fetchUserMeals(userId)`

### Which service does it use?
- `MealService.getUserMeals(userId)`

### Which repository does it use?
- `MealLogRepository.getMealsByUser(userId)` (Supabase table `MealLog`)

---

# Food Features

## 5) Add New Food

### Where is the button?
- **Page**: `lib/views/add_new_meal.dart`
- **Button label**: `Add New Food`
- Trigger:
  - `_navigateToAddFood()` → navigates to `AddNewFoodView`

### Which controller does it use?
- `FoodController.createFood(...)` (called inside add food form)

### Which service does it use?
- `FoodService.createFood(...)`

### Which repository does it use?
- `FoodRepository.createFood(...)` (exact method name inferred; the repository file should be checked)
- Stored in Supabase (Food table name depends on repository implementation)

### UI page
- `lib/views/add_new_food.dart`
  - On save: calls `foodController.createFood(...)`

---

## 6) Edit Food

### Where is the button?
- **Page**: `lib/views/add_new_meal.dart`
- Food rows pass callback:
  - `onEditFood: () => _navigateToEditFood(food)`
- That navigates to:
  - `EditFoodView` in `lib/views/edit_food.dart`

### Which controller does it use?
- `FoodController.updateFood(...)` (called inside `EditFoodView._saveFoodData()`)

### Which service does it use?
- `FoodService.updateFood(...)`

### Which repository does it use?
- `FoodRepository.updateFood(...)`

---

## 7) Delete Food

### Where is the button?
- Confirmed “batch delete” exists on Add New Meal page:
  - **Page**: `lib/views/add_new_meal.dart`
  - Toggle button in header: `Delete`
  - Confirmation dialog: “Delete Multiple Foods?”
  - Action: `_deleteBatchFoods()` loops selected foods and calls delete

### Which controller does it use?
- `FoodController.deleteFood(foodId)`

### Which service does it use?
- `FoodService.deleteFood(foodId)`

### Which repository does it use?
- `FoodRepository.deleteFood(foodId)`

> Note: Your feature list includes “Delete Meal” twice; one of them is likely intended to be “Delete Food”.

---

## 8) Display all meal in add new meal page

Current behavior (confirmed):
- `AddNewMealPage` (`lib/views/add_new_meal.dart`) displays **foods**, not meals:
  - it loads foods with `context.read<FoodController>().fetchAllFoods();`
  - and renders `foodController.userFoods`

If you truly want “display all meals” on this page, you’ll likely need:
- `MealController.fetchUserMeals(userId)`
- a UI section that renders `mealController.userMeals`

---

# Analytics Features

## 9) Daily Analysis
## 10) Weekly Analysis
## 11) Monthly Analysis

### Where is the UI?
- `lib/views/nutrition_analysis.dart`
  - Tab bar: `['Daily', 'Weekly', 'Monthly']`
  - UI builders:
    - Daily: `_buildDailyContent()`
    - Weekly: `_buildWeeklyContent()`
    - Monthly: `_buildMonthlyContent()`

### Which controller does it use?
- Reads meals from:
  - `final mealController = context.read<MealController>();`
  - Uses: `mealController.userMeals`
- Reads current user from:
  - `final authController = context.read<AuthController>();`

### Which service does it use?
- Aggregation is computed using:
  - `NutritionAggregationService` (`lib/services/nutrition_aggregation_service.dart`)

### Which repository does it use?
- Daily goals fetched from:
  - `DailyGoalsRepository.getDailyGoalsByUserId(userIdInt)` (Supabase table `DailyGoals`)

---

## 12) Daily Goal analytic card

### Where is the card?
- Two related places:
1) Nutrition Analysis page:
   - `lib/views/nutrition_analysis.dart`
   - Daily summary card: `_buildDailySummaryCard(...)` (shows consumed vs goal + progress)
2) Another UI component that looks like a “Daily Goal” widget:
   - `lib/views/nutrition_main_page.dart` (contains “DAILY GOAL” + “ANALYTICS” header and progress ring UI)

### Which controller does it use?
- Uses meal totals from `MealController.userMeals` (via aggregation)
- Uses goals from `DailyGoalsRepository`

### Which repository does it use?
- `DailyGoalsRepository` (Supabase `DailyGoals` table)

---

## 13) Macronutrient analytic card

### Where is the card?
- `lib/views/nutrition_analysis.dart`
  - Daily macro card: `_buildDailyMacroCard(...)` (“Macro Breakdown” donut)
  - Weekly macro card: `_buildWeeklyMacroCard(...)` (“Average Macro Distribution” donut)
  - Monthly macro card exists further down in the file (`_buildMonthlyMacroCard(...)`)

### Which controller does it use?
- Same as analytics:
  - `MealController.userMeals` + aggregation service

### Which service does it use?
- `NutritionAggregationService`

### Which repository does it use?
- Meals ultimately come from `MealLogRepository.getMealsByUser(...)`
- Goals from `DailyGoalsRepository.getDailyGoalsByUserId(...)`

---

# Key Files (quick links)

- Add meal: `lib/views/add_new_meal.dart`
- Meal controller: `lib/controllers/meal_controller.dart`
- Meal service: `lib/services/meal_service.dart`
- Meal repositories:
  - `lib/repository/meal_repository.dart` (MealLog table)
  - `lib/repository/meal_food_repository.dart` (MealFood table)
- Add/edit food pages:
  - `lib/views/add_new_food.dart`
  - `lib/views/edit_food.dart`
- Food controller: `lib/controllers/food_controller.dart`
- Nutrition analysis UI: `lib/views/nutrition_analysis.dart`
- Daily goals repository: `lib/repository/daily_goals_repository.dart`

---

# Notes / TODO for teammate

- Confirm and document:
  - the exact **Delete Meal** UI entry point (button location/page)
  - the exact **Meal Log page** where meals are listed (if separate from Nutrition Analysis)
  - the exact **Edit Meal save/update button** in `edit_meal.dart`

Use GitHub search for:
- `deleteMeal(`, `fetchUserMeals(`, `updateMeal(`, `EditMeal`, `MealLog`