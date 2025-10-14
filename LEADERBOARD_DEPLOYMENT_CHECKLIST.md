# ✅ Leaderboard Deployment Checklist

## Pre-Deployment Steps

### 1. Code Review ✅
- [x] All files created and integrated
- [x] No linter errors
- [x] Code follows best practices
- [x] Documentation complete

### 2. Firestore Setup
- [ ] Update Firestore security rules
- [ ] Create indexes for performance
- [ ] Test database queries

#### Recommended Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules...
    
    // User stats collection
    match /userStats/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId 
                   || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Authority';
      allow create: if request.auth.uid == userId;
    }
    
    // Update users collection to allow points field
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId 
                    || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Authority';
    }
  }
}
```

#### Recommended Indexes
Create composite indexes in Firebase Console:

1. **users collection**
   - Collection: `users`
   - Fields: `role` (Ascending), `points` (Descending)
   - Query scope: Collection

2. **userStats collection** (optional, for future features)
   - Collection: `userStats`
   - Fields: `totalReports` (Descending), `updatedAt` (Descending)
   - Query scope: Collection

### 3. Testing Phase
- [ ] Test user signup (stats initialization)
- [ ] Test issue creation (points awarded)
- [ ] Test with photo (bonus applied)
- [ ] Test detailed description (bonus applied)
- [ ] Test issue resolution (bonus awarded)
- [ ] Test upvoting (points to issue owner)
- [ ] Test un-upvoting (points removed)
- [ ] Test leaderboard display
- [ ] Test all 4 time period tabs
- [ ] Test achievements screen
- [ ] Test badge unlocking
- [ ] Test navigation from menu
- [ ] Test pull-to-refresh
- [ ] Test with multiple users
- [ ] Test real-time updates

### 4. Performance Optimization
- [ ] Verify Firestore indexes are created
- [ ] Test with 100+ users (performance)
- [ ] Check query execution times
- [ ] Monitor bandwidth usage
- [ ] Verify caching works properly

### 5. User Experience
- [ ] Test on different screen sizes
- [ ] Test on Android
- [ ] Test on iOS (if applicable)
- [ ] Verify animations work smoothly
- [ ] Check loading states
- [ ] Verify error messages
- [ ] Test empty states
- [ ] Check accessibility

## Deployment Steps

### Step 1: Code Deployment
```bash
# Run final checks
flutter analyze
flutter test

# Build for production
flutter build apk --release  # For Android
flutter build ios --release  # For iOS (if applicable)
```

### Step 2: Firebase Configuration
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Update security rules (see above)
4. Create indexes (see above)
5. Test rules in Firebase Emulator

### Step 3: Data Migration (if needed)
If you have existing users:

```dart
// Run this migration script once to initialize existing users
Future<void> migrateExistingUsers() async {
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();
  
  for (final userDoc in usersSnapshot.docs) {
    final userId = userDoc.id;
    
    // Initialize points if not exists
    if (!userDoc.data().containsKey('points')) {
      await userDoc.reference.update({'points': 0});
    }
    
    // Initialize user stats
    await LeaderboardService().initializeUserStats(userId);
  }
  
  print('Migration complete!');
}
```

### Step 4: Soft Launch
- [ ] Deploy to beta testers first
- [ ] Monitor Firebase logs
- [ ] Collect feedback
- [ ] Fix any issues
- [ ] Verify performance metrics

### Step 5: Full Launch
- [ ] Deploy to production
- [ ] Announce new feature
- [ ] Monitor user engagement
- [ ] Track error rates
- [ ] Collect user feedback

## Post-Deployment Monitoring

### Week 1: Critical Monitoring
- [ ] Check error rates in Firebase
- [ ] Monitor Firestore read/write counts
- [ ] Verify points are awarded correctly
- [ ] Check badge unlock rate
- [ ] Monitor leaderboard load times
- [ ] Review user feedback
- [ ] Track engagement metrics

### Week 2-4: Performance Tuning
- [ ] Analyze query performance
- [ ] Optimize slow queries
- [ ] Adjust point values if needed
- [ ] Fine-tune badge thresholds
- [ ] Address user feedback
- [ ] Monitor cost metrics

### Ongoing: Feature Enhancement
- [ ] Plan geographic leaderboards
- [ ] Design reward system
- [ ] Create weekly challenges
- [ ] Add social features
- [ ] Implement notifications

## Troubleshooting Guide

### Common Issues & Solutions

#### Points Not Updating
**Symptoms:** Users report issues but don't see points
**Check:**
- [ ] Firestore security rules allow writes
- [ ] Console logs for errors
- [ ] Network connectivity
- [ ] User document exists

**Fix:**
```dart
// Manually award points
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({'points': FieldValue.increment(10)});
```

#### Badges Not Unlocking
**Symptoms:** Users meet requirements but don't get badges
**Check:**
- [ ] userStats document exists
- [ ] earnedBadges array updates
- [ ] Badge check logic runs

**Fix:**
```dart
// Force badge check
await LeaderboardService()._checkAndAwardBadges(
  userId,
  FirebaseFirestore.instance.collection('userStats').doc(userId)
);
```

#### Leaderboard Empty
**Symptoms:** No users showing in leaderboard
**Check:**
- [ ] Users have role = 'Citizen'
- [ ] Points field exists on users
- [ ] Query limits are appropriate

**Fix:**
```dart
// Check if users have points field
final users = await FirebaseFirestore.instance
    .collection('users')
    .where('role', isEqualTo: 'Citizen')
    .get();

