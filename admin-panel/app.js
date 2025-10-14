// Firebase Configuration
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
const auth = firebase.auth();
const db = firebase.firestore();

// Global Variables
let allIssues = [];
let allSolutions = [];
let currentView = 'overview';
let currentUser = null;

// Map Variables
let mainMap = null;
let mapMarkers = [];
let markerClusterGroup = null;
let heatmapLayer = null;
let currentMapView = 'markers'; // 'markers', 'cluster', or 'heat'

// DOM Elements
const loginScreen = document.getElementById('loginScreen');
const dashboard = document.getElementById('dashboard');
const loginForm = document.getElementById('loginForm');
const loginError = document.getElementById('loginError');
const logoutBtn = document.getElementById('logoutBtn');
const navItems = document.querySelectorAll('.nav-item');
const pageTitle = document.getElementById('pageTitle');
const userEmail = document.getElementById('userEmail');
const overviewSection = document.getElementById('overviewSection');
const issuesSection = document.getElementById('issuesSection');
const mapSection = document.getElementById('mapSection');
const issuesGrid = document.getElementById('issuesGrid');
const searchInput = document.getElementById('searchInput');
const statusFilter = document.getElementById('statusFilter');
const typeFilter = document.getElementById('typeFilter');
const sortBy = document.getElementById('sortBy');
const loadingSpinner = document.getElementById('loadingSpinner');
const issueModal = document.getElementById('issueModal');

// Solutions DOM Elements
const solutionsSection = document.getElementById('solutionsSection');
const solutionsGrid = document.getElementById('solutionsGrid');
const solutionsLoadingSpinner = document.getElementById('solutionsLoadingSpinner');
const solutionModal = document.getElementById('solutionModal');
const solutionModalBody = document.getElementById('solutionModalBody');
const pendingSolutionsCount = document.getElementById('pendingSolutionsCount');
const verifiedSolutionsCount = document.getElementById('verifiedSolutionsCount');
const rejectedSolutionsCount = document.getElementById('rejectedSolutionsCount');
const solutionStatusFilter = document.getElementById('solutionStatusFilter');
const solutionTypeFilter = document.getElementById('solutionTypeFilter');
const solutionSearchInput = document.getElementById('solutionSearchInput');

// Authentication
auth.onAuthStateChanged((user) => {
    if (user) {
        currentUser = user;
        loginScreen.style.display = 'none';
        dashboard.style.display = 'flex';
        userEmail.textContent = user.email;
        loadDashboard();
    } else {
        loginScreen.style.display = 'flex';
        dashboard.style.display = 'none';
    }
});

// Login Form Handler
loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    try {
        await auth.signInWithEmailAndPassword(email, password);
    } catch (error) {
        loginError.textContent = error.message;
        loginError.classList.add('show');
    }
});

// Logout Handler
logoutBtn.addEventListener('click', async () => {
    try {
        await auth.signOut();
    } catch (error) {
        console.error('Logout error:', error);
    }
});

// Navigation Handler
navItems.forEach(item => {
    item.addEventListener('click', (e) => {
        e.preventDefault();
        navItems.forEach(nav => nav.classList.remove('active'));
        item.classList.add('active');
        
        const view = item.getAttribute('data-view');
        currentView = view;
        switchView(view);
    });
});

// Switch View
function switchView(view) {
    overviewSection.style.display = 'none';
    issuesSection.style.display = 'none';
    mapSection.style.display = 'none';
    solutionsSection.style.display = 'none';

    switch(view) {
        case 'overview':
            pageTitle.textContent = 'Overview';
            overviewSection.style.display = 'block';
            break;
        case 'map':
            pageTitle.textContent = 'Issue Hotspot Map';
            mapSection.style.display = 'block';
            initializeMap();
            break;
        case 'issues':
            pageTitle.textContent = 'All Issues';
            issuesSection.style.display = 'block';
            statusFilter.value = 'all';
            filterAndDisplayIssues();
            break;
        case 'pending':
            pageTitle.textContent = 'Pending Issues';
            issuesSection.style.display = 'block';
            statusFilter.value = 'Pending';
            filterAndDisplayIssues();
            break;
        case 'in-progress':
            pageTitle.textContent = 'In Progress Issues';
            issuesSection.style.display = 'block';
            statusFilter.value = 'In Progress';
            filterAndDisplayIssues();
            break;
        case 'resolved':
            pageTitle.textContent = 'Resolved Issues';
            issuesSection.style.display = 'block';
            statusFilter.value = 'Resolved';
            filterAndDisplayIssues();
            break;
        case 'solutions':
            pageTitle.textContent = 'Solutions Management';
            solutionsSection.style.display = 'block';
            loadSolutions();
            break;
    }
}

// Load Dashboard
async function loadDashboard() {
    try {
        loadingSpinner.style.display = 'flex';
        
        // Load all issues from Firestore
        const issuesSnapshot = await db.collection('issues').get();
        allIssues = issuesSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        // Update statistics
        updateStatistics();
        updateCharts();
        updateRecentActivity();
        populateTypeFilter();
        filterAndDisplayIssues();

        loadingSpinner.style.display = 'none';
    } catch (error) {
        console.error('Error loading dashboard:', error);
        loadingSpinner.style.display = 'none';
    }
}

// Update Statistics
function updateStatistics() {
    const pending = allIssues.filter(i => i.status === 'Pending').length;
    const inProgress = allIssues.filter(i => i.status === 'In Progress').length;
    const resolved = allIssues.filter(i => i.status === 'Resolved').length;
    const total = allIssues.length;

    document.getElementById('pendingCount').textContent = pending;
    document.getElementById('inProgressCount').textContent = inProgress;
    document.getElementById('resolvedCount').textContent = resolved;
    document.getElementById('totalCount').textContent = total;
}

