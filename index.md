أنت مهندس Flutter محترف + معماري أنظمة Firebase محترف.

مهمتك:
Build a complete, professional, scalable Flutter chat application similar to WhatsApp.

App Name: yemenChat  
Language: English  
Backend: Firebase (Authentication + Firestore + Storage + Cloud Messaging)

Coding Principles:
- Clean Architecture
- MVC Pattern
- Readable & Simple Code
- No complex or over-engineered logic
- Beginner-friendly
- Production Ready
- Fully commented code
- Responsive UI

Project Folder Structure (STRICT):
lib/
 ├── controllers/
 ├── screens/
 ├── widgets/
 ├── models/
 ├── services/
 ├── utils/
 └── main.dart

-------------------------------------------------
FEATURES REQUIRED:
-------------------------------------------------

1️⃣ AUTH FLOW:
- Splash Screen:
  Animated logo + app name + smooth transitions.
  Auto check login state:
    - If logged in → Home Screen
    - Else → Welcome Screen

- Welcome Screen:
  App logo
  App name
  Two buttons:
    - Sign In
    - Sign Up
  Beautiful UI matching app colors.

- Sign Up Screen:
  Fields:
    - Full Name
    - Username
    - Phone Number
    - Email
    - Password
  Validation:
    - Strong validation
    - Check duplicates (email & username) using Firebase
  Save full user profile to Firestore.
  Auto login after successful signup.

- Sign In Screen:
  Fields:
    - Email or Username
    - Password
  Firebase validation.
  Proper error handling.

-------------------------------------------------

2️⃣ HOME SCREEN:
AppBar:
- User first name
- Profile avatar icon → opens Drawer
- PopupMenu:
    - New Chat
    - Delete Chat
    - Pin Chat
    - Select All
    - Settings
  (Show extra options only when selecting chats)

Body:
- Search bar (real-time search)
- Chats list:
    Each chat card shows:
      - User avatar
      - Username
      - Last message
      - Date
    Click:
      - Card → Open Chat Screen
      - Avatar → Open Contact Info Screen

Drawer:
- Profile info card
- Theme switcher
- Buttons:
    - Profile
    - Settings
    - Logout

Floating Action Button:
- Start new chat
- Select contact → Open chat

Bottom Navigation Bar:
- Chats
- Contacts
- Favorites

-------------------------------------------------

3️⃣ CONTACT SCREEN:
- List all registered users from Firestore
- Professional cards
- Tap:
    - Card → Chat screen
    - Avatar → Contact Info

-------------------------------------------------

4️⃣ PROFILE SCREEN:
Show:
- Avatar
- Full name
- Username
- Phone
- Email
- Account creation date

Options:
- Edit profile
- Change password
- Security logs (login history)
- Delete account

-------------------------------------------------

5️⃣ FAVORITES SCREEN:
- Show all favorite contacts
- Same UI as contacts list

-------------------------------------------------

6️⃣ CHAT SCREEN:
AppBar:
- Username
- Avatar → Contact Info Screen
- Back button
- Search in messages
- PopupMenu:
    - Export chat to PDF
    - Theme customization
    - Delete chat history
    - Edit message
    - Delete message
    - Select all

Messages UI:
- Bubble design
- Different styles for sent/received
- Time under each message
- Auto scroll
- Real-time updates (Firestore streams)

Message input:
- Text input
- Send button
- Camera + Gallery upload
- Image sending

-------------------------------------------------

7️⃣ CONTACT INFO SCREEN:
Show:
- Avatar
- Full name
- Username
- Phone
- Email
- Join date

Options:
- Mute notifications
- Add to favorites
- Block user

-------------------------------------------------

8️⃣ SETTINGS SCREEN:
- Theme control
- Login session duration
- Notifications settings
- Other general options

-------------------------------------------------

SECURITY REQUIREMENTS:
- Strong authentication validation
- Secure Firestore rules
- User data isolation
- Each user only sees:
    → Their own chats
    → Their own messages
- Activity logging:
    → Login
    → Logout
    → Password change

-------------------------------------------------

EXTRA FEATURES:
- Advanced search system
- Responsive UI (mobile + tablet)
- Smooth navigation animations
- Firebase Cloud Messaging push notifications
- Realtime chat
- Offline caching
- Message delivery status (sent, delivered, seen)

-------------------------------------------------

