# Tech Stack – CountSip

**Status:** Locked (MVP)  
**Last Updated:** January 2025  
**Flutter SDK:** 3.38+ (stable)  
**Dart SDK:** 3.10+

---

## Core Dependencies

### UI & Navigation
- `go_router: ^14.0.2` - Declarative routing with deep links
- `flutter_svg: ^2.0.9` - SVG icons
- `shimmer: ^3.0.0` - Loading states
- `cached_network_image: ^3.3.1` - Profile photo caching

### State Management
- `flutter_riverpod: ^2.4.10` - State management
- `riverpod_annotation: ^2.3.5` - Code generation for providers

### Firebase (Backend)
- `firebase_core: ^3.6.0` - Firebase initialization
- `firebase_auth: ^5.3.1` - Authentication (Email, Google, Apple)
- `cloud_firestore: ^5.4.4` - Database
- `firebase_storage: ^12.3.4` - Profile photo storage (future)
- `google_sign_in: ^6.2.1` - Google OAuth
- `sign_in_with_apple: ^6.1.2` - Apple Sign In

### Ads
- `google_mobile_ads: ^5.2.0` - AdMob integration

### Utilities
- `intl: ^0.19.0` - Date/time formatting
- `timeago: ^3.7.0` - "2 hours ago" formatting
- `uuid: ^4.5.1` - Unique ID generation
- `flutter_dotenv: ^5.1.0` - Environment variables (.env)
- `url_launcher: ^6.3.1` - Open email for custom drink request

### Local Storage (Minimal)
- `shared_preferences: ^2.2.3` - Local settings (theme, onboarding state)

---

## Dev Dependencies

- `build_runner: ^2.4.13` - Code generation
- `riverpod_generator: ^2.4.3` - Riverpod code gen
- `flutter_lints: ^5.0.0` - Linting rules
- `flutter_test` - Testing framework (SDK)
- `mocktail: ^1.0.4` - Mocking for tests
- `fake_cloud_firestore: ^3.0.3` - Firestore mocking

---

## Platform Requirements

- **iOS:** 13.0+ (Firebase Auth requirement)
- **Android:** API 23+ (Android 6.0 Marshmallow minimum)
- **Target SDK:** Android 34+ (Play Store requirement)

---

## Firebase Configuration

### Required Firebase Services
1. **Authentication:**
   - Email/Password provider
   - Google provider
   - Apple provider (iOS only)

2. **Firestore:**
   - Collections: `users`, `entries`, `friendships`
   - Security Rules: authenticated users only

3. **Storage:**
   - Bucket: profile photos (future feature)
   - Rules: users can only upload to their own folder

4. **Cloud Functions:** (Future, not MVP)
   - Weekly leaderboard reset
   - Send push notifications

---

## AdMob Setup

### Ad Units (Create in AdMob Console)
- **Test Ads (Development):**
  - Interstitial: `ca-app-pub-3940256099942544/1033173712`
  
- **Production Ads:**
  - Create real ad units after app approval
  - iOS Interstitial: `ca-app-pub-XXXXXXXX/XXXXXXXXXX`
  - Android Interstitial: `ca-app-pub-XXXXXXXX/XXXXXXXXXX`

---

## Environment Variables (.env)

```env
# Firebase (from Firebase Console)
FIREBASE_API_KEY_IOS=AIzaSy...
FIREBASE_API_KEY_ANDROID=AIzaSy...
FIREBASE_PROJECT_ID=countsip-prod
FIREBASE_MESSAGING_SENDER_ID=123456789

# AdMob
ADMOB_APP_ID_IOS=ca-app-pub-XXXXXXXX~XXXXXXXXXX
ADMOB_APP_ID_ANDROID=ca-app-pub-XXXXXXXX~XXXXXXXXXX
ADMOB_INTERSTITIAL_ID_IOS=ca-app-pub-XXXXXXXX/XXXXXXXXXX
ADMOB_INTERSTITIAL_ID_ANDROID=ca-app-pub-XXXXXXXX/XXXXXXXXXX

# Feature Flags
ENABLE_ADS=true
ENABLE_ANALYTICS=true
```

---

## Rationale

### Why Firebase over Supabase?
- **Simpler social features:** Firestore real-time listeners perfect for feed
- **Better Auth:** Google/Apple Sign In native support
- **AdMob integration:** Same ecosystem (Google)
- **Free tier:** Generous limits for MVP (50K reads/day, 20K writes/day)

### Why Riverpod over Bloc?
- Type-safe, compile-time safety
- Less boilerplate than Bloc
- Better testing support
- Matches team preference from BodyCounter

### Why Go Router?
- Deep linking for friend invite URLs (future)
- Tab bar + modal navigation support
- Declarative routing fits Flutter 3.x

---

## Package Update Strategy

```bash
# Check for updates
flutter pub outdated

# Update all (after testing)
flutter pub upgrade

# Major version updates (careful)
flutter pub upgrade --major-versions
```

---

## Security Considerations

### Firebase Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Entries: owner can write, friends can read
    match /entries/{entryId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null; // Friends check in app logic
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
    
    // Friendships: participants can read/write
    match /friendships/{friendshipId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userA || 
         request.auth.uid == resource.data.userB);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.userA || 
         request.auth.uid == resource.data.userB);
    }
  }
}
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId && 
        request.resource.size < 5 * 1024 * 1024 && // 5MB max
        request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## Testing Dependencies

```yaml
dev_dependencies:
  # Already listed above
  fake_cloud_firestore: ^3.0.3
  firebase_auth_mocks: ^0.14.1
  
  # Additional for integration tests
  integration_test:
    sdk: flutter
```

---

## CI/CD Notes (Future)

- **GitHub Actions:** Auto-build on PR
- **Codemagic / Fastlane:** Deploy to TestFlight / Internal Testing
- **Firebase App Distribution:** Beta testing

---

**End of Tech Stack Document**