// Update Charts
function updateCharts() {
    const issuesByType = {};
    allIssues.forEach(issue => {
        const type = issue.issueType || 'Other';
        issuesByType[type] = (issuesByType[type] || 0) + 1;
    });

    const chartContainer = document.getElementById('issueTypeChart');
    chartContainer.innerHTML = '';

    Object.entries(issuesByType).forEach(([type, count]) => {
        const percentage = (count / allIssues.length * 100).toFixed(1);
        const bar = document.createElement('div');
        bar.style.cssText = `
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px;
            margin-bottom: 12px;
            background: var(--light-bg);
            border-radius: 8px;
        `;
        bar.innerHTML = `
            <span style="font-weight: 600;">${type}</span>
            <span style="color: var(--text-secondary);">${count} (${percentage}%)</span>
        `;
        chartContainer.appendChild(bar);
    });
}

// Update Recent Activity
function updateRecentActivity() {
    const recentIssues = [...allIssues]
        .sort((a, b) => b.createdAt - a.createdAt)
        .slice(0, 5);

    const activityList = document.getElementById('recentActivity');
    activityList.innerHTML = '';

    if (recentIssues.length === 0) {
        activityList.innerHTML = '<p style="color: var(--text-secondary);">No recent activity</p>';
        return;
    }

    recentIssues.forEach(issue => {
        const item = document.createElement('div');
        item.className = 'activity-item';
        const date = new Date(issue.createdAt);
        item.innerHTML = `
            <h4>${issue.title}</h4>
            <p>${issue.issueType} • ${getStatusEmoji(issue.status)} ${issue.status} • ${formatDate(date)}</p>
        `;
        activityList.appendChild(item);
    });
}

// Populate Type Filter
function populateTypeFilter() {
    const types = new Set(allIssues.map(i => i.issueType).filter(Boolean));
    typeFilter.innerHTML = '<option value="all">All Types</option>';
    types.forEach(type => {
        const option = document.createElement('option');
        option.value = type;
        option.textContent = type;
        typeFilter.appendChild(option);
    });
}

// Filter and Display Issues
function filterAndDisplayIssues() {
    const searchTerm = searchInput.value.toLowerCase();
    const statusValue = statusFilter.value;
    const typeValue = typeFilter.value;
    const sortValue = sortBy.value;

    let filtered = allIssues.filter(issue => {
        const matchesSearch = issue.title.toLowerCase().includes(searchTerm) || 
                             issue.description.toLowerCase().includes(searchTerm);
        const matchesStatus = statusValue === 'all' || issue.status === statusValue;
        const matchesType = typeValue === 'all' || issue.issueType === typeValue;
        return matchesSearch && matchesStatus && matchesType;
    });

    // Sort issues
    filtered.sort((a, b) => {
        switch(sortValue) {
            case 'newest':
                return b.createdAt - a.createdAt;
            case 'oldest':
                return a.createdAt - b.createdAt;
            case 'upvotes':
                return (b.upvotes || 0) - (a.upvotes || 0);
            default:
                return 0;
        }
    });

    displayIssues(filtered);
}

// Display Issues
function displayIssues(issues) {
    issuesGrid.innerHTML = '';

    if (issues.length === 0) {
        issuesGrid.innerHTML = `
            <div class="no-issues">
                <h3>No issues found</h3>
                <p>Try adjusting your filters</p>
            </div>
        `;
        return;
    }

    issues.forEach(issue => {
        const card = createIssueCard(issue);
        issuesGrid.appendChild(card);
    });
}

// Create Issue Card
function createIssueCard(issue) {
    const card = document.createElement('div');
    card.className = 'issue-card';
    card.onclick = () => openIssueModal(issue);

    const date = new Date(issue.createdAt);
    const statusClass = issue.status.toLowerCase().replace(' ', '-');

    card.innerHTML = `
        ${issue.imageUrl ? `<img src="${issue.imageUrl}" alt="${issue.title}" class="issue-image">` : ''}
        <div class="issue-content">
            <div class="issue-header">
                <div>
                    <h3 class="issue-title">${issue.title}</h3>
                    <span class="issue-type">${issue.issueType || 'Other'}</span>
                </div>
                <span class="status-badge ${statusClass}">${getStatusEmoji(issue.status)} ${issue.status}</span>
            </div>
            <p class="issue-description">${issue.description}</p>
            <div class="issue-meta">
                <span>${formatDate(date)}</span>
                <span class="issue-upvotes">👍 ${issue.upvotes || 0}</span>
            </div>
        </div>
    `;

    return card;
}