for (final doc in users.docs) {
  if (!doc.data().containsKey('points')) {
    await doc.reference.update({'points': 0});
  }
}
```

#### Slow Performance
**Symptoms:** Leaderboard takes long to load
**Check:**
- [ ] Indexes are created
- [ ] Query limits are set
- [ ] Network is fast

**Fix:**
- Create composite indexes
- Reduce limit from 100 to 50
- Implement pagination

## Success Metrics

### Track These KPIs

#### Engagement Metrics
- Daily active users viewing leaderboard
- Average time on leaderboard screen
- Number of achievement screen visits
- Badge unlock rate

#### Quality Metrics
- Reports per user (before vs after)
- User retention rate
- Feature adoption rate
- User satisfaction scores

#### Technical Metrics
- Firestore read/write counts
- Query execution times
- Error rates
- App performance scores

### Goals to Achieve

**Week 1:**
- [ ] 50% of users view leaderboard
- [ ] 25% of users unlock first badge
- [ ] 10% increase in reports

**Month 1:**
- [ ] 75% of active users engage with gamification
- [ ] Average 3 badges per active user
- [ ] 25% increase in overall reports
- [ ] 20% increase in user retention

**Month 3:**
- [ ] 90% adoption rate
- [ ] Multiple Diamond Legends
- [ ] Thriving competition
- [ ] Positive user feedback

## Documentation Links

For reference during deployment:

- **Technical Guide:** `LEADERBOARD_IMPLEMENTATION.md`
- **User Guide:** `LEADERBOARD_QUICK_START.md`
- **Overview:** `LEADERBOARD_SUMMARY.md`
- **This Checklist:** `LEADERBOARD_DEPLOYMENT_CHECKLIST.md`

## Support & Maintenance

### Regular Maintenance Tasks

**Weekly:**
- Review Firebase costs
- Check error logs
- Monitor performance

**Monthly:**
- Analyze engagement metrics
- Review user feedback
- Plan feature updates
- Adjust point values if needed

**Quarterly:**
- Major feature additions
- UI/UX improvements
- Performance optimization
- Community events

## Emergency Contacts

**Firebase Issues:**
- Firebase Console: https://console.firebase.google.com
- Firebase Support: https://firebase.google.com/support

**Flutter Issues:**
- Flutter Docs: https://flutter.dev/docs
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter

## Final Pre-Launch Checklist

Before you hit deploy, verify:

- [ ] ✅ All code is committed
- [ ] ✅ No linter errors
- [ ] ✅ Firebase rules updated
- [ ] ✅ Indexes created
- [ ] ✅ Tested on real device
- [ ] ✅ Documentation reviewed
- [ ] ✅ Backup plan ready
- [ ] ✅ Monitoring set up
- [ ] ✅ Team is informed
- [ ] ✅ Users are notified

## 🚀 You're Ready to Launch!

When all items above are checked, you're ready to deploy the leaderboard system and watch your user engagement soar!

**Good luck! 🎉**

---

**Questions?** Review the documentation or check Firebase logs for detailed error messages.

**Feedback?** Track user responses and iterate based on real usage patterns.

**Issues?** Use the troubleshooting guide above or check console logs.

