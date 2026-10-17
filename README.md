# TailorAI

AI-powered tailor / boutique management app (Flutter + Firebase + Gemini).

## Features
- Email login, har user ka data alag (users/{uid}/...)
- Customers + naap (measurements), search, order history
- Orders: status (Cutting / Stitching / Ready / Delivered), advance, delivery date, payments
- Udhaar tracking
- AI: Quick Order (text se order form), AI Naap Assistant, AI Design Ideas,
  AI WhatsApp Message (Urdu / Roman Urdu / English), AI Business Insights

## Setup
1. `flutter create tailor_ai` chalayein, phir is zip ka `lib/` folder aur `pubspec.yaml`
   us naye project mein copy/replace karein. `firestore.rules` bhi rakh lein.
2. `cd tailor_ai && flutter pub get`
3. Firebase: console mein project banayein, **Authentication > Email/Password** enable karein,
   **Firestore Database** create karein, phir `flutterfire configure` chalayein
   (yeh `lib/firebase_options.dart` bana dega).
4. Firestore Rules mein `firestore.rules` ka content paste karke Publish karein.
5. Android: `android/app/src/main/AndroidManifest.xml` mein `<manifest>` ke andar add karein:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <queries>
     <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
     <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
   </queries>
   ```
   Aur `android/app/build.gradle` mein `minSdk` kam az kam 23 rakhein.
6. Gemini API key (aistudio.google.com se) ke saath run karein:
   `flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY`

## Note
- Agar AI error de to `lib/ai.dart` mein `_model` ka naam check karein.
- App ke andar API key production ke liye safe nahi hoti; release se pehle AI calls
  Cloud Function ke peeche rakhein.