// Open Issue Modal
function openIssueModal(issue) {
    const modalBody = document.getElementById('modalBody');
    const date = new Date(issue.createdAt);
    const statusClass = issue.status.toLowerCase().replace(' ', '-');

    modalBody.innerHTML = `
        <div class="detail-section">
            ${issue.imageUrl ? `<img src="${issue.imageUrl}" alt="${issue.title}" class="detail-image">` : ''}
            <h3>${issue.title}</h3>
            <span class="status-badge ${statusClass}">${getStatusEmoji(issue.status)} ${issue.status}</span>
        </div>

        <div class="detail-section">
            <div class="detail-grid">
                <div class="detail-item">
                    <span class="detail-label">Type</span>
                    <span class="detail-value">${issue.issueType || 'Not specified'}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Created</span>
                    <span class="detail-value">${formatDate(date)}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Upvotes</span>
                    <span class="detail-value">👍 ${issue.upvotes || 0}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Issue ID</span>
                    <span class="detail-value">${issue.id}</span>
                </div>
            </div>
        </div>

        <div class="detail-section">
            <h3>Description</h3>
            <p>${issue.description}</p>
        </div>

        ${issue.location ? `
            <div class="detail-section">
                <h3>Location</h3>
                <div class="detail-grid">
                    <div class="detail-item">
                        <span class="detail-label">Latitude</span>
                        <span class="detail-value">${issue.location.lat}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Longitude</span>
                        <span class="detail-value">${issue.location.lng}</span>
                    </div>
                </div>
                <div id="issueMap" class="map-container"></div>
            </div>
        ` : ''}

        ${issue.authorityNotes ? `
            <div class="detail-section">
                <h3>Authority Notes</h3>
                <p style="padding: 12px; background: var(--light-bg); border-radius: 8px;">${issue.authorityNotes}</p>
            </div>
        ` : ''}

        ${issue.resolvedImageUrl ? `
            <div class="detail-section">
                <h3>Resolved Image</h3>
                <img src="${issue.resolvedImageUrl}" alt="Resolved" class="detail-image">
            </div>
        ` : ''}

        <div class="detail-section">
            <h3>Actions</h3>
            <div class="action-buttons">
                <button class="btn btn-pending" onclick="updateIssueStatus('${issue.id}', 'Pending')">
                    ⏳ Mark as Pending
                </button>
                <button class="btn btn-in-progress" onclick="updateIssueStatus('${issue.id}', 'In Progress')">
                    🔧 Mark as In Progress
                </button>
                <button class="btn btn-resolved" onclick="updateIssueStatus('${issue.id}', 'Resolved')">
                    ✅ Mark as Resolved
                </button>
            </div>
        </div>

        <div class="detail-section notes-section">
            <h3>Authority Notes</h3>
            <textarea id="authorityNotes" placeholder="Add notes about this issue...">${issue.authorityNotes || ''}</textarea>
            <button class="btn btn-save" onclick="saveAuthorityNotes('${issue.id}')">
                Save Notes
            </button>
        </div>
    `;

    issueModal.classList.add('show');

    // Initialize map if location exists
    if (issue.location) {
        setTimeout(() => {
            const map = L.map('issueMap').setView([issue.location.lat, issue.location.lng], 15);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors'
            }).addTo(map);
            L.marker([issue.location.lat, issue.location.lng]).addTo(map);
        }, 100);
    }
}

// Close Modal
function closeModal() {
    issueModal.classList.remove('show');
}

// Update Issue Status
async function updateIssueStatus(issueId, newStatus) {
    try {
        await db.collection('issues').doc(issueId).update({
            status: newStatus,
            updatedAt: Date.now()
        });

        // Update local data
        const issue = allIssues.find(i => i.id === issueId);
        if (issue) {
            issue.status = newStatus;
            issue.updatedAt = Date.now();
        }

        updateStatistics();
        filterAndDisplayIssues();
        closeModal();

        // Show success message
        alert(`Issue status updated to "${newStatus}"`);
    } catch (error) {
        console.error('Error updating status:', error);
        alert('Error updating status. Please try again.');
    }
}

// Save Authority Notes
async function saveAuthorityNotes(issueId) {
    const notes = document.getElementById('authorityNotes').value;
    
    try {
        await db.collection('issues').doc(issueId).update({
            authorityNotes: notes,
            updatedAt: Date.now()
        });

        // Update local data
        const issue = allIssues.find(i => i.id === issueId);
        if (issue) {
            issue.authorityNotes = notes;
            issue.updatedAt = Date.now();
        }

        alert('Notes saved successfully!');
    } catch (error) {
        console.error('Error saving notes:', error);
        alert('Error saving notes. Please try again.');
    }
}

