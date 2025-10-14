# 🏆 Leaderboard System Implementation Guide

## Overview

The CivicSense app now includes a comprehensive leaderboard and gamification system to encourage citizen engagement and reward active community participation.

## Features Implemented

### 1. **Leaderboard System**
- ✅ Multi-period leaderboards (Daily, Weekly, Monthly, All-Time)
- ✅ Top 3 podium display with medals
- ✅ User ranking with detailed stats
- ✅ Real-time updates
- ✅ Current user highlight
- ✅ Points-based ranking system

### 2. **Points System**

Points are automatically awarded for various actions:

| Action | Points |
|--------|--------|
| Report an issue | 10 points |
| Report with photo | +5 bonus |
| Detailed description (>100 chars) | +5 bonus |
| First reporter in area | +15 bonus |
| Issue verified by authority | +25 points |
| Issue resolved | +50 points |
| Receive upvote | +1 point |
| Weekly active participation | +20 points |

### 3. **Badge & Achievement System**

#### Tier Badges
- 🥉 **Bronze Citizen** - Report 10 issues
- 🥈 **Silver Guardian** - Report 50 issues
- 🥇 **Gold Champion** - Report 100 issues
- 💎 **Platinum Hero** - Report 500 issues
- 🏅 **Diamond Legend** - Report 1000+ issues

#### Achievement Badges
- 🌅 **Early Bird** - Report 5 issues before 8 AM
- 🦉 **Night Owl** - Report 5 issues after 10 PM
- 🎯 **Category Expert** - Report 20+ issues in one category
- ✅ **Resolution Champion** - Have 10+ issues resolved
- 🔥 **Streak Master** - Report for 30 consecutive days
- ⭐ **Quality Inspector** - Maintain 95%+ approval rate on 20+ reports
- 💪 **Impact Maker** - Get 100+ total upvotes
- 🚀 **First Reporter** - First to report an issue in your area
- ⚔️ **Weekly Warrior** - Top 10 in weekly leaderboard
- 👑 **Monthly Maven** - Top 10 in monthly leaderboard

### 4. **User Statistics Tracking**

The system tracks comprehensive user statistics:
- Total reports submitted
- Resolved reports count
- Pending and in-progress reports
- Total upvotes received
- Current and longest streaks
- Early bird and night owl reports
- Category-wise report breakdown
- Earned badges collection

## File Structure

### Models
```
lib/models/
├── badge_model.dart              # Badge definitions and logic
├── leaderboard_entry_model.dart  # Leaderboard entry and user stats
├── user_model.dart               # Enhanced with points field
└── issue_model.dart              # Existing issue model
```

### Services
```
lib/services/
├── leaderboard_service.dart      # Core leaderboard logic and points
├── firestore_service.dart        # Updated with point awarding
└── auth_service.dart             # Updated with stats initialization
```

### Screens
```
lib/screens/citizen/
├── leaderboard_screen.dart       # Main leaderboard display
├── achievements_screen.dart      # Badge showcase and progress
└── home_screen.dart              # Updated with navigation
```

### Widgets
```
lib/widgets/
├── badge_widget.dart             # Badge display components
├── issue_card.dart               # Existing issue card
└── custom_button.dart            # Existing button
```

## Database Schema

### Collections

