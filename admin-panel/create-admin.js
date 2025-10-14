// Run this script to create an admin user
// Usage: node create-admin.js

const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json'); // You'll need to download this

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const email = 'admin@civicsense.com';
const password = 'CivicAdmin2024!'; // Change this to your desired password

admin.auth().createUser({
  email: email,
  password: password,
  emailVerified: true,
  disabled: false
})
.then((userRecord) => {
  console.log('✅ Successfully created admin user:', userRecord.uid);
  console.log('📧 Email:', email);
  console.log('🔐 Password:', password);
  console.log('\nYou can now login to the admin panel with these credentials!');
  process.exit(0);
})
.catch((error) => {
  console.error('❌ Error creating user:', error);
  process.exit(1);
});