// Helper Functions
function formatDate(date) {
    // Handle Firestore timestamps
    let actualDate;
    if (date && typeof date.toDate === 'function') {
        actualDate = date.toDate();
    } else if (date && date.seconds) {
        actualDate = new Date(date.seconds * 1000);
    } else if (date instanceof Date) {
        actualDate = date;
    } else if (typeof date === 'number') {
        actualDate = new Date(date);
    } else {
        actualDate = new Date(date);
    }
    
    // Check if date is valid
    if (isNaN(actualDate.getTime())) {
        return 'Invalid date';
    }
    
    const now = new Date();
    const diff = now - actualDate;
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    
    if (days === 0) return 'Today';
    if (days === 1) return 'Yesterday';
    if (days < 7) return `${days} days ago`;
    
    return actualDate.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

function getStatusEmoji(status) {
    switch(status) {
        case 'Pending': return '⏳';
        case 'In Progress': return '🔧';
        case 'Resolved': return '✅';
        default: return '❓';
    }
}

// Notification function
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${type === 'success' ? '#10B981' : type === 'error' ? '#EF4444' : '#3B82F6'};
        color: white;
        padding: 12px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        z-index: 10000;
        font-weight: 500;
        max-width: 300px;
        transform: translateX(100%);
        transition: transform 0.3s ease;
    `;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Auto remove after 4 seconds
    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 4000);
}

// Event Listeners for Filters
searchInput.addEventListener('input', filterAndDisplayIssues);
statusFilter.addEventListener('change', filterAndDisplayIssues);
typeFilter.addEventListener('change', filterAndDisplayIssues);
sortBy.addEventListener('change', filterAndDisplayIssues);

// Close modal when clicking outside
issueModal.addEventListener('click', (e) => {
    if (e.target === issueModal) {
        closeModal();
    }
});

// Real-time updates
db.collection('issues').onSnapshot((snapshot) => {
    snapshot.docChanges().forEach((change) => {
        const issueData = { id: change.doc.id, ...change.doc.data() };
        
        if (change.type === 'added') {
            const exists = allIssues.find(i => i.id === issueData.id);
            if (!exists) {
                allIssues.push(issueData);
            }
        }
        if (change.type === 'modified') {
            const index = allIssues.findIndex(i => i.id === issueData.id);
            if (index !== -1) {
                allIssues[index] = issueData;
            }
        }
        if (change.type === 'removed') {
            allIssues = allIssues.filter(i => i.id !== issueData.id);
        }
    });

    updateStatistics();
    updateCharts();
    updateRecentActivity();
    filterAndDisplayIssues();
    
    // Update map if it's currently visible
    if (currentView === 'map' && mainMap) {
        updateMapDisplay();
    }
});

// ==================== MAP FUNCTIONS ====================

// Initialize Map
function initializeMap() {
    if (mainMap) {
        updateMapDisplay();
        return;
    }

    // Default center (can be adjusted based on your region)
    const defaultCenter = [20.5937, 78.9629]; // India center
    const defaultZoom = 5;

    // Create map
    mainMap = L.map('mainMap').setView(defaultCenter, defaultZoom);

    // Add tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 18
    }).addTo(mainMap);

    // Initialize marker cluster group
    markerClusterGroup = L.markerClusterGroup({
        maxClusterRadius: 50,
        spiderfyOnMaxZoom: true,
        showCoverageOnHover: false,
        zoomToBoundsOnClick: true
    });

    // Load initial markers
    updateMapDisplay();

    // Auto-fit bounds to show all markers if any exist
    setTimeout(() => {
        if (mapMarkers.length > 0) {
            const group = L.featureGroup(mapMarkers);
            mainMap.fitBounds(group.getBounds().pad(0.1));
        }
    }, 500);
}

// Set Map View Mode
function setMapView(viewType) {
    currentMapView = viewType;

    // Update button states
    document.getElementById('markerViewBtn').classList.remove('active');
    document.getElementById('clusterViewBtn').classList.remove('active');
    document.getElementById('heatViewBtn').classList.remove('active');

    if (viewType === 'markers') {
        document.getElementById('markerViewBtn').classList.add('active');
    } else if (viewType === 'cluster') {
        document.getElementById('clusterViewBtn').classList.add('active');
    } else if (viewType === 'heat') {
        document.getElementById('heatViewBtn').classList.add('active');
    }

    updateMapDisplay();
}

// Update Map Filters
function updateMapFilters() {
    updateMapDisplay();
}

// Update Map Display
function updateMapDisplay() {
    if (!mainMap) return;

    // Get filter states
    const showPending = document.getElementById('showPending')?.checked ?? true;
    const showInProgress = document.getElementById('showInProgress')?.checked ?? true;
    const showResolved = document.getElementById('showResolved')?.checked ?? true;

    // Filter issues based on status and location
    const filteredIssues = allIssues.filter(issue => {
        if (!issue.location || !issue.location.lat || !issue.location.lng) return false;
        
        if (issue.status === 'Pending' && !showPending) return false;
        if (issue.status === 'In Progress' && !showInProgress) return false;
        if (issue.status === 'Resolved' && !showResolved) return false;
        
        return true;
    });

    // Clear existing markers and layers
    mapMarkers.forEach(marker => mainMap.removeLayer(marker));
    mapMarkers = [];
    
    if (markerClusterGroup) {
        markerClusterGroup.clearLayers();
        mainMap.removeLayer(markerClusterGroup);
    }
    
    if (heatmapLayer) {
        mainMap.removeLayer(heatmapLayer);
        heatmapLayer = null;
    }

    // Update statistics
    const totalIssues = allIssues.filter(i => i.location && i.location.lat && i.location.lng).length;
    document.getElementById('mapTotalIssues').textContent = totalIssues;
    document.getElementById('mapVisibleIssues').textContent = filteredIssues.length;

    // Display based on view mode
    if (currentMapView === 'markers') {
        displayMarkersView(filteredIssues);
    } else if (currentMapView === 'cluster') {
        displayClusterView(filteredIssues);
    } else if (currentMapView === 'heat') {
        displayHeatmapView(filteredIssues);
    }

    // Calculate and display hotspot
    calculateHotspot(filteredIssues);
}

// Display Markers View
function displayMarkersView(issues) {
    issues.forEach(issue => {
        const marker = createCustomMarker(issue);
        marker.addTo(mainMap);
        mapMarkers.push(marker);
    });
}

// Display Cluster View
function displayClusterView(issues) {
    issues.forEach(issue => {
        const marker = createCustomMarker(issue);
        markerClusterGroup.addLayer(marker);
    });
    
    mainMap.addLayer(markerClusterGroup);
}

// Display Heatmap View
function displayHeatmapView(issues) {
    if (issues.length === 0) return;

    const heatData = issues.map(issue => {
        const intensity = issue.upvotes ? Math.min(issue.upvotes / 10, 1) : 0.5;
        return [issue.location.lat, issue.location.lng, intensity];
    });

    heatmapLayer = L.heatLayer(heatData, {
        radius: 25,
        blur: 35,
        maxZoom: 17,
        max: 1.0,
        gradient: {
            0.0: '#3B82F6',
            0.5: '#F59E0B',
            1.0: '#EF4444'
        }
    }).addTo(mainMap);
}

// Create Custom Marker
function createCustomMarker(issue) {
    const statusClass = issue.status.toLowerCase().replace(' ', '-');
    const color = getMarkerColor(issue.status);
    
    // Create custom icon
    const customIcon = L.divIcon({
        className: 'custom-div-icon',
        html: `<div class="custom-marker ${statusClass}"></div>`,
        iconSize: [30, 30],
        iconAnchor: [15, 15]
    });

    const marker = L.marker([issue.location.lat, issue.location.lng], { 
        icon: customIcon 
    });

    // Create popup content
    const popupContent = `
        <div style="min-width: 200px;">
            <h4 style="margin: 0 0 8px 0; font-size: 1rem;">${issue.title}</h4>
            <p style="margin: 0 0 8px 0; color: #666; font-size: 0.85rem;">
                ${issue.description.substring(0, 100)}${issue.description.length > 100 ? '...' : ''}
            </p>
            <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 8px;">
                <span style="font-size: 0.85rem; color: #888;">
                    ${getStatusEmoji(issue.status)} ${issue.status}
                </span>
                <span style="font-size: 0.85rem; color: #888;">
                    👍 ${issue.upvotes || 0}
                </span>
            </div>
            <button onclick="openIssueFromMap('${issue.id}')" 
                    style="width: 100%; margin-top: 10px; padding: 8px; background: #4F46E5; 
                           color: white; border: none; border-radius: 4px; cursor: pointer; 
                           font-weight: 600;">
                View Details
            </button>
        </div>
    `;

    marker.bindPopup(popupContent);
    
    return marker;
}

// Open Issue from Map
function openIssueFromMap(issueId) {
    const issue = allIssues.find(i => i.id === issueId);
    if (issue) {
        openIssueModal(issue);
    }
}

// Get Marker Color
function getMarkerColor(status) {
    switch(status) {
        case 'Pending': return '#F59E0B';
        case 'In Progress': return '#3B82F6';
        case 'Resolved': return '#10B981';
        default: return '#6B7280';
    }
}

// Calculate Hotspot
function calculateHotspot(issues) {
    if (issues.length === 0) {
        document.getElementById('mapHotspot').textContent = '-';
        return;
    }

    // Simple grid-based clustering to find hotspot
    const gridSize = 0.1; // approximately 11km
    const grid = {};

    issues.forEach(issue => {
        const gridLat = Math.floor(issue.location.lat / gridSize);
        const gridLng = Math.floor(issue.location.lng / gridSize);
        const key = `${gridLat},${gridLng}`;
        
        if (!grid[key]) {
            grid[key] = {
                count: 0,
                lat: issue.location.lat,
                lng: issue.location.lng,
                issues: []
            };
        }
        
        grid[key].count++;
        grid[key].issues.push(issue);
    });

    // Find grid cell with most issues
    let maxCount = 0;
    let hotspotCell = null;

    Object.values(grid).forEach(cell => {
        if (cell.count > maxCount) {
            maxCount = cell.count;
            hotspotCell = cell;
        }
    });

    if (hotspotCell) {
        document.getElementById('mapHotspot').textContent = `${maxCount} issues`;
        
        // Optionally, you could add a circle to highlight the hotspot area
        // L.circle([hotspotCell.lat, hotspotCell.lng], {
        //     color: 'red',
        //     fillColor: '#f03',
        //     fillOpacity: 0.2,
        //     radius: 5000
        // }).addTo(mainMap);
    }
}

// Solutions Management Functions
async function loadSolutions() {
    try {
        solutionsLoadingSpinner.style.display = 'block';
        solutionsGrid.innerHTML = '';

        const solutionsSnapshot = await db.collection('solutions').get();
        allSolutions = solutionsSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        updateSolutionsStats();
        filterAndDisplaySolutions();

        // Add event listeners for filters
        solutionStatusFilter.addEventListener('change', filterAndDisplaySolutions);
        solutionTypeFilter.addEventListener('change', filterAndDisplaySolutions);
        solutionSearchInput.addEventListener('input', filterAndDisplaySolutions);

    } catch (error) {
        console.error('Error loading solutions:', error);
        showNotification('Failed to load solutions', 'error');
    } finally {
        solutionsLoadingSpinner.style.display = 'none';
    }
}

function updateSolutionsStats() {
    const pending = allSolutions.filter(s => s.status === 'pending').length;
    const verified = allSolutions.filter(s => s.status === 'SolutionStatus.verified').length;
    const rejected = allSolutions.filter(s => s.status === 'rejected').length;

    pendingSolutionsCount.textContent = pending;
    verifiedSolutionsCount.textContent = verified;
    rejectedSolutionsCount.textContent = rejected;
}

function filterAndDisplaySolutions() {
    const statusFilter = solutionStatusFilter.value;
    const typeFilter = solutionTypeFilter.value;
    const searchTerm = solutionSearchInput.value.toLowerCase();

    let filteredSolutions = allSolutions.filter(solution => {
        const matchesStatus = statusFilter === 'all' || solution.status === statusFilter;
        const matchesType = typeFilter === 'all' || solution.type === typeFilter;
        const matchesSearch = searchTerm === '' || 
            solution.title.toLowerCase().includes(searchTerm) ||
            solution.description.toLowerCase().includes(searchTerm);

        return matchesStatus && matchesType && matchesSearch;
    });

    // Sort by submission date (newest first)
    filteredSolutions.sort((a, b) => {
        const dateA = a.submittedAt?.toDate ? a.submittedAt.toDate() : (a.submittedAt ? new Date(a.submittedAt) : new Date(0));
        const dateB = b.submittedAt?.toDate ? b.submittedAt.toDate() : (b.submittedAt ? new Date(b.submittedAt) : new Date(0));
        return dateB - dateA;
    });

    displaySolutions(filteredSolutions);
}

function displaySolutions(solutions) {
    solutionsGrid.innerHTML = '';

    if (solutions.length === 0) {
        solutionsGrid.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; padding: 3rem; color: #6B7280;">
                <div style="font-size: 3rem; margin-bottom: 1rem;">🔧</div>
                <h3>No solutions found</h3>
                <p>No solutions match your current filters.</p>
            </div>
        `;
        return;
    }

    solutions.forEach(solution => {
        const solutionCard = createSolutionCard(solution);
        solutionsGrid.appendChild(solutionCard);
    });
}

