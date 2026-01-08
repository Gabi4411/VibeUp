# Firebase Setup Guide - Table Booking & Ordering Feature

This document contains all Firebase configurations needed for the nightclub table booking and ordering system.

## 1. Firestore Security Rules

Add these rules to your Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write, create, update, delete: if true;
    }
  }
}
```

## 2. Firestore Composite Indexes

Create these composite indexes in the Firebase Console (Firestore Database > Indexes):

### Index 1: Table Orders by Event and Status
- **Collection ID:** `table_orders`
- **Fields indexed:**
  - `eventId` (Ascending)
  - `status` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection

### Index 2: Table Orders by Table
- **Collection ID:** `table_orders`
- **Fields indexed:**
  - `tableId` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection

### Index 3: Table Orders by User
- **Collection ID:** `table_orders`
- **Fields indexed:**
  - `userId` (Ascending)
  - `eventId` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection

### Index 4: Menu Items by Event and Category
- **Collection ID:** `menu_items`
- **Fields indexed:**
  - `eventId` (Ascending)
  - `category` (Ascending)
  - `name` (Ascending)
- **Query scope:** Collection

### Index 5: Tables by Event and Location
- **Collection ID:** `tables`
- **Fields indexed:**
  - `eventId` (Ascending)
  - `location` (Ascending)
  - `tableNumber` (Ascending)
- **Query scope:** Collection

### Index 6: Table Bookings by Event
- **Collection ID:** `table_bookings`
- **Fields indexed:**
  - `eventId` (Ascending)
  - `bookingDate` (Descending)
- **Query scope:** Collection

### Index 7: Event Photos by Event
- **Collection ID:** `event_photos`
- **Fields indexed:**
  - `eventId` (Ascending)
  - `uploadedAt` (Descending)
- **Query scope:** Collection

**Note:** Firebase will automatically prompt you to create these indexes when you first run queries that require them. You can click the provided link in the error message to create them automatically.

## 3. Firebase Storage Rules

Update your Storage rules to allow photo uploads:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Event photos - authenticated users can upload, anyone can read
    match /event_photos/{eventId}/{photoId} {
      allow read: if true;
      allow write: if request.auth != null &&
                     request.resource.size < 5 * 1024 * 1024 && // Max 5MB
                     request.resource.contentType.matches('image/.*');
    }
    
    // Existing rules for other storage paths...
  }
}
```

## 4. CORS Configuration for Storage

If you're using Firebase Storage for photos, you need to configure CORS to allow web access.

**File:** `cors.json` (already created in your project root)

**Deploy using Google Cloud SDK:**

```bash
# Install Google Cloud SDK first: https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Set your project
gcloud config set project vibeup-de0fc

# Deploy CORS configuration
gsutil cors set cors.json gs://vibeup-de0fc.firebasestorage.app
```

**Verify CORS is applied:**
```bash
gsutil cors get gs://vibeup-de0fc.firebasestorage.app
```

## 5. Firestore Collections Structure

Here's the expected structure for the new collections:

### `tables` Collection
```javascript
{
  "tableNumber": "VIP-1",
  "capacity": 8,
  "eventId": "event123",
  "location": "Main Floor",
  "bookingPrice": 500.00,
  "isBooked": true,
  "bookedByUserId": "user123",
  "totalSpent": 1250.50,
  "totalDue": 450.00
}
```

### `table_bookings` Collection
```javascript
{
  "tableId": "table123",
  "eventId": "event123",
  "userId": "user123",
  "bookingDate": Timestamp,
  "bookingPrice": 500.00,
  "status": "active"
}
```

### `menu_items` Collection
```javascript
{
  "eventId": "event123",
  "name": "Dom Pérignon",
  "category": "Champagne",
  "price": 450.00,
  "description": "Vintage champagne",
  "imageUrl": "https://...",
  "inStock": true,
  "stockQuantity": 12
}
```

### `table_orders` Collection
```javascript
{
  "eventId": "event123",
  "tableId": "table123",
  "userId": "user123",
  "items": [
    {
      "menuItemId": "item123",
      "menuItemName": "Dom Pérignon",
      "quantity": 2,
      "pricePerItem": 450.00,
      "totalPrice": 900.00
    }
  ],
  "totalAmount": 900.00,
  "status": "pending", // pending, confirmed, preparing, delivered, paid
  "createdAt": Timestamp,
  "isPaid": false
}
```

### `event_photos` Collection
```javascript
{
  "eventId": "event123",
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "uploaderId": "user123",
  "uploaderName": "John Doe",
  "uploadedAt": Timestamp,
  "caption": "Great night!"
}
```

## 6. Deployment Checklist

- [ ] Copy Firestore security rules to Firebase Console
- [ ] Create all 7 composite indexes (or wait for auto-prompts)
- [ ] Update Storage rules in Firebase Console
- [ ] Deploy CORS configuration using gsutil
- [ ] Test table booking flow in development
- [ ] Test menu ordering flow
- [ ] Verify photos upload correctly
- [ ] Test organizer screens (table management, menu management, order dashboard)

## 7. Testing Recommendations

1. **Table Booking Flow:**
   - Purchase a ticket for a club event
   - Accept the table booking dialog
   - Select and book a VIP table
   - Verify balance is deducted

2. **Menu Ordering Flow:**
   - From a booked table, browse the menu
   - Add items to cart
   - Place an order
   - Verify order appears in active orders

3. **Organizer Flow:**
   - Create a club event with table booking enabled
   - Set up VIP tables in Table Management
   - Add menu items in Menu Management
   - Monitor orders in Order Dashboard
   - Update order status (pending → confirmed → preparing → delivered → paid)

4. **Photo Gallery:**
   - Upload photos to an event
   - Verify photos display in gallery
   - Test filtering by uploader
   - Verify CORS allows image loading

## 8. Common Issues & Solutions

### Issue: "Missing or insufficient permissions"
**Solution:** Verify your Firestore security rules are deployed and the user is authenticated.

### Issue: "Requires composite index"
**Solution:** Click the link in the error message or manually create the index in Firebase Console.

### Issue: "CORS error when loading images"
**Solution:** Deploy the CORS configuration using gsutil (see section 4).

### Issue: "Image upload fails"
**Solution:** Check Storage rules allow authenticated writes and file size is under 5MB.

### Issue: "Balance not deducting"
**Solution:** Verify the user document has a `balance` field and it's a number type.

## 9. Production Considerations

Before going to production:

1. **Security Rules:** Review and tighten security rules as needed
2. **Indexes:** Ensure all indexes are created and optimized
3. **Storage Limits:** Monitor storage usage for photos
4. **Cost Optimization:** Review Firestore read/write patterns
5. **Error Handling:** Add proper error handling and user feedback
6. **Testing:** Thoroughly test all flows with real users
7. **Backup:** Set up automated Firestore backups
8. **Monitoring:** Enable Firebase Performance Monitoring and Analytics

---

**Last Updated:** December 2024  
**Feature:** Nightclub VIP Table Booking & Ordering System
