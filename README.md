# Real-Time Auction Platform (Node.js, Express, MongoDB + Flutter)

A complete end-to-end auction platform featuring a RESTful backend with real-time WebSockets and an interactive Flutter mobile/web application.

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **Node.js**: v18+ (tested on Node v20)
- **Flutter**: v3.24+ (tested on Flutter 3.47.6 / Dart 3.13.5)
- **MongoDB**: Connected to your live MongoDB Atlas cluster (`cluster0.aoapegr.mongodb.net`) with an automatic embedded in-memory fallback for offline development.

---

### 2. Backend Setup
```bash
cd backend
npm install

# Seed the database with Admin, 5 Users, and realistic sample auctions
npm run seed

# Run the server on port 5000
npm start
```

*Note: The server automatically initializes and auto-seeds the demo database on initial boot if empty.*

#### Verify Backend:
- Health check: `curl http://localhost:5000/health`
- List auctions: `curl http://localhost:5000/api/auctions`

---

### 3. Flutter App Setup
```bash
# Return to the root directory
cd ..

# Fetch Flutter dependencies
flutter pub get

# Run on Chrome/Web
flutter run -d chrome

# Or run on Android emulator
flutter run -d android
```

*Note for Android: The app automatically detects Android and directs network requests to `http://10.0.2.2:5000`. You can also tap the settings gear on the login screen to customize the backend URL at any time.*

---

## 🔑 Demo Login Credentials

The database comes pre-seeded with 1 Admin and 5 Users. For convenience, the Login screen includes **1-Tap Demo Account Buttons** so you can quickly switch between accounts without manual typing.

| Role | Name | Email | Password | Permissions / Capabilities |
| :--- | :--- | :--- | :--- | :--- |
| **Admin** | Auction Admin | `admin@auction.com` | `admin123` | Create auctions, upload photos, view all statuses & winners |
| **User 1** | Alice Walker | `alice@auction.com` | `user123` | Browse, place bids, live updates, track winning/lost status |
| **User 2** | Bob Martinez | `bob@auction.com` | `user123` | Browse, place bids, live updates, track winning/lost status |
| **User 3** | Charlie Chen | `charlie@auction.com` | `user123` | Browse, place bids, live updates, track winning/lost status |
| **User 4** | Diana Prince | `diana@auction.com` | `user123` | Browse, place bids, live updates, track winning/lost status |
| **User 5** | Ethan Hunt | `ethan@auction.com` | `user123` | Browse, place bids, live updates, track winning/lost status |

---

## 🏛️ Architecture & Key Engineering Decisions

### 1. Concurrency & Race Condition Safety
- **Requirement**: *"Bids placed on the same auction at the same time must still produce a correct result."*
- **Solution**: MongoDB atomic conditional updates (`Auction.findOneAndUpdate`) with query guards:
  ```javascript
  const filter = {
    _id: auctionId,
    status: 'live',
    startTime: { $lte: now },
    endTime: { $gt: now },
    currentHighestBid: { $lte: amount - minIncrement } // Or { bids: { $size: 0 }, startingPrice: { $lte: amount } }
  };
  ```
- If 10 users bid on the same item at the exact same millisecond:
  - Exactly **1** atomic write succeeds and locks the new price.
  - The other **9** requests match 0 documents, return 409 Conflict, and immediately inform the user of the new minimum required bid.
- Verified with automated stress testing: `cd backend && npm run test:concurrency`.

### 2. Scheduled Lifecycle & Expiration Worker
- **Requirement**: *"Each auction closes and records its result at its end time. This happens even if nobody is using the app at that moment, and even if the server restarts."*
- **Solution**:
  - In-process background worker (`backend/src/services/auctionWorker.js`) scans every 4 seconds.
  - Automatically transitions `upcoming` auctions to `live` when `startTime` arrives.
  - Automatically transitions `live` auctions to `ended`, selects the highest bidder as the winner (or sets `winner = null` if no bids), and emits real-time WebSocket events.
  - Executes **immediately on server startup** to recover and finalize any auctions that reached their end time while the server was offline.

### 3. Real-Time WebSocket Synchronization
- **Requirement**: *"See bids from other users without refreshing manually."*
- **Solution**:
  - Node.js `socket.io` server broadcasts events:
    - `new_bid`: Emitted to auction room `auction:<id>` and general `auctions` room.
    - `auction_ended`: Emitted upon expiry with winner details.
    - `auction_updated`: Updates card list prices instantly.
  - Flutter `socket_io_client` listens to stream events and updates state via `ChangeNotifierProvider` without full page reloads.

