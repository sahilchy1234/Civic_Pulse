// Migration script to update existing verified solutions with isVerified field
// Run this script once to update existing solutions that have status='verified' but missing isVerified field

const firebaseConfig = {
    apiKey: 'AIzaSyDKOI5Kz0FgM58X0JmLbk32NxUMU_iXOgg',
    authDomain: 'civicsense-cca11-vnxyc.appspot.com',
    projectId: 'civicsense-cca11',
    storageBucket: 'civicsense-cca11-vnxyc.appspot.com',
    messagingSenderId: '911825802149',
    appId: '1:911825802149:web:54e85ddfb788626bae8e4c',
    measurementId: 'G-6BY32VCV3X'
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

async function migrateVerifiedSolutions() {
    try {
        console.log('🔄 Starting migration of verified solutions...');
        
        // Get all solutions with status='verified' but missing isVerified field
        const solutionsSnapshot = await db.collection('solutions')
            .where('status', '==', 'verified')
            .get();
        
        console.log(`📊 Found ${solutionsSnapshot.docs.length} solutions with status='verified'`);
        
        let updatedCount = 0;
        const batch = db.batch();
        
        for (const doc of solutionsSnapshot.docs) {
            const data = doc.data();
            
            // Check if isVerified field is missing or false
            if (!data.hasOwnProperty('isVerified') || data.isVerified === false) {
                console.log(`🔄 Updating solution ${doc.id}...`);
                
                batch.update(doc.ref, {
                    isVerified: true,
                    migratedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                updatedCount++;
            }
        }
        
        if (updatedCount > 0) {
            await batch.commit();
            console.log(`✅ Successfully updated ${updatedCount} solutions with isVerified=true`);
        } else {
            console.log('✅ No solutions needed migration');
        }
        
        console.log('🎉 Migration completed successfully!');
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
    }
}

// Run migration
migrateVerifiedSolutions();
