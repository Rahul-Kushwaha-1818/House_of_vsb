# 🏛️ Full System Architecture & Technical Documentation
## Real-Time Auction Platform (Node.js, Express, MongoDB + Flutter)

---

## 1. Executive Summary & Architecture Overview

The system is a production-ready, full-stack real-time auction platform consisting of:
1. **Backend**: Node.js & Express REST API with Socket.io WebSockets, MongoDB (Mongoose ODM), Multer for image handling, and an automated background lifecycle worker. Hosted on **Render** (`https://house-of-vsb.onrender.com`).
2. **Mobile App**: Cross-platform Flutter application (Android APK built and tested, Web/iOS compatible) utilizing Provider for reactive state management, socket_io_client for live bidirectional synchronization, and custom UI components.
3. **Database**: MongoDB Atlas cloud cluster with fallback support for offline/in-memory development.

```
                      ┌───────────────────────────────────────────────┐
                      │              Flutter Mobile App               │
                      │  (Provider State, Socket.io Client, UI Views) │
                      └──────────────┬───────────────────▲────────────┘
                                     │                   │
                     HTTP REST / JSON│                   │WebSocket Events
                     (JWT Bearer)    │                   │(new_bid, auction_ended)
                                     ▼                   │
                      ┌──────────────────────────────────┴────────────┐
                      │           Node.js & Express Server            │
                      │ ───────────────────────────────────────────── │
                      │ • Auth & Role Middleware (Admin vs User)      │
                      │ • Atomic Concurrency Engine (findOneAndUpdate)│
                      │ • Multer Storage & Static File Serving (/uploads)
                      │ • Dual Keep-Alive Worker (Self-Ping < 5 min)  │
                      │ • 4-Sec Background Lifecycle Worker           │
                      └──────────────┬───────────────────▲────────────┘
                                     │                   │
                                Mongoose ODM (Atomic Transactions & Locks)
                                     ▼                   │
                      ┌──────────────────────────────────┴────────────┐
                      │            MongoDB Atlas Database             │
                      │  (Collections: Users, Auctions, Bids, Notifs) │
                      └───────────────────────────────────────────────┘
```

---

## 2. Complete Tech Stack & Libraries Used

### Backend Dependencies (`backend/package.json`)
| Library | Version | Purpose & Rationale |
| :--- | :--- | :--- |
| **`express`** | `^4.21.2` | Core HTTP framework for routing, middleware pipelines, and API endpoints. |
| **`socket.io`** | `^4.8.1` | Real-time WebSocket server with fallback to HTTP long-polling for firewall/proxy resilience. |
| **`mongoose`** | `^8.9.5` | Object Data Modeling (ODM) for MongoDB; enforces schemas, validation, and atomic queries. |
| **`jsonwebtoken`** | `^9.0.2` | Issues and verifies stateless JWT tokens for user and admin authentication. |
| **`bcryptjs`** | `^2.4.3` | Cryptographic password hashing with salt rounds to securely store user credentials. |
| **`multer`** | `^1.4.5-lts.1` | Multipart form-data parser for auction image uploads to local disk storage. |
| **`cors`** | `^2.8.5` | Cross-Origin Resource Sharing middleware enabling safe cross-domain mobile/web communication. |
| **`dotenv`** | `^16.4.7` | Loads environment configurations (MongoDB URI, JWT secret, ports). |
| **`mongodb-memory-server`** | `^11.3.0` | In-memory zero-configuration MongoDB engine used for fast automated unit tests and offline fallbacks. |

### Flutter Dependencies (`pubspec.yaml`)
| Library | Version | Purpose & Rationale |
| :--- | :--- | :--- |
| **`provider`** | `^6.1.2` | Recommended state management; provides reactive dependency injection (`ChangeNotifierProvider`). |
| **`socket_io_client`** | `^3.0.2` | Connects Flutter to the Node.js Socket.io server to receive instant real-time events. |
| **`http`** | `^1.6.0` | Performs REST API requests (login, signup, fetching auctions, multipart image upload). |
| **`intl`** | `^0.19.0` | Formats currency values, dates, and localized countdown timestamps. |
| **`shared_preferences`**| `^2.3.2` | Persists user auth token and role locally on the Android device across app launches. |
| **`image_picker`** | `^1.1.2` | Native camera and gallery selector for uploading auction images on mobile devices. |
| **`cupertino_icons`** | `^1.0.8` | Cross-platform high quality vector iconography. |

---

## 3. Core Roles & Functional Requirements

