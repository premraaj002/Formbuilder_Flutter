# Support Tickets Troubleshooting Guide

## Issue: Tickets are submitted but not showing in "My Tickets"

### 🔍 **Step 1: Check Console Logs**
1. Open your web app in browser
2. Open Developer Tools (F12)
3. Go to Console tab
4. Submit a support ticket and look for these messages:
   - `Submitting ticket for user: [user-id]`
   - `Ticket created with ID: [document-id]`
   - `Loading tickets for user: [user-id]`
   - `Found X tickets`

### 🔍 **Step 2: Verify Ticket Creation**
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Look for `support_tickets` collection
4. Check if documents exist with your `userId`

### 🔍 **Step 3: Test Debug Features**
1. Go to "My Tickets" screen
2. Click the info icon (ℹ️) in the top right
3. Check the debug info displayed

### 🔍 **Step 4: Check Firestore Rules**
Make sure your Firestore rules include:
```javascript
match /support_tickets/{ticketId} {
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.userId;
  allow read: if request.auth != null && 
    request.auth.uid == resource.data.userId;
}
```

### 🔍 **Step 5: Potential Issues & Solutions**

#### Issue 1: Composite Index Missing
**Symptoms:** Error about missing index when using orderBy
**Solution:** 
- The app now falls back to no-orderBy query
- Check console for "OrderBy failed, trying without orderBy"

#### Issue 2: Permission Denied
**Symptoms:** "permission-denied" error
**Solution:** 
- Update Firestore rules as shown above
- Make sure rules are published

#### Issue 3: User Authentication
**Symptoms:** "User is null" error  
**Solution:**
- Make sure user is logged in
- Check Firebase Auth status

#### Issue 4: Data Structure Mismatch
**Symptoms:** Tickets created but not loaded
**Solution:**
- Check if `userId` field matches exactly
- Verify timestamp fields are created properly

### 🔧 **Quick Test Steps:**

1. **Submit a test ticket:**
   - Go to Settings → Support → Submit Support Ticket
   - Fill out the form and submit
   - Note the success message and document ID

2. **Check Firebase Console:**
   - Go to Firestore Database
   - Look for `support_tickets` collection
   - Find your document by ID
   - Verify `userId` matches your account

3. **Check "My Tickets":**
   - Go to "My Tickets" screen
   - Click refresh button
   - Click info button for debug info
   - Check console logs for any errors

4. **Manual Query Test:**
   - In Firebase Console, try this query:
   - Collection: `support_tickets`
   - Where: `userId == [your-user-id]`
   - See if documents appear

### 📞 **If Still Not Working:**

Share these details:
1. Console log messages
2. Screenshot of Firebase Console showing tickets collection
3. Debug info from the info button
4. Any error messages displayed

The updated code includes better error handling and debugging to help identify the exact issue!