### 4. Image Upload & Persistence
- **Requirement**: *"Uploaded images stay available after the server restarts or redeploys."*
- **Solution**:
  - `Multer` saves uploaded images to the persistent `backend/uploads/` directory on disk with unique timestamped filenames.
  - Express serves this static folder at `/uploads`.
  - The app also provides preset sample images for instant testing on platforms without camera/gallery support.

### 5. UI/UX States & Feedback
- Material 3 theme with intuitive visual hierarchy.
- **Loading States**: Spinners during network requests, image loading placeholders.
- **Empty States**: Customized illustrations and helper text for each tab ("Live", "Upcoming", "Ended", "My Bids").
- **Error Feedback**: Rejection snackbars and inline alerts detailing why bids fail (e.g. outbid conflict, auction not started, below minimum increment, or holding top bid).
- **Live Countdown Timers**: Second-by-second ticking timers on cards and detail screens.

---

## 🧪 Testing

### Backend Concurrency Stress Test
Simulates 10 concurrent requests at the exact same amount on a live auction:
```bash
cd backend
npm run test:concurrency
```
**Expected Output**:
```
Results:
  Successful Bids (200 OK): 1
  Rejected Bids (Conflict/Error): 9
  Sample Rejection Reason [1]: "Conflict! Another bidder placed a bid of $1050 just ahead of you. Minimum required bid is now $1100."
 SUCCESS: Race condition prevented! Exactly 1 bid accepted; conflicting simultaneous bids safely rejected.
```

### Flutter Static Analysis & Unit Tests
```bash
# Verify static analysis (0 errors, 0 warnings)
flutter analyze

# Run unit and widget tests
flutter test
```
Outputs:
```
All tests passed!
```

---

## 📂 Project Structure

```
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── db.js             # Mongoose connection & in-memory fallback
│   │   │   └── seedHelper.js     # Shared data seeder
│   │   ├── controllers/
│   │   │   ├── authController.js    # Login & profile retrieval
│   │   │   └── auctionController.js # Concurrency-safe bidding & CRUD
│   │   ├── middleware/
│   │   │   ├── auth.js           # JWT verification & role authorization
│   │   │   ├── upload.js         # Multer image storage configuration
│   │   │   └── errorHandler.js   # Centralized error formatting
│   │   ├── models/
│   │   │   ├── User.js           # User schema with bcrypt password hashing
│   │   │   └── Auction.js        # Auction schema with bid history & indexes
│   │   ├── routes/
│   │   │   ├── authRoutes.js     # /api/auth endpoints
│   │   │   └── auctionRoutes.js  # /api/auctions endpoints
│   │   ├── services/
│   │   │   ├── auctionWorker.js  # Scheduled auction closure worker
│   │   │   └── socketService.js  # Socket.io broadcast manager
│   │   └── app.js                # Express app setup
│   ├── uploads/                  # Persisted uploaded auction images
│   ├── server.js                 # HTTP + WebSocket server entrypoint
│   ├── seed.js                   # Seeder script
│   ├── test_concurrency.js       # Race condition stress test
│   └── package.json
│
└── lib/                          # Flutter Application
    ├── models/
    │   ├── user.dart             # AppUser model
    │   ├── auction.dart          # Auction model with price calculations
    │   └── bid.dart              # Bid model
    ├── providers/
    │   ├── auth_provider.dart    # Auth state & token storage
    │   └── auction_provider.dart # Auction state & socket synchronization
    ├── services/
    │   ├── api_service.dart      # REST HTTP client
    │   └── socket_service.dart   # Socket.io client wrapper
    ├── screens/
    │   ├── login_screen.dart           # Login with 1-tap demo credentials
    │   ├── auction_list_screen.dart    # Tabbed browser (Live, Upcoming, Ended, My Bids)
    │   ├── auction_detail_screen.dart  # Real-time detail view with live bid history
    │   └── create_auction_screen.dart  # Admin auction creator with image picker
    ├── widgets/
    │   ├── auction_card.dart           # Card with status chips & countdown
    │   ├── countdown_timer.dart        # Ticking timer widget
    │   ├── bid_history_tile.dart       # Individual bid entry with highest badge
    │   └── quick_bid_sheet.dart        # Bottom sheet for placing bids
    ├── theme/
    │   └── app_theme.dart              # Clean Material 3 palette & components
    ├── utils/
    │   └── constants.dart              # Auto-detected host & demo credentials
    └── main.dart                       # App entrypoint & MultiProvider setup
```
# House_of_vsb