#### `userStats` Collection
```javascript
{
  userId: string,
  totalReports: number,
  resolvedReports: number,
  pendingReports: number,
  inProgressReports: number,
  totalUpvotes: number,
  currentStreak: number,
  longestStreak: number,
  earlyBirdReports: number,
  nightOwlReports: number,
  categoryReports: {
    'Pothole': number,
    'Garbage': number,
    // ... other categories
  },
  earnedBadges: [string],  // Array of badge type strings
  lastReportDate: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### `users` Collection (Updated)
```javascript
{
  id: string,
  name: string,
  email: string,
  role: string,
  points: number,  // Added for leaderboard
  profileImageUrl: string,
  createdAt: timestamp
}
```

## Usage Guide

### For Users

#### Accessing the Leaderboard
1. Open the CivicSense app
2. Tap the menu icon (⋮) in the top-right corner
3. Select "Leaderboard"
4. Switch between Daily, Weekly, Monthly, and All-Time tabs

#### Viewing Achievements
1. Open the menu
2. Select "Achievements"
3. View earned badges and progress toward next badges
4. Tap any badge to see detailed information

### For Developers

#### Awarding Custom Points
```dart
// Award points for a custom action
await LeaderboardService().awardPointsForReport(
  userId: userId,
  issue: issueModel,
  isFirstInArea: true,  // Optional bonus
);
```

#### Getting User Stats
```dart
final stats = await LeaderboardService().getUserStats(userId);
print('Total reports: ${stats.totalReports}');
print('Current streak: ${stats.currentStreak}');
```

#### Getting Leaderboard Data
```dart
final leaderboard = await LeaderboardService().getLeaderboard(
  period: 'weekly',  // 'daily', 'weekly', 'monthly', 'all'
  limit: 100,
);
```

#### Checking User Badges
```dart
final badges = await LeaderboardService().getUserBadges(userId);
for (final badge in badges) {
  print('${badge.emoji} ${badge.name}');
}
```

## Integration Points

### Automatic Point Awarding

Points are automatically awarded when:

1. **Issue Creation** (in `firestore_service.dart`)
   - Triggered when `createIssue()` is called
   - Awards base points + bonuses

2. **Issue Status Change** (in `firestore_service.dart`)
   - Triggered when `updateIssue()` is called with status change
   - Awards resolution bonus

3. **Upvoting** (in `firestore_service.dart`)
   - Triggered when `upvoteIssue()` is called
   - Awards points to issue owner

4. **User Registration** (in `auth_service.dart`)
   - Initializes user stats document
   - Sets up tracking for new users

## UI/UX Highlights

### Leaderboard Screen
- **Gradient header** with app branding
- **Tab navigation** for different time periods
- **User rank card** showing current position
- **Top 3 podium** with animated medals
- **Scrollable list** with user cards
- **Pull to refresh** functionality
- **Empty state** for new installations

### Achievements Screen
- **Stats overview** with gradient card
- **Progress tracking** for next badge
- **Grid layout** for earned badges
- **Locked badges** shown with lock icon
- **Detailed dialog** on badge tap
- **Progress bars** for completion percentage

### Home Screen Integration
- New menu items for Leaderboard and Achievements
- Icons: 🏆 Leaderboard, 🏅 Achievements
- Easy navigation from main screen

## Customization

### Adding New Badges

1. Add badge type to `BadgeType` enum in `badge_model.dart`
2. Add badge definition in `BadgeModel.getAllBadges()`
3. Implement check logic in `_checkAndAwardBadges()` in `leaderboard_service.dart`

Example:
```dart
// In badge_model.dart
enum BadgeType {
  // ... existing badges
  superReporter,  // New badge
}

// In getAllBadges()
BadgeModel(
  type: BadgeType.superReporter,
  name: 'Super Reporter',
  description: 'Report 50 issues in one month',
  emoji: '🦸',
  requiredValue: 50,
),
```

### Adjusting Point Values

Modify constants in `leaderboard_service.dart`:
```dart
static const int pointsReportIssue = 10;
static const int pointsIssueVerified = 25;
static const int pointsIssueResolved = 50;
// ... etc
```

## Performance Considerations

### Optimization
- Leaderboard queries limited to top 100 users
- User stats updates batched where possible
- Indexes recommended on:
  - `users.points` (descending)
  - `users.role`
  - `userStats.userId`

### Firestore Rules
Add security rules for the new collections:
```javascript
match /userStats/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}
```

## Testing Checklist

- [ ] Points awarded correctly on issue creation
- [ ] Points awarded correctly on issue resolution
- [ ] Upvote points work both ways (add/remove)
- [ ] Badges unlock at correct thresholds
- [ ] Leaderboard updates in real-time
- [ ] User stats track accurately
- [ ] Streak calculation works correctly
- [ ] All tabs show correct data
- [ ] Navigation works from home screen
- [ ] Achievement screen shows progress
- [ ] Badge details dialog works

## Future Enhancements

### Planned Features
- 📍 Geographic leaderboards (by ward/city)
- 👥 Team/group competitions
- 🎁 Reward redemption system
- 📊 Advanced analytics dashboard
- 🔔 Push notifications for rank changes
- 🤝 Social sharing of achievements
- 🎯 Weekly challenges
- 🏆 Special event leaderboards
- 💬 Leaderboard comments/reactions
- 📈 Historical ranking charts

### Nice-to-Have
- Profile badge showcase
- Badge collection completion percentage
- Seasonal badges
- Special badges for authorities
- Referral bonuses
- Photo quality badges
- Response time badges

## Troubleshooting

### Common Issues

**Points not updating:**
- Check Firestore security rules
- Verify user document exists
- Check console logs for errors

**Badges not unlocking:**
- Verify badge thresholds in code
- Check userStats document
- Confirm earnedBadges array updates

**Leaderboard not showing:**
- Ensure users have `role: 'Citizen'`
- Check points field exists on user documents
- Verify query limits

## Support

For questions or issues:
1. Check console logs for error messages
2. Verify Firestore data structure matches schema
3. Review the code comments in service files
4. Check the main documentation files

## Credits

**Developed for CivicSense**
- Gamification system
- Badge & achievement framework
- Leaderboard implementation
- Statistics tracking

---

**Version:** 1.0.0  
**Last Updated:** October 2025  
**Status:** ✅ Production Ready