function createSolutionCard(solution) {
    const card = document.createElement('div');
    card.className = 'solution-card';
    card.onclick = () => openSolutionModal(solution);

    const statusClass = solution.status || 'pending';
    const statusText = getSolutionStatusText(solution.status);
    const typeText = getSolutionTypeText(solution.type);

    // Handle the submittedAt date properly
    const submittedDate = solution.submittedAt?.toDate ? solution.submittedAt.toDate() : solution.submittedAt;
    
    // Get status emoji and color
    const statusEmoji = getStatusEmojiForSolution(solution.status);
    const priorityLevel = getPriorityLevel(solution);
    
    card.innerHTML = `
        <div class="card-header">
            <div class="card-title-section">
                <div class="solution-title">${solution.title}</div>
                <div class="solution-meta">
                    <span class="meta-item">
                        <span class="meta-icon">🔧</span>
                        ${typeText}
                    </span>
                    <span class="meta-item">
                        <span class="meta-icon">👤</span>
                        ${solution.userName || 'Anonymous'}
                    </span>
                    <span class="meta-item">
                        <span class="meta-icon">📅</span>
                        ${formatDate(submittedDate)}
                    </span>
                </div>
            </div>
            <div class="card-status-section">
                <div class="solution-status ${statusClass}">
                    <span class="status-emoji">${statusEmoji}</span>
                    ${statusText}
                </div>
                <div class="priority-badge priority-${priorityLevel}">
                    ${priorityLevel.toUpperCase()}
                </div>
            </div>
        </div>
        
        <div class="card-content">
            <div class="solution-description">
                ${solution.description.length > 150 ? 
                    solution.description.substring(0, 150) + '...' : 
                    solution.description
                }
            </div>
            
            <div class="solution-stats">
                <div class="stat-item">
                    <div class="stat-icon">⏱️</div>
                    <div class="stat-content">
                        <div class="stat-value">${solution.estimatedTime || 0}m</div>
                        <div class="stat-label">Time</div>
                    </div>
                </div>
                <div class="stat-item">
                    <div class="stat-icon">💰</div>
                    <div class="stat-content">
                        <div class="stat-value">₹${Math.round((solution.estimatedCost || 0) / 100)}</div>
                        <div class="stat-label">Cost</div>
                    </div>
                </div>
                <div class="stat-item">
                    <div class="stat-icon">📊</div>
                    <div class="stat-content">
                        <div class="stat-value">${getDifficultyText(solution.difficulty)}</div>
                        <div class="stat-label">Level</div>
                    </div>
                </div>
                ${solution.verificationPhotos && solution.verificationPhotos.length > 0 ? `
                    <div class="stat-item">
                        <div class="stat-icon">📸</div>
                        <div class="stat-content">
                            <div class="stat-value">${solution.verificationPhotos.length}</div>
                            <div class="stat-label">Photos</div>
                        </div>
                    </div>
                ` : ''}
            </div>

            ${solution.verificationPhotos && solution.verificationPhotos.length > 0 ? `
                <div class="solution-photos-preview">
                    <div class="photos-grid">
                        ${solution.verificationPhotos.slice(0, 3).map(photo => `
                            <img src="${photo}" alt="Verification" class="photo-thumbnail" onclick="event.stopPropagation(); openPhotoModal('${photo}')">
                        `).join('')}
                        ${solution.verificationPhotos.length > 3 ? `
                            <div class="photo-thumbnail more-photos" onclick="event.stopPropagation(); openSolutionModal('${solution.id}')">
                                <span class="more-count">+${solution.verificationPhotos.length - 3}</span>
                            </div>
                        ` : ''}
                    </div>
                </div>
            ` : ''}
        </div>

        <div class="card-actions">
            <div class="action-row">
                <div class="status-controls">
                    <select class="status-select" onchange="event.stopPropagation(); changeSolutionStatus('${solution.id}', this.value)">
                        <option value="pending" ${solution.status === 'pending' ? 'selected' : ''}>Pending</option>
                        <option value="under_review" ${solution.status === 'under_review' ? 'selected' : ''}>Under Review</option>
                        <option value="SolutionStatus.verified" ${solution.status === 'SolutionStatus.verified' ? 'selected' : ''}>Verified</option>
                        <option value="rejected" ${solution.status === 'rejected' ? 'selected' : ''}>Rejected</option>
                        <option value="needs_revision" ${solution.status === 'needs_revision' ? 'selected' : ''}>Needs Revision</option>
                    </select>
                    <button class="btn-update" onclick="event.stopPropagation(); updateSolutionStatus('${solution.id}')">
                        <span class="btn-icon">🔄</span>
                        Update
                    </button>
                </div>
                
                ${solution.status === 'pending' ? `
                    <div class="quick-actions">
                        <button class="btn-quick btn-approve" onclick="event.stopPropagation(); verifySolution('${solution.id}', true)">
                            <span class="btn-icon">✅</span>
                            Approve
                        </button>
                        <button class="btn-quick btn-reject" onclick="event.stopPropagation(); verifySolution('${solution.id}', false)">
                            <span class="btn-icon">❌</span>
                            Reject
                        </button>
                    </div>
                ` : ''}
            </div>
            
            <div class="action-row">
                <button class="btn-primary" onclick="event.stopPropagation(); openSolutionModal('${solution.id}')">
                    <span class="btn-icon">👁️</span>
                    View Details
                </button>
            </div>
        </div>
    `;

    return card;
}

