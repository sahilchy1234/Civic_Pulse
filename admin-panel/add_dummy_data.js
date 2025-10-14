const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// You'll need to download your service account key from Firebase Console
// and place it in your project directory
let serviceAccount;
try {
  serviceAccount = require('./firebase-service-account-key.json');
} catch (error) {
  console.error('❌ ERROR: Firebase service account key not found!');
  console.error('');
  console.error('📋 SETUP REQUIRED:');
  console.error('1. Go to Firebase Console: https://console.firebase.google.com/');
  console.error('2. Select your project: civicsense-cca11');
  console.error('3. Go to Project Settings (gear icon) → Service Accounts');
  console.error('4. Click "Generate new private key"');
  console.error('5. Download the JSON file');
  console.error('6. Rename it to: firebase-service-account-key.json');
  console.error('7. Place it in the admin-panel directory');
  console.error('8. Run the script again: npm run add-dummy-data');
  console.error('');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // Your Firebase project database URL
  databaseURL: 'https://civicsense-cca11-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

// Dummy data for civic issues
const dummyIssues = [
  {
    title: "Large Pothole on Main Street",
    description: "There's a huge pothole near the intersection of Main Street and Oak Avenue. It's been there for weeks and is getting worse with each rain. Cars are swerving to avoid it, creating a traffic hazard.",
    issueType: "Pothole",
    location: { lat: 40.7128, lng: -74.0060 }, // New York City coordinates
    status: "Pending",
    userName: "John Smith",
    upvotes: 15,
    likedBy: ["user1", "user2", "user3", "user4", "user5"]
  },
  {
    title: "Broken Street Light",
    description: "The street light at the corner of Elm Street and Pine Road has been flickering for days and finally went out completely last night. This area is very dark and unsafe for pedestrians.",
    issueType: "Street Light",
    location: { lat: 40.7589, lng: -73.9851 },
    status: "In Progress",
    userName: "Sarah Johnson",
    upvotes: 8,
    likedBy: ["user2", "user6", "user7"]
  },
  {
    title: "Garbage Overflow",
    description: "The garbage bins in the park are overflowing and trash is scattered around. This has been going on for over a week and is attracting pests.",
    issueType: "Garbage",
    location: { lat: 40.7505, lng: -73.9934 },
    status: "Resolved",
    userName: "Mike Chen",
    upvotes: 12,
    likedBy: ["user1", "user3", "user8", "user9", "user10"],
    authorityNotes: "Garbage collection has been completed. New bins have been installed with better capacity."
  },
  {
    title: "Water Leak on Sidewalk",
    description: "There's a constant water leak from an underground pipe creating a large puddle on the sidewalk. Water is pooling and making the area slippery and dangerous.",
    issueType: "Water Leak",
    location: { lat: 40.7614, lng: -73.9776 },
    status: "Pending",
    userName: "Emily Rodriguez",
    upvotes: 6,
    likedBy: ["user4", "user11"]
  },
  {
    title: "Damaged Traffic Sign",
    description: "The stop sign at the intersection of 5th Avenue and Broadway is bent and barely visible. This is a major safety concern for drivers and pedestrians.",
    issueType: "Traffic",
    location: { lat: 40.7505, lng: -73.9934 },
    status: "In Progress",
    userName: "David Wilson",
    upvotes: 20,
    likedBy: ["user1", "user2", "user3", "user5", "user6", "user7", "user8", "user9", "user10", "user11", "user12", "user13", "user14", "user15", "user16", "user17", "user18", "user19", "user20"]
  },
  {
    title: "Sewage Backup",
    description: "Raw sewage is backing up from the manhole cover on 3rd Street. The smell is unbearable and it's a serious health hazard.",
    issueType: "Sewage",
    location: { lat: 40.6892, lng: -74.0445 },
    status: "Resolved",
    userName: "Lisa Brown",
    upvotes: 25,
    likedBy: ["user1", "user2", "user3", "user4", "user5", "user6", "user7", "user8", "user9", "user10", "user11", "user12", "user13", "user14", "user15", "user16", "user17", "user18", "user19", "user20", "user21", "user22", "user23", "user24", "user25"],
    authorityNotes: "Sewage line has been repaired and cleaned. Area has been sanitized."
  },
  {
    title: "Cracked Sidewalk",
    description: "Large cracks in the sidewalk on Washington Street are making it difficult for people with mobility issues to navigate safely.",
    issueType: "Road Damage",
    location: { lat: 40.7505, lng: -73.9934 },
    status: "Pending",
    userName: "Robert Taylor",
    upvotes: 9,
    likedBy: ["user2", "user5", "user8", "user12", "user15"]
  },
  {
    title: "Abandoned Vehicle",
    description: "An abandoned car has been parked in the same spot for over two weeks. It's blocking the fire hydrant and taking up valuable parking space.",
    issueType: "Other",
    location: { lat: 40.7128, lng: -74.0060 },
    status: "In Progress",
    userName: "Jennifer Davis",
    upvotes: 4,
    likedBy: ["user7", "user14"]
  },
  {
    title: "Overgrown Tree Branches",
    description: "Tree branches are hanging low over the sidewalk on Park Avenue, making it difficult for pedestrians to walk safely. Some branches are touching power lines.",
    issueType: "Other",
    location: { lat: 40.7589, lng: -73.9851 },
    status: "Resolved",
    userName: "Thomas Anderson",
    upvotes: 7,
    likedBy: ["user3", "user6", "user9", "user13", "user16"],
    authorityNotes: "Tree branches have been trimmed by the city arborist. Power lines are now clear."
  },
  {
    title: "Broken Bench in Park",
    description: "One of the park benches near the playground is broken and unsafe to sit on. The wood is splintered and could cause injury.",
    issueType: "Other",
    location: { lat: 40.7505, lng: -73.9934 },
    status: "Pending",
    userName: "Maria Garcia",
    upvotes: 3,
    likedBy: ["user4", "user10"]
  }
];

// Random image URLs for different issue types - Specific civic infrastructure images
const imageUrls = {
  "Pothole": [
    "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1574267432553-4b4628081c31?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1581833971358-2c8b550f87b3?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=500&h=300&fit=crop&auto=format"
  ],
  "Street Light": [
    "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=500&h=300&fit=crop&auto=format"
  ],
  "Garbage": [
    "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500&h=300&fit=crop&auto=format"
  ],
  "Water Leak": [
    "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1581833971358-2c8b550f87b3?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1574267432553-4b4628081c31?w=500&h=300&fit=crop&auto=format"
  ],
  "Traffic": [
    "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500&h=300&fit=crop&auto=format"
  ],
  "Sewage": [
    "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1581833971358-2c8b550f87b3?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1574267432553-4b4628081c31?w=500&h=300&fit=crop&auto=format"
  ],
  "Road Damage": [
    "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1574267432553-4b4628081c31?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1581833971358-2c8b550f87b3?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=500&h=300&fit=crop&auto=format"
  ],
  "Other": [
    "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&h=300&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=500&h=300&fit=crop&auto=format"
  ]
};

// User profile images - More diverse and professional avatars
const userProfileImages = [
  "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1507591064344-4c6ce005b128?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1566492031773-4f4e44671d66?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=100&h=100&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1552058544-f2b08422138a?w=100&h=100&fit=crop&crop=face"
];

// Dummy users
const dummyUsers = [
  { name: "John Smith", email: "john.smith@email.com", role: "Citizen" },
  { name: "Sarah Johnson", email: "sarah.johnson@email.com", role: "Citizen" },
  { name: "Mike Chen", email: "mike.chen@email.com", role: "Citizen" },
  { name: "Emily Rodriguez", email: "emily.rodriguez@email.com", role: "Citizen" },
  { name: "David Wilson", email: "david.wilson@email.com", role: "Citizen" },
  { name: "Lisa Brown", email: "lisa.brown@email.com", role: "Citizen" },
  { name: "Robert Taylor", email: "robert.taylor@email.com", role: "Citizen" },
  { name: "Jennifer Davis", email: "jennifer.davis@email.com", role: "Citizen" },
  { name: "Thomas Anderson", email: "thomas.anderson@email.com", role: "Citizen" },
  { name: "Maria Garcia", email: "maria.garcia@email.com", role: "Citizen" },
  { name: "City Admin", email: "admin@city.gov", role: "Authority" },
  { name: "Public Works Manager", email: "works@city.gov", role: "Authority" }
];

async function addDummyData() {
  try {
    console.log('🔥 Starting to add dummy data to Firebase...');

    // Add dummy users first
    console.log('👥 Adding dummy users...');
    const userIds = [];
    
    for (let i = 0; i < dummyUsers.length; i++) {
      const user = dummyUsers[i];
      const userId = `user_${i + 1}`;
      
      const userData = {
        id: userId,
        name: user.name,
        email: user.email,
        role: user.role,
        points: Math.floor(Math.random() * 500) + 50, // Random points between 50-550
        profileImageUrl: userProfileImages[i % userProfileImages.length],
        createdAt: Date.now() - Math.floor(Math.random() * 30 * 24 * 60 * 60 * 1000) // Random date within last 30 days
      };

      await db.collection('users').doc(userId).set(userData);
      userIds.push(userId);
      console.log(`✅ Added user: ${user.name}`);
    }

    // Add dummy issues
    console.log('📝 Adding dummy issues...');
    
    for (let i = 0; i < dummyIssues.length; i++) {
      const issue = dummyIssues[i];
      const issueId = `issue_${i + 1}`;
      
      // Get random image for the issue type
      const availableImages = imageUrls[issue.issueType] || imageUrls["Other"];
      const randomImage = availableImages[Math.floor(Math.random() * availableImages.length)];
      
      // Get random user ID (excluding authority users for issue creation)
      const citizenUserIds = userIds.filter((id, index) => dummyUsers[index].role === 'Citizen');
      const randomUserId = citizenUserIds[Math.floor(Math.random() * citizenUserIds.length)];
      
      const issueData = {
        id: issueId,
        userId: randomUserId,
        userName: issue.userName,
        userProfileImageUrl: userProfileImages[Math.floor(Math.random() * userProfileImages.length)],
        title: issue.title,
        description: issue.description,
        issueType: issue.issueType,
        location: issue.location,
        imageUrl: randomImage,
        status: issue.status,
        createdAt: Date.now() - Math.floor(Math.random() * 14 * 24 * 60 * 60 * 1000), // Random date within last 14 days
        updatedAt: Date.now() - Math.floor(Math.random() * 7 * 24 * 60 * 60 * 1000), // Random date within last 7 days
        upvotes: issue.upvotes,
        likedBy: issue.likedBy,
        authorityNotes: issue.authorityNotes || null,
        resolvedImageUrl: issue.status === 'Resolved' ? randomImage : null
      };

      await db.collection('issues').doc(issueId).set(issueData);
      console.log(`✅ Added issue: ${issue.title}`);
    }

    console.log('🎉 Successfully added all dummy data to Firebase!');
    console.log(`📊 Added ${dummyUsers.length} users and ${dummyIssues.length} issues`);

  } catch (error) {
    console.error('❌ Error adding dummy data:', error);
  } finally {
    process.exit(0);
  }
}

// Run the script
addDummyData();