FIREBASE STRUCTURE:
Design a professional Firestore database schema including:
- users
- chats
- messages
- favorites
- security_logs
- blocked_users

-------------------------------------------------

OUTPUT REQUIRED:
- Full Flutter project source code
- Full Firebase integration
- UI widgets reusable
- Clean MVC separation
- Step-by-step setup guide
- Firebase setup instructions
- Firestore rules
- Cloud Messaging setup
- App architecture explanation

---------------------
1) مخطط بنية النظام (System Architecture Diagram)
┌───────────────┐
│   Flutter UI  │
└───────┬───────┘
        ↓
┌───────────────┐
│ Controllers   │  ← إدارة المنطق
└───────┬───────┘
        ↓
┌───────────────┐
│ Services      │  ← Firebase API
└───────┬───────┘
        ↓
┌───────────────┐
│ Firebase      │
│ Auth          │
│ Firestore     │
│ Storage       │
│ FCM           │
└───────────────┘

2) مخطط هيكلية الملفات (Project Structure Diagram)
lib/
│
├── controllers/
│   ├── auth_controller.dart
│   ├── chat_controller.dart
│   ├── contact_controller.dart
│   ├── profile_controller.dart
│   └── settings_controller.dart
│
├── screens/
│   ├── splash/
│   ├── auth/
│   ├── home/
│   ├── chat/
│   ├── contacts/
│   ├── profile/
│   ├── favorites/
│   └── settings/
│
├── widgets/
│   ├── chat_bubble.dart
│   ├── user_card.dart
│   ├── custom_button.dart
│   └── input_field.dart
│
├── models/
│   ├── user_model.dart
│   ├── chat_model.dart
│   ├── message_model.dart
│   └── security_log_model.dart
│
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   └── notification_service.dart
│
├── utils/
│   ├── constants.dart
│   ├── validators.dart
│   └── helpers.dart
│
└── main.dart


3) مخطط قاعدة البيانات Firestore (ERD Diagram)
users (collection)
  └── userId
       ├── fullName
       ├── username
       ├── phone
       ├── email
       ├── photoUrl
       ├── createdAt

chats
  └── chatId
       ├── members: [uid1, uid2]
       ├── lastMessage
       ├── lastTime

messages
  └── chatId
       └── messageId
             ├── senderId
             ├── text
             ├── imageUrl
             ├── time
             ├── status

favorites
  └── userId
       └── favoriteUserId

security_logs
  └── logId
       ├── userId
       ├── action
       ├── timestamp

blocked_users
  └── userId
       └── blockedUserId


4) مخطط تدفق التطبيق (Flowchart)
Start
  ↓
Splash Screen
  ↓
Is Logged In?
  ├── Yes → Home Screen
  └── No → Welcome Screen
            ├── Sign In → Home
            └── Sign Up → Home

5) مخطط الأمان (Security Architecture)
Flutter App
   ↓ Token
Firebase Auth
   ↓ UID Check
Firestore Rules
   ↓
User can only:
- Read own chats
- Read own messages
- Write only own data

6) مخطط تدفق الرسائل (Chat Flow)
User A → Firebase → User B
   ↑                    ↓
Realtime Stream ← Firestore Listener

==============================
Firestore Database Schema
users/
  └── {userId}/
       ├── fullName: string
       ├── username: string
       ├── phone: string
       ├── email: string
       ├── photoUrl: string
       ├── fcmToken: string
       ├── createdAt: timestamp
chats/
  └── {chatId}/
       ├── members: [uid1, uid2]
       ├── lastMessage: string
       ├── lastTime: timestamp
       ├── isPinned: map {uid: bool}
messages/
  └── {chatId}/
       └── {messageId}/
             ├── senderId: string
             ├── text: string
             ├── imageUrl: string
             ├── time: timestamp
             ├── status: string (sent/delivered/seen)
favorites/
  └── {userId}/
       └── {favoriteUserId}: true
blocked_users/
  └── {userId}/
       └── {blockedUserId}: true
security_logs/
  └── {logId}/
       ├── userId: string
       ├── action: string (login/logout/password_change)
       ├── timestamp: timestamp
       ├── deviceInfo: string



Create Firebase project at console.firebase.google.com

لقد قمت في Firebase Console ب 
انشاء project باسم : yemenChat
ربط Firebase مع Flutter