function openSolutionModal(solutionId) {
    let solution;
    if (typeof solutionId === 'string') {
        solution = allSolutions.find(s => s.id === solutionId);
    } else {
        solution = solutionId;
    }

    if (!solution) return;

    // Handle the submittedAt date properly
    const submittedDate = solution.submittedAt?.toDate ? solution.submittedAt.toDate() : solution.submittedAt;
    
    solutionModalBody.innerHTML = `
        <div class="solution-modal-content">
            <div class="solution-info">
                <h3>${solution.title}</h3>
                <p><strong>Submitted by:</strong> ${solution.userName || 'Anonymous'}</p>
                <p><strong>Date:</strong> ${formatDate(submittedDate)}</p>
                <p><strong>Status:</strong> <span class="solution-status ${solution.status || 'pending'}">${getSolutionStatusText(solution.status)}</span></p>
                
                <h4>Description</h4>
                <p>${solution.description}</p>
                
                <h4>Solution Details</h4>
                <div class="solution-details">
                    <div class="detail-chip">
                        <span class="icon">🔧</span>
                        <span>${getSolutionTypeText(solution.type)}</span>
                    </div>
                    <div class="detail-chip">
                        <span class="icon">⏱️</span>
                        <span>${solution.estimatedTime || 0} minutes</span>
                    </div>
                    <div class="detail-chip">
                        <span class="icon">💰</span>
                        <span>₹${Math.round((solution.estimatedCost || 0) / 100)}</span>
                    </div>
                    <div class="detail-chip">
                        <span class="icon">📊</span>
                        <span>${getDifficultyText(solution.difficulty)}</span>
                    </div>
                </div>

                ${solution.materials && solution.materials.length > 0 ? `
                    <h4>Materials Used</h4>
                    <ul>
                        ${solution.materials.map(material => `<li>${material}</li>`).join('')}
                    </ul>
                ` : ''}
            </div>

            <div class="solution-photos-modal">
                ${solution.verificationPhotos && solution.verificationPhotos.length > 0 ? `
                    <h4>Verification Photos</h4>
                    <div class="photos-modal-grid">
                        ${solution.verificationPhotos.map(photo => `
                            <img src="${photo}" alt="Verification" class="photo-modal" onclick="openPhotoModal('${photo}')">
                        `).join('')}
                    </div>
                ` : '<p>No verification photos provided.</p>'}
            </div>
        </div>

        <div class="verification-actions">
            <h4>Status Management</h4>
            <div class="status-change-section">
                <label for="statusSelect">Change Status:</label>
                <select id="statusSelect" onchange="changeSolutionStatus('${solution.id}', this.value)">
                    <option value="pending" ${solution.status === 'pending' ? 'selected' : ''}>Pending Review</option>
                    <option value="SolutionStatus.verified" ${solution.status === 'SolutionStatus.verified' ? 'selected' : ''}>Verified</option>
                    <option value="rejected" ${solution.status === 'rejected' ? 'selected' : ''}>Rejected</option>
                    <option value="under_review" ${solution.status === 'under_review' ? 'selected' : ''}>Under Review</option>
                    <option value="needs_revision" ${solution.status === 'needs_revision' ? 'selected' : ''}>Needs Revision</option>
                </select>
                <button class="btn-status-update" onclick="updateSolutionStatus('${solution.id}')">
                    Update Status
                </button>
            </div>
            
            ${solution.status === 'pending' ? `
                <div class="quick-actions">
                    <button class="btn-verify approve" onclick="verifySolution('${solution.id}', true)">
                        ✅ Quick Approve
                    </button>
                    <button class="btn-verify reject" onclick="verifySolution('${solution.id}', false)">
                        ❌ Quick Reject
                    </button>
                </div>
            ` : ''}
        </div>
    `;

    solutionModal.style.display = 'flex';
}