### A. Admin Functionality
1. **Create an Auction**:
   - **Fields**: Title, Description, Starting Price, Minimum Bid Increment, Start Time, End Time, and Image.
   - **Image Upload**: Supports native device camera/gallery file selection via `image_picker` (sent as multipart/form-data) OR URL fallback.
   - **Validation**:
     - Starting price must be $\ge 0$.
     - Minimum increment must be $\ge 1$.
     - End time must be strictly after start time and in the future.
     - Automatically transitions to `live` if scheduled for the current time (with a 60-second grace window to absorb clock drift).
2. **View All Auctions**:
   - Filter by **Live**, **Upcoming**, and **Ended**.
   - Admin view displays the current highest bid, bidder details, and final winner badge once ended.
   - **Strict Rule Enforcement**: Admins are prohibited from bidding (`403 Forbidden`). The "My Bids" tab and bidding buttons are hidden for admin accounts.

### B. User Functionality
1. **Browse Auctions**:
   - Tabs: **Live** (currently active), **Upcoming** (scheduled), **Ended** (concluded), and **My Bids** (auctions where the user placed bids).
   - Real-time search by keyword and category.
2. **Auction Details**:
   - High-resolution hero image with graceful network caching and fallback placeholders.
   - Live real-time countdown timer ticking second-by-second (`02h 45m 12s`).
   - Dynamic badges displaying status (`LIVE`, `UPCOMING`, `ENDED`) and user outcome (`WINNING`, `OUTBID`, `WON`, `LOST`).
   - Bid history table sorted in **decreasing order** (highest/latest bid at the top).
3. **Placing Bids**:
   - Dedicated quick-increment bidding chips (`+$50`, `+$100`, `+$250`) and custom amount input.
   - Minimum required bid is automatically computed and displayed (`Current + Increment`).
   - Real-time feedback with instant rejection messages (e.g., if outbid, if bid too low, or if user already holds top bid).
4. **Real-Time Push Notifications & Alerts**:
   - Socket notifications triggered when outbid by another bidder: `⚠️ Outbid Alert!`.
   - Victory announcement when an auction ends: `🏆 Congratulations! You Won!`.

---

## 4. Auction Business Rules & Verification

| Business Rule | Server Implementation | Client UI Feedback |
| :--- | :--- | :--- |
| **Time Window** | Server checks `startTime <= now < endTime`. If `now < startTime` returns `400` ("Auction not started"). If `now >= endTime` returns `400` ("Auction ended"). | Countdown timer displays "Starts in..." or "Auction Ended". Bidding sheet disabled outside live window. |
| **First Bid Rule** | If auction has zero bids, bid must be $\ge \text{startingPrice}$. | Quick bid input defaults to starting price. |
| **Subsequent Bid Rule**| If bids exist, bid must be $\ge \text{currentHighestBid} + \text{minIncrement}$. | Input field displays exact required minimum (`minRequiredBid`). Rejects with explanatory error if lower. |
| **Outcome Determination**| At end time, highest valid bidder is recorded as `winner`. If zero bids placed, `winner = null` (marked as Unsold). | Ended card displays green "Winner: Alice" badge or neutral "No Bids Placed". |
| **Immutability** | No edit or withdrawal endpoints exist. Bids are permanently appended to the Mongoose `bids` subdocument array. | Bid history list is immutable and read-only. |

---

## 5. Non-Functional Requirements & Key Engineering Solutions

### 1. Concurrency & Race Condition Safety
- **Requirement**: *"Bids placed on the same auction at the same time must still produce a correct result."*
- **Solution**: MongoDB Atomic Conditional Update (`Auction.findOneAndUpdate`):
```javascript
const filter = {
  _id: id,
  status: 'live',
  startTime: { $lte: now },
  endTime: { $gt: now },
};

if (!hasExistingBids) {
  filter.bids = { $size: 0 };
  filter.startingPrice = { $lte: amount };
} else {
  // Database-level atomic condition: Current highest bid cannot have advanced past amount - minIncrement
  filter.currentHighestBid = { $lte: amount - auction.minIncrement };
}

const update = {
  $set: { currentHighestBid: amount, currentHighestBidder: req.user._id },
  $push: { bids: { bidder: req.user._id, amount, createdAt: now } },
};

const updatedAuction = await Auction.findOneAndUpdate(filter, update, { new: true });
```
- **Stress Test Verification (`test_concurrency.js`)**:
  - 10 simultaneous asynchronous HTTP requests bid \$1,050 at the exact same millisecond.
  - Result: **Exactly 1 bid succeeded (200 OK)**. The remaining **9 were rejected (409 Conflict)** with the updated minimum required bid.

