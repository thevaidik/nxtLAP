# Motorsports Widget Setup Guide

I've created the widget files for your motorsports app. Here's how to add the widget extension to your Xcode project:

## Files Created:
- `MotorsportsWidget/MotorsportsWidget.swift` - Main widget implementation
- `MotorsportsWidget/MotorsportsWidgetBundle.swift` - Widget bundle
- `MotorsportsWidget/Info.plist` - Widget extension Info.plist
- `Shared/RacingModels.swift` - Shared data models

## Setup Steps:

### 1. Add Widget Extension Target
1. Open your project in Xcode
2. Go to **File → New → Target**
3. Choose **Widget Extension**
4. Set the following:
   - Product Name: `MotorsportsWidget`
   - Bundle Identifier: `vaidik.motorsports.MotorsportsWidget`
   - Include Configuration Intent: **No**
5. Click **Finish**

### 2. Replace Generated Files
1. Delete the generated widget files in the new `MotorsportsWidget` folder
2. Add the files from the `MotorsportsWidget/` directory I created
3. Add the files from the `Shared/` directory to both targets (main app and widget)

### 3. Configure Shared Files
1. Select `Shared/RacingModels.swift` in Xcode
2. In the File Inspector, check both target memberships:
   - ✅ motorsports
   - ✅ MotorsportsWidget
3. The widget includes its own Color extension, so no additional setup needed

### 4. Update Asset Catalog
Make sure your `RacingRed` color is available to the widget target:
1. Select `Assets.xcassets`
2. Select the `RacingRed` colorset
3. In the File Inspector, ensure both targets are checked

### 5. App Groups (Optional but Recommended)
To share data between the main app and widget:
1. Add App Groups capability to both targets
2. Use the same group identifier (e.g., `group.vaidik.motorsports`)
3. Update the widget to read cached race data from UserDefaults with the suite name

## Widget Features:
- **Small Widget**: Shows next upcoming race
- **Medium Widget**: Shows 3 upcoming races
- **Large Widget**: Shows up to 6 upcoming races with full details
- **Auto-refresh**: Updates every hour
- **Racing Red theme**: Matches your app's design

## Next Steps:
1. Build and run the widget extension
2. Add the widget to your home screen to test
3. Implement data sharing between app and widget using App Groups
4. Consider adding configuration options for filtering by series

The widget is ready to use with sample data. To show real race data, you'll need to implement data sharing between your main app and the widget extension using App Groups and UserDefaults.