async function verifySolution(solutionId, approved) {
    try {
        const solution = allSolutions.find(s => s.id === solutionId);
        if (!solution) return;

        const newStatus = approved ? 'SolutionStatus.verified' : 'SolutionStatus.rejected';
        const timestamp = firebase.firestore.FieldValue.serverTimestamp();

        // Update solution status
        const updateData = {
            status: newStatus,
            verifiedAt: timestamp,
            verifiedBy: currentUser.email,
            lastUpdated: timestamp
        };
        
        // If approved, also set isVerified to true
        if (approved) {
            updateData.isVerified = true;
        }
        
        await db.collection('solutions').doc(solutionId).update(updateData);

        // If approved, update the related issue status to "Resolved"
        if (approved) {
            await db.collection('issues').doc(solution.issueId).update({
                status: 'Resolved',
                resolvedBy: solution.userId,
                resolvedAt: timestamp,
                updatedAt: timestamp
            });

            // Award points to the user
            await awardPointsToUser(solution.userId, 50);
        }

        // Update local data
        solution.status = newStatus;
        solution.verifiedAt = timestamp;
        solution.verifiedBy = currentUser.email;

        // Refresh display
        updateSolutionsStats();
        filterAndDisplaySolutions();
        closeSolutionModal();

        showNotification(
            `Solution ${approved ? 'approved' : 'rejected'} successfully!`,
            approved ? 'success' : 'info'
        );

    } catch (error) {
        console.error('Error verifying solution:', error);
        showNotification('Failed to verify solution', 'error');
    }
}

// Change solution status function
function changeSolutionStatus(solutionId, newStatus) {
    // This function is called when the dropdown changes
    // We'll store the new status temporarily and update it when the user clicks "Update Status"
    const solution = allSolutions.find(s => s.id === solutionId);
    if (solution) {
        solution._tempStatus = newStatus;
    }
}

