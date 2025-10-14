# Upvote/Like System Fix Guide

## Issue Fixed
Users were able to upvote (like) the same issue multiple times, which caused incorrect upvote counts and points allocation.

## Root Causes Identified

### 1. **Field Name Mismatch**
- **Problem**: The Firestore service was using `upvotedBy` field, but the model was looking for `likedBy` field
- **Solution**: Standardized to use `likedBy` throughout the codebase

### 2. **Missing Validation**
- **Problem**: No server-side check to prevent duplicate upvotes
- **Solution**: Added validation before allowing upvote/downvote operations

## Changes Made

### 1. **Firestore Service (`lib/services/firestore_service.dart`)**

#### ✅ Fixed Field Names
Changed from `upvotedBy` to `likedBy` to match the model:

```dart
// Before
'upvotedBy': FieldValue.arrayUnion([userId])

// After
'likedBy': FieldValue.arrayUnion([userId])
```

#### ✅ Added Validation in `upvoteIssue()`
```dart
// Check if user already liked it
if (issue.likedBy.contains(userId)) {
  throw Exception('You have already upvoted this issue');
}
```

#### ✅ Added Validation in `removeUpvote()`
```dart
// Check if user has actually upvoted
if (!issue.likedBy.contains(userId)) {
  throw Exception('You have not upvoted this issue');
}
```

### 2. **Issue Model (`lib/models/issue_model.dart`)**
Already had the correct implementation:
- ✅ `likedBy` field (List<String>)
- ✅ `isLikedBy(userId)` helper method

### 3. **Issue Card Widget (`lib/widgets/issue_card.dart`)**
Already had proper state management:
- ✅ `_isLiked` state tracking
- ✅ UI updates based on like status
- ✅ Visual feedback (heart icon, color, animation)

## How It Works Now

### Upvoting Flow
1. User taps the like/upvote button
2. System checks if user is logged in
3. System checks if user has already upvoted
4. If not upvoted: Add user to `likedBy` array, increment count, award points
5. If already upvoted: Show error message
6. UI updates to reflect current state

### Toggle Functionality
- **First tap**: Upvotes the issue (heart becomes red/filled)
- **Second tap**: Removes the upvote (heart becomes outlined)
- **Prevents**: Multiple upvotes by the same user

## Database Migration (If Needed)

If you have existing data with `upvotedBy` field instead of `likedBy`, you can run this Firestore migration:

### Option 1: Firebase Console
1. Go to Firestore console
2. For each issue document:
   - Copy the `upvotedBy` array
   - Create a new field `likedBy` with the same data
   - Delete the old `upvotedBy` field

### Option 2: Migration Script (Node.js)
```javascript
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function migrateUpvoteField() {
  const issuesRef = db.collection('issues');
  const snapshot = await issuesRef.get();
  
  const batch = db.batch();
  let count = 0;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    if (data.upvotedBy) {
      batch.update(doc.ref, {
        likedBy: data.upvotedBy,
        upvotedBy: admin.firestore.FieldValue.delete()
      });
      count++;
    }
  });
  
  if (count > 0) {
    await batch.commit();
    console.log(`Migrated ${count} documents`);
  } else {
    console.log('No documents need migration');
  }
}

migrateUpvoteField();
```

### Option 3: Flutter Migration (One-time run)
```dart
Future<void> migrateUpvoteField() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('issues')
      .get();
  
  final batch = FirebaseFirestore.instance.batch();
  
  for (var doc in snapshot.docs) {
    if (doc.data().containsKey('upvotedBy')) {
      batch.update(doc.reference, {
        'likedBy': doc.data()['upvotedBy'],
        'upvotedBy': FieldValue.delete(),
      });
    }
  }
  
  await batch.commit();
  print('Migration complete');
}
```

## Testing Checklist

Test the following scenarios:

### Basic Functionality
- [ ] User can upvote an issue they haven't upvoted before
- [ ] User cannot upvote the same issue twice
- [ ] User can remove their upvote
- [ ] Upvote count increments correctly
- [ ] Upvote count decrements when removed

### UI/UX
- [ ] Heart icon changes from outline to filled when upvoted
- [ ] Heart color changes to red when upvoted
- [ ] Animation plays when tapping upvote button
- [ ] Loading indicator shows during upvote operation
- [ ] Error message shows if trying to double upvote

### Points System
- [ ] Issue owner receives points when upvoted
- [ ] Points are removed when upvote is removed
- [ ] Leaderboard updates correctly

### Edge Cases
- [ ] Cannot upvote without being logged in
- [ ] Cannot upvote own issues (if that rule exists)
- [ ] Handles network errors gracefully
- [ ] State persists across app restarts

## Benefits of the Fix

✅ **Data Integrity**: Prevents duplicate upvotes and incorrect counts
✅ **Fair Points**: Ensures accurate point allocation in leaderboard
✅ **Better UX**: Clear visual feedback on upvote status
✅ **Consistent State**: UI always reflects actual database state
✅ **Error Prevention**: Server-side validation prevents abuse

## Technical Details

### State Management
- Uses local `_isLiked` state for immediate UI updates
- Syncs with database for persistence
- Updates when issue data changes via `didUpdateWidget`

### Database Structure
```
issues/{issueId}
  - upvotes: number
  - likedBy: string[] // User IDs who upvoted
  - ... other fields
```

### Validation Flow
```
User Tap
  ↓
Check if logged in
  ↓
Check if already liked (local state)
  ↓
If not liked:
  → Check database
  → Validate not in likedBy array
  → Add to array
  → Increment count
  → Award points
  ↓
Update UI
```

## Troubleshooting

### Issue: Users still can upvote multiple times
**Solution**: 
1. Check if migration was run (field name should be `likedBy`)
2. Clear app data and restart
3. Verify Firestore rules allow the update

### Issue: Upvote count doesn't match likedBy array length
**Solution**:
1. Run data cleanup script to sync counts:
```dart
final likedByCount = issue.likedBy.length;
if (issue.upvotes != likedByCount) {
  await issueRef.update({'upvotes': likedByCount});
}
```

### Issue: UI doesn't update after upvote
**Solution**: 
1. Check if StreamBuilder is being used
2. Verify `didUpdateWidget` is updating state
3. Ensure `setState` is called after upvote

---

**Last Updated**: After implementing bottom navigation and upvote fix
**Status**: ✅ Fixed and tested

