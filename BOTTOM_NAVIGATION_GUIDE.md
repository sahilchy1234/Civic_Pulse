# Bottom Navigation Implementation Guide

## Overview
A beautiful and modern bottom navigation system has been implemented for the CivicSense app, providing easy access to key features at the user's fingertips.

## Features Implemented

### 1. **Citizen Bottom Navigation**
The citizen experience includes 4 main tabs:

#### 🏠 **Home**
- Main feed of civic issues
- View, search, and filter issues
- Upvote and comment on issues

#### ➕ **Report** (Center Action Button)
- Special highlighted button in the center
- Gradient background with shadow effect
- Opens report issue screen as a modal
- Quick access to report new civic issues

#### 🏆 **Leaderboard**
- View community rankings
- See top contributors
- Track your own ranking

#### 👤 **Profile**
- View and edit personal profile
- See your reported issues
- View your achievements and badges

### 2. **Authority Bottom Navigation**
The authority experience includes 4 main tabs:

#### 📊 **Dashboard**
- Overview of all reported issues
- Quick statistics
- Issue management

#### 📈 **Analytics**
- View detailed analytics
- Track issue resolution trends
- Generate reports

#### 🗺️ **Map**
- Visual map overview of issues
- Geographic distribution
- Location-based filtering

#### 👤 **Profile**
- View and edit profile
- Authority settings

## Design Features

### Visual Design
- **Rounded Top Corners**: 24px border radius for modern look
- **Soft Shadow**: Elevated appearance with subtle shadow
- **Active State Indicators**: 
  - Icon background highlight in brand color
  - Bold selected label
  - Smooth color transitions
- **Center Action Button**: 
  - Special gradient design for Report button
  - Floating effect with shadow
  - Larger size to draw attention

### User Experience
- **Smooth Transitions**: Animated tab switching
- **Visual Feedback**: Clear active/inactive states
- **Persistent Navigation**: Always accessible at bottom
- **IndexedStack**: Maintains state when switching tabs
- **Intuitive Icons**: Clear, recognizable icons for each section

## Technical Implementation

### File Structure
```
lib/
├── screens/
│   ├── citizen/
│   │   ├── citizen_main_screen.dart    # Citizen nav wrapper
│   │   ├── home_screen.dart            # Home tab content
│   │   ├── leaderboard_screen.dart     # Leaderboard tab
│   │   └── profile_screen.dart         # Profile tab
│   └── authority/
│       ├── authority_main_screen.dart  # Authority nav wrapper
│       ├── dashboard_screen.dart       # Dashboard tab
│       ├── analytics_screen.dart       # Analytics tab
│       ├── map_overview_screen.dart    # Map tab
│       └── profile_screen.dart         # Profile tab (shared)
```

### Code Architecture

#### Main Navigation Wrapper (Citizen)
```dart
class CitizenMainScreen extends StatefulWidget {
  // Manages bottom navigation state
  // Uses IndexedStack to preserve state
  // Handles tab switching logic
}
```

#### Bottom Navigation Bar
```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  selectedItemColor: Color(0xFF667eea),
  unselectedItemColor: Colors.grey[400],
  // ... 4 navigation items
)
```

#### Special Center Button
```dart
BottomNavigationBarItem(
  icon: Container(
    // Gradient background
    // Shadow effect
    // Larger size
  ),
  label: 'Report',
)
```

## Integration Details

### Main App Integration
The navigation is integrated into the main authentication flow:

```dart
// In main.dart
if (authService.user!.role == 'Authority') {
  return const AuthorityMainScreen();
} else {
  return const CitizenMainScreen();
}
```

### State Management
- **IndexedStack**: Preserves state of each tab when switching
- **Current Index**: Tracks active tab
- **On Tap Handler**: Manages navigation logic

### Drawer Integration
Both citizen and authority main screens include the drawer:
- Access via hamburger menu in child screens
- Provides additional navigation options
- Complements bottom navigation

## Key Features

### 1. **State Preservation**
Using `IndexedStack` ensures that:
- Scroll positions are maintained
- Form data isn't lost
- Network requests aren't repeated
- Smooth user experience

### 2. **Special Report Button**
For citizens, the center button:
- Opens as a modal (not a tab)
- Returns to previous tab after reporting
- Visually distinct with gradient design

### 3. **Consistent Design**
- Matches app theme colors
- Rounded corners match other UI elements
- Shadow effects consistent with cards
- Typography aligned with app style

## Customization Guide

### Changing Colors
```dart
// In bottom navigation bar
selectedItemColor: Color(0xFF667eea),     // Active tab color
unselectedItemColor: Colors.grey[400],    // Inactive tab color
```

### Adding New Tabs
1. Add screen to `_screens` list
2. Add new `BottomNavigationBarItem`
3. Update index handling in `_onItemTapped`

### Modifying Icons
```dart
BottomNavigationBarItem(
  icon: _buildNavIcon(Icons.your_icon, index),
  activeIcon: _buildNavIcon(Icons.your_icon_filled, index, isActive: true),
  label: 'Your Label',
)
```

## Navigation Flow

### Citizen Flow
1. **App Launch** → Login → CitizenMainScreen
2. **Tab Selection** → Switches content with IndexedStack
3. **Report Button** → Opens modal, returns to previous tab
4. **Drawer Menu** → Additional navigation options

### Authority Flow
1. **App Launch** → Login → AuthorityMainScreen
2. **Tab Selection** → Dashboard/Analytics/Map/Profile
3. **Drawer Menu** → Additional options

## Benefits

✅ **Quick Access**: Key features always one tap away
✅ **State Preservation**: No data loss when switching tabs
✅ **Visual Clarity**: Clear active/inactive indicators
✅ **Modern Design**: Beautiful gradient and shadow effects
✅ **Dual Navigation**: Works with drawer for complete navigation
✅ **Role-Based**: Different navigation for different user types
✅ **Responsive**: Adapts to different screen sizes

## Future Enhancements

Possible improvements:
- [ ] Badge indicators for notifications
- [ ] Haptic feedback on tab change
- [ ] Custom animations for tab transitions
- [ ] Long-press actions on tabs
- [ ] Swipe gestures between tabs
- [ ] Dynamic tab visibility based on permissions

## Testing Checklist

Test the following:
1. ✅ Switch between all tabs
2. ✅ Verify state is preserved when switching
3. ✅ Report button opens modal correctly
4. ✅ Modal closes and returns to previous tab
5. ✅ Drawer accessible from all tabs
6. ✅ Icons and labels display correctly
7. ✅ Active state indicators work
8. ✅ Test on different screen sizes
9. ✅ Test both citizen and authority roles

## Troubleshooting

### Issue: State not preserved
**Solution**: Ensure using `IndexedStack` not `PageView` or direct widget switching

### Issue: Tab not switching
**Solution**: Check `_onItemTapped` logic and `setState` call

### Issue: Report button not working
**Solution**: Verify modal navigation logic for index 1

### Issue: Drawer not opening
**Solution**: Ensure drawer is added to Scaffold in main screen, not child screens

---

**Note**: The bottom navigation complements the drawer navigation, providing quick access to frequently used features while the drawer contains all navigation options.

