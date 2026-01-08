# CountSip – Product Requirements Document (PRD)

**Version:** v1.0  
**Status:** Locked (Core)  
**Platform:** Mobile (iOS first, Android compatible)  
**Language:** English  
**Category:** Lifestyle  
**Product Type:** Social drinking tracker with leaderboard

---

## 1. Product Overview
- Social drinking tracker with gamified point system
- Friends can compete on weekly/monthly leaderboards
- Each drink type has point value (Beer: 1pt, Wine: 2pt, Whisky: 3pt, etc.)
- Simple authentication (Email/Google/Apple Sign In)
- Ad-supported (no premium tier in MVP)
- Cloud-first: data syncs across devices

---

## 2. Purpose & Goals
- Make drinking tracking fun and social
- Light-hearted competition among friends
- Answer: "Who drank what, when, and where?"
- No health warnings, no stigma, no judgment
- Pure entertainment and social bonding

---

## 3. Brand Voice & Tone
- Playful, fun, casual
- Party-friendly but not promoting excess
- Emoji support encouraged 🍻
- **Light UI inspired by iOS Calendar:**
  - Clean white background
  - Subtle shadows and borders
  - Large, readable text
  - Minimal decorations
  - Rounded corners (iOS 16+ style)
- Positive reinforcement ("Great night!", "Legend status!")

---

## 4. Authentication & Account System

### 4.1 Sign Up Options
- **Email + Password:** Classic flow with email verification
- **Google Sign In:** One-tap OAuth
- **Apple Sign In:** Required for iOS (App Store compliance)
- No complex recovery seed, standard password reset via email

### 4.2 Profile Setup
- Username (unique, public to friends)
- Display name (can be nickname)
- Optional profile photo (uploaded to cloud storage)
- Age verification: must confirm 18+ (local validation only)

### 4.3 Session Management
- Stay logged in by default
- Firebase Auth handles token refresh
- Logout option in settings

---

## 5. Privacy & Data Policy

### 5.1 Data Storage
- All data stored in Firebase Firestore (plaintext, no encryption)
- User can see their own data + friends' data
- No public discovery (friend requests only)

### 5.2 Data Sharing
- Leaderboard visible only to mutual friends
- Individual entries visible to friends (venue + drink type + points)
- No photo sharing (removed from Seçenek B per request)

### 5.3 Analytics & Ads
- Google Analytics: track screen views, button clicks
- AdMob: interstitial ad after each drink entry submission
- No selling of personal data to third parties

---

## 6. Navigation & Structure

### 6.1 Tab Bar (Bottom Navigation)
- **Home:** Feed of friends' recent drinks + your entries
- **Add:** Big center button (modal) to log new drink
- **Leaderboard:** Weekly/Monthly rankings
- **Profile:** Your stats + settings

### 6.2 Top Bar
- Home: "CountSip" title + notification bell (friend requests)
- Leaderboard: Time filter toggle (Week / Month / All Time)
- Profile: Settings gear icon

---

## 7. Friend System

### 7.1 Adding Friends
- Search by username (exact match or prefix)
- Send friend request
- Accept/decline requests
- Friends list in Profile tab

### 7.2 Friend Feed
- Home tab shows friends' recent entries (last 24 hours)
- Format: "John logged 2x Beer at Murphy's Pub 🍺 (+2pts)"

### 7.3 Privacy
- Leaderboard only shows mutual friends
- Strangers cannot see your entries

---

## 8. Drink Entry System

### 8.1 Drink Types & Points
| Drink Type | Points | Icon |
|------------|--------|------|
| Beer | 1 | 🍺 |
| Wine | 2 | 🍷 |
| Whisky | 3 | 🥃 |
| Vodka | 3 | 🍸 |
| Tequila | 3 | 🥃 |
| Cocktail | 2 | 🍹 |
| Shot | 2 | 🥃 |
| Rakı | 3 | 🥃 |
| Other | 1 | 🍻 |

**Custom Drink Request:**
- "Request New Drink" button at bottom of drink picker
- Opens email compose: `countsip.feedback@gmail.com`
- Subject: "New Drink Request"
- Body template: "I'd like to add: [drink name]"

### 8.2 Entry Fields
- **Drink Type:** Icon grid picker (3x3 grid, large tap targets)
  - Each icon shows: emoji + drink name + points
  - Selected icon highlighted with border
  - Bottom: "Request New Drink" link → opens email
- **Quantity:** Number stepper (- | 1 | +), default: 1, max: 20
- **Venue:** Text input (optional, max 50 chars) - "Murphy's Pub", "Home", "Club XYZ"
- **Time:** Defaults to now, can edit (date + time picker, iOS-style)
- **Note:** Optional text (optional, max 200 chars) - "Great night with the crew!"

### 8.3 Entry Flow
1. User taps "Add" button
2. Modal opens with entry form
3. User fills fields
4. Taps "Log It!" button
5. Interstitial ad shows (AdMob)
6. Entry saved to Firestore
7. Points added to user's total
8. Modal closes, Home tab updates