### 2. Automated Lifecycle Worker & Restart Resilience
- **Requirement**: *"Each auction closes and records its result at its end time. This happens even if nobody is using the app at that moment, and even if the server restarts."*
- **Solution**:
  - In-process background scheduler (`backend/src/services/auctionWorker.js`) runs every **4 seconds**.
  - **Cold Boot Catch-Up**: On server boot/restart, `processAuctionTransitions()` runs immediately before listening to network requests. Any auction that expired during server downtime is processed and closed with winner assigned.
  - Broadcasts `auction_ended` and `auction_started` over WebSockets and records winners in the database.

### 3. Universal UTC Timezone Handling
- **Issue**: Indian Standard Time (IST, UTC+05:30) vs UTC server clock previously caused an artificial ~5-hour scheduling delay when creating auctions.
- **Solution**:
  - Flutter converts all user-selected dates to UTC ISO strings ending in `'Z'` (`startTime.toUtc().toIso8601String()`).
  - Backend evaluates all timestamps against `new Date()`.
  - Flutter deserializes all dates using `.toLocal()` to format according to the user's device clock.

### 4. Render Free-Tier Keep-Alive System
- **Issue**: Render free tier services go to sleep after 15 minutes of inactivity.
- **Solution**:
  - **Server-Side Self-Ping**: `startKeepAlive(4 * 60 * 1000)` in `backend/src/services/keepAliveService.js` issues a GET request to its own `/health` endpoint every 4 minutes.
  - **Client-Side Keep-Alive**: Flutter's `AuctionProvider` runs a periodic 4-minute keep-alive ping whenever the app is open.

### 5. Persistent Image Storage
- **Solution**:
  - Multer stores uploaded images with unique timestamps on disk in `backend/uploads/`.
  - Express serves this directory as static assets at `/uploads/:filename`.
  - Stored in the git repository structure so deployed instances keep assets available.

### 6. Design System & UI Architecture
- **Theme**: Luxury navy blue (`#0D1B2A`), royal slate (`#1B263B`), metallic amber/gold accents (`#E0A96D`), and clean off-white surfaces (`#F8F9FA`).
- **Launcher Icons**: Custom gold gavel crest vector rendered across Android mipmap buckets (`mdpi` through `xxxhdpi`, adaptive icons with XML foreground/background layers).
- **Responsive Layout**: Adapts gracefully between mobile portrait and tablet/desktop wide screens using `MediaQuery` and `LayoutBuilder`.
- **States**:
  - **Loading**: Custom shimmering loading indicator.
  - **Empty**: Context-specific cards with explanatory messages when no auctions exist in a tab.
  - **Error Handling**: Distinct snackbar banners indicating exact reasons for rejections.

---

## 6. Pre-Seeded Accounts & Credentials

The system comes pre-seeded with 1 Administrator and 5 Users. One-tap demo account selector buttons are provided directly on the Login screen:

| Role | Name | Email | Password | Primary Permissions |
| :--- | :--- | :--- | :--- | :--- |
| **Admin** | Auction Admin | `admin@auction.com` | `admin123` | Create auctions, upload photos, monitor all bids & winners |
| **User 1** | Alice Walker | `alice@auction.com` | `user123` | Browse, place bids, live socket updates, win tracking |
| **User 2** | Bob Martinez | `bob@auction.com` | `user123` | Browse, place bids, live socket updates, win tracking |
| **User 3** | Charlie Chen | `charlie@auction.com` | `user123` | Browse, place bids, live socket updates, win tracking |
| **User 4** | Diana Prince | `diana@auction.com` | `user123` | Browse, place bids, live socket updates, win tracking |
| **User 5** | Ethan Hunt | `ethan@auction.com` | `user123` | Browse, place bids, live socket updates, win tracking |

---

## 7. Verification & Quality Assurance

- **Flutter Static Analysis**: `flutter analyze` $\rightarrow$ **0 issues**.
- **Automated Test Suite**: `flutter test` $\rightarrow$ **All 15 unit and widget tests passed**.
- **Backend Concurrency Stress Test**: `npm run test:concurrency` $\rightarrow$ **100% pass (Zero race conditions)**.
- **Production APK**: Compiled release APK at `build/app/outputs/flutter-apk/app-release.apk` (56.5 MB).
- **Live Deployment**: Live backend verified at `https://house-of-vsb.onrender.com/health`.