// Update solution status function
async function updateSolutionStatus(solutionId) {
    try {
        const solution = allSolutions.find(s => s.id === solutionId);
        if (!solution) return;

        const newStatus = solution._tempStatus || solution.status;
        const timestamp = firebase.firestore.FieldValue.serverTimestamp();

        // Update solution status in Firestore
        const updateData = {
            status: newStatus,
            lastUpdated: timestamp,
            updatedBy: currentUser.email
        };
        
        // If status is verified, also set isVerified to true
        if (newStatus === 'SolutionStatus.verified') {
            updateData.isVerified = true;
        }
        
        await db.collection('solutions').doc(solutionId).update(updateData);

        // If status is verified, update the related issue status to "Resolved"
        if (newStatus === 'SolutionStatus.verified') {
            await db.collection('issues').doc(solution.issueId).update({
                status: 'Resolved',
                resolvedBy: solution.userId,
                resolvedAt: timestamp,
                updatedAt: timestamp
            });

            // Award points to the user
            await awardPointsToUser(solution.userId, 50);
        }

        // Update local data
        solution.status = newStatus;
        solution.lastUpdated = timestamp;
        solution.updatedBy = currentUser.email;
        delete solution._tempStatus;

        // Refresh display
        updateSolutionsStats();
        filterAndDisplaySolutions();
        
        // Update the modal if it's open
        if (solutionModal.style.display === 'flex') {
            openSolutionModal(solutionId);
        }

        showNotification(
            `Solution status updated to "${getSolutionStatusText(newStatus)}" successfully!`,
            'success'
        );

    } catch (error) {
        console.error('Error updating solution status:', error);
        showNotification('Failed to update solution status', 'error');
    }
}

async function awardPointsToUser(userId, points) {
    try {
        // Update user points
        await db.collection('users').doc(userId).update({
            points: firebase.firestore.FieldValue.increment(points),
            lastUpdated: firebase.firestore.FieldValue.serverTimestamp()
        });

        // Update user stats
        await db.collection('userStats').doc(userId).update({
            points: firebase.firestore.FieldValue.increment(points),
            lastUpdated: firebase.firestore.FieldValue.serverTimestamp()
        });

        console.log(`Awarded ${points} points to user ${userId}`);
    } catch (error) {
        console.error('Error awarding points:', error);
    }
}

function getSolutionStatusText(status) {
    switch (status) {
        case 'pending': return 'Pending Review';
        case 'SolutionStatus.verified': return 'Verified';
        case 'SolutionStatus.rejected': return 'Rejected';
        case 'under_review': return 'Under Review';
        case 'needs_revision': return 'Needs Revision';
        default: return 'Pending Review';
    }
}

function getSolutionTypeText(type) {
    switch (type) {
        case 'diyFix': return 'DIY Fix';
        case 'workaround': return 'Workaround';
        case 'documentation': return 'Documentation';
        case 'communityHelp': return 'Community Help';
        default: return 'Solution';
    }
}

// Get status emoji for solution cards
function getStatusEmojiForSolution(status) {
    switch (status) {
        case 'pending': return '⏳';
        case 'under_review': return '🔍';
        case 'SolutionStatus.verified': return '✅';
        case 'SolutionStatus.rejected': return '❌';
        case 'needs_revision': return '🔄';
        default: return '⏳';
    }
}

// Get priority level based on solution characteristics
function getPriorityLevel(solution) {
    const hasPhotos = solution.verificationPhotos && solution.verificationPhotos.length > 0;
    const isDetailed = solution.description && solution.description.length > 100;
    const hasMaterials = solution.materials && solution.materials.length > 0;
    const isLowCost = (solution.estimatedCost || 0) < 500; // Less than ₹5
    
    let score = 0;
    if (hasPhotos) score += 2;
    if (isDetailed) score += 1;
    if (hasMaterials) score += 1;
    if (isLowCost) score += 1;
    
    if (score >= 4) return 'high';
    if (score >= 2) return 'medium';
    return 'low';
}

// Clean up difficulty text display
function getDifficultyText(difficulty) {
    if (!difficulty) return 'Easy';
    
    // Remove "DifficultyLevel." prefix if present
    const cleanDifficulty = difficulty.replace(/^DifficultyLevel\./i, '');
    
    // Capitalize first letter
    return cleanDifficulty.charAt(0).toUpperCase() + cleanDifficulty.slice(1).toLowerCase();
}

function closeSolutionModal() {
    solutionModal.style.display = 'none';
}

// Photo modal function
function openPhotoModal(photoUrl) {
    // Create photo modal
    const photoModal = document.createElement('div');
    photoModal.id = 'photoModal';
    photoModal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.9);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10001;
        cursor: pointer;
    `;
    
    const img = document.createElement('img');
    img.src = photoUrl;
    img.style.cssText = `
        max-width: 90%;
        max-height: 90%;
        object-fit: contain;
        border-radius: 8px;
    `;
    
    photoModal.appendChild(img);
    document.body.appendChild(photoModal);
    
    // Close on click
    photoModal.addEventListener('click', () => {
        document.body.removeChild(photoModal);
    });
}

// Make functions available globally
window.setMapView = setMapView;
window.updateMapFilters = updateMapFilters;
window.openIssueFromMap = openIssueFromMap;
window.verifySolution = verifySolution;
window.openSolutionModal = openSolutionModal;
window.closeSolutionModal = closeSolutionModal;
window.openPhotoModal = openPhotoModal;
window.changeSolutionStatus = changeSolutionStatus;
window.updateSolutionStatus = updateSolutionStatus;