---

## 9. Leaderboard

### 9.1 Time Periods
- **This Week:** Monday 00:00 - Sunday 23:59 (resets weekly)
- **This Month:** 1st 00:00 - Last day 23:59 (resets monthly)
- **All Time:** Since account creation

### 9.2 Display
- Ranked list of friends by points
- Shows: Rank, Avatar, Username, Total Points
- Your position highlighted in different color
- Top 3 get trophy icons (🥇🥈🥉)

### 9.3 Tiebreaker
- If same points: most recent entry wins higher rank

---

## 10. Profile & Stats

### 10.1 Your Stats
- Total drinks logged
- Total points
- Favorite drink (most logged type)
- Favorite venue (most logged location)
- Streak: consecutive days with at least 1 entry

### 10.2 Settings
- Edit profile (name, photo)
- Friend management
- Notifications toggle (friend requests)
- Delete account (permanent, shows confirmation)
- Logout

---

## 11. Ads Strategy (MVP)

### 11.1 Ad Placement
- **Interstitial:** After each drink entry submission (100% frequency)
- **Banner:** (Future) Bottom of Home tab feed

### 11.2 Ad Network
- AdMob (Google)
- Test ads in development, real ads in production

### 11.3 Future Premium (Not MVP)
- $2.99/month: Remove ads + custom drink types + advanced stats

---

## 12. Technology Stack

### 12.1 Frontend
- Flutter 3.38+
- Riverpod (state management)
- Go Router (navigation)

### 12.2 Backend
- Firebase Auth (email, Google, Apple)
- Firebase Firestore (database)
- Firebase Storage (profile photos)
- Firebase Cloud Messaging (push notifications - future)

### 12.3 Ads
- google_mobile_ads package (AdMob)

---

## 13. Data Schema (Firestore)

### 13.1 Collections

#### users
```
{
  uid: string (Firebase Auth UID)
  username: string (unique)
  displayName: string
  email: string
  photoURL: string (Storage path)
  createdAt: timestamp
  totalPoints: number (denormalized)
  totalDrinks: number (denormalized)
}
```

#### entries
```
{
  id: string (auto-generated)
  userId: string (owner UID)
  drinkType: string (Beer, Wine, etc.)
  quantity: number
  points: number (calculated: drinkType points × quantity)
  venue: string (optional)
  note: string (optional)
  timestamp: timestamp
  createdAt: timestamp
}
```

#### friendships
```
{
  id: string (auto-generated)
  userA: string (UID, alphabetically first)
  userB: string (UID, alphabetically second)
  status: string (pending, accepted)
  requestedBy: string (UID who sent request)
  createdAt: timestamp
  acceptedAt: timestamp (optional)
}
```

---

## 14. MVP Scope (Locked)

### ✅ Must Have
- Email/Google/Apple sign in
- Add drink entry with points
- Friend request system
- Leaderboard (week/month/all-time)
- Home feed (friends' entries)
- Profile stats
- Interstitial ads after entry

### ❌ Not in MVP
- Photo uploads (profile uses default avatar or initials)
- Push notifications
- Chat/comments
- Venue check-in with GPS
- Custom drink types
- Export data

---

## 15. Store Compliance Strategy

### 15.1 Age Rating
- iOS: 17+ (Alcohol, Tobacco, or Drug Use or References)
- Android: Mature 17+ (Alcohol and Tobacco)

### 15.2 App Store Copy
- **Name:** CountSip - Social Drink Tracker
- **Subtitle:** Track drinks with friends
- **Keywords:** drink tracker, alcohol log, social drinking, party app, leaderboard
- **Description:** 
  > "CountSip is a fun, social way to track your drinks with friends. Compete on weekly leaderboards, see what your crew is drinking, and relive epic nights. No judgment, just friendly competition! 🍻"

### 15.3 Screenshots
- Home feed (with sample entries: "John: 2x Beer at O'Malley's")
- Leaderboard (Top 5 with trophy icons)
- Add entry modal (Beer selected)
- Profile stats (clean, no sensitive data)

### 15.4 Privacy Policy (Required)
- Hosted on GitHub Pages or Firebase Hosting
- States: data stored in Firebase, visible to friends, used for ads
- User can delete account anytime

---

## 16. Legal Disclaimers

### 16.1 In-App Warnings
- First launch: "CountSip is for entertainment only. Drink responsibly. Must be 18+ to use."
- No health advice, no BAC calculation, no "safe limit" claims

### 16.2 Terms of Service
- Users agree they are 18+
- App not liable for misuse or health issues
- Standard liability waiver

---

## 17. Launch Checklist

- [ ] Firebase project created (iOS + Android apps)
- [ ] AdMob account setup (test ad units)
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Age gate on first launch
- [ ] Store screenshots prepared
- [ ] Test with 5+ beta users
- [ ] Submit to App Store & Play Store

---

**End of PRD**