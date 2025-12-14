#  Baddel - v1.0 (Beta)

Baddel is a hyper-local mobile marketplace that uses a "Swipe-to-Trade/Buy" gesture to facilitate fast, intuitive, and engaging interactions. The primary goal is to reduce the time it takes to negotiate a deal from hours to minutes. This project is now at a feature-complete Beta stage, ready for user testing.

---

## ✨ Features (v1.0)

*   **Phone Authentication:** Secure sign-in and sign-up using SMS OTP. User profiles are automatically created.
*   **Geolocation-based Feed (The Deck):** The main screen displays a swipeable card stack of items sorted by proximity to the user's current location.
*   **Item Upload with GPS:** Users can upload new items by taking a photo, adding details, and stamping the item with their current GPS coordinates.
*   **Advanced Negotiation (The Action Sheet):** When a user swipes right on an item, they can make:
    *   A direct **Cash Offer**.
    *   A pure **Swap Offer** by selecting an item from their own inventory.
    *   A **Hybrid Offer** by selecting an item and adding a cash top-up via a slider.
*   **Real-time Deal Management:** A dedicated "Deals" screen shows all incoming offers. Sellers can accept or reject offers.
*   **Real-time Chat:** Once a deal is accepted, a chat room is created, allowing users to communicate in real-time to finalize the exchange.
*   **Gamified User Profiles (The "Tajer" Profile):** A profile screen that displays user stats like reputation score, level (e.g., "Novice," "Merchant"), and item counts.
*   **Inventory Management:** Users can view their active items on their profile and mark them as "deleted" (soft delete).
*   **In-App Notifications:** The app listens for real-time events and displays in-app notifications for new offers.

---

## 🛠️ Technology Stack

*   **Mobile Framework:** [Flutter](https://flutter.dev/) (Dart)
    *   **UI Packages:** `flutter_card_swiper`, `image_picker`, `geolocator`, `flutter_native_splash`.
*   **Backend:** [Supabase](https://supabase.io/)
    *   **Authentication:** Supabase Auth for Phone (OTP) and Anonymous sign-in.
    *   **Database:** PostgreSQL with the PostGIS extension for efficient geospatial queries.
    *   **Realtime:** Supabase Realtime for live chat and notifications.
    *   **Storage:** Supabase Storage for user-uploaded item images.

---

## 🚀 Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

*   A free account on [Supabase](https://supabase.io/).
*   Flutter SDK installed on your local machine.

### Setup

1.  **Clone the repository.**

2.  **Set up the Supabase Backend:**
    *   Create a new project on Supabase.
    *   Go to **Authentication -> Providers** and enable **Phone** and **Anonymous** sign-in.
    *   Go to the **SQL Editor** and run the entire `baddel_schema.sql` script to create all necessary tables and the geolocation function.
    *   Go to **Storage** and create a new, public bucket named `baddel_images`.

3.  **Configure Environment Variables:**
    *   In the root of the project, create a `.env` file and add your Supabase Project URL and anon public key:
        ```env
        SUPABASE_URL=YOUR_SUPABASE_URL
        SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
        ```

4.  **Configure Native Permissions:**
    *   **Android:** Ensure the permissions in `android/app/src/main/AndroidManifest.xml` are present (INTERNET, ACCESS_FINE_LOCATION, CAMERA, etc.).
    *   **iOS:** Ensure the usage descriptions in `ios/Runner/Info.plist` are present (NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, etc.).

5.  **Run the App:**
    *   Install the dependencies:
        ```sh
        flutter pub get
        ```
    *   Run the application:
        ```sh
        flutter run
        ```

---

This README provides a comprehensive guide to the Baddel v1.0 Beta project.
# Baddel

## Performance Considerations

To ensure a smooth and responsive user experience, this application follows key Flutter performance best practices.

### Const Constructors

Stateless widgets and their properties (such as `TextStyle`, `EdgeInsets`, and `BoxDecoration`) are declared as `const` wherever possible. This allows Flutter's rendering engine to cache these widget instances and avoid unnecessary rebuilds, leading to significant improvements in UI performance. This practice is applied consistently throughout the app, particularly in UI-heavy screens like the `HomeDeckScreen`.
# Baddel - The Smart Marketplace

Baddel is a next-generation mobile marketplace for the Algerian market, combining the intuitive swipe-based discovery of dating apps with a flexible trading and bartering system. It's built with Flutter for a smooth cross-platform experience and powered by a sophisticated Supabase backend.

## ✨ Features

This isn't just another classifieds app. Baddel is packed with production-grade features designed to create an engaging, secure, and intelligent trading experience.

-   **🧠 ML-Powered Recommendation Engine:** A sophisticated, 9-factor algorithm that learns from user behavior to provide personalized item recommendations. It considers everything from proximity and price to item quality and user preferences.
-   **🎨 Premium UI/UX:**
    -   **Advanced Card Swiper:** A custom-built, physics-based card swiper for a fluid and satisfying browsing experience.
    -   **Premium Onboarding:** A beautiful, animated onboarding flow to welcome and educate new users.
    -   **Premium Chat:** A real-time chat interface complete with typing indicators, read receipts, and an optimistic UI for a snappy feel.
-   **🎮 Complete Gamification System:** An extensive achievement and quest system designed to make trading addictive. Users can unlock 30+ achievements, complete daily quests, and climb leaderboards.
-   **📊 Admin Analytics Dashboard:** A secure, admin-only dashboard providing real-time insights into user growth, item popularity, geographic distribution, and more.
-   **🔐 Secure by Design:** The backend is built with Supabase's Row Level Security (RLS) to ensure users can only access and modify their own data. All sensitive operations are protected.

## 🚀 Getting Started

### Prerequisites

-   Flutter SDK
-   A Supabase project

### 1. Flutter Client Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-repo/baddel.git
    cd baddel
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Supabase:**
    Open `lib/main.dart` and replace the placeholder credentials with your actual Supabase URL and anon key:
    ```dart
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

### 2. Supabase Backend Setup

This project contains a comprehensive set of SQL scripts to set up your Supabase database.

1.  **Navigate to the Supabase SQL Editor:**
    In your Supabase project dashboard, go to the "SQL Editor" section.

2.  **Execute the Migration Script:**
    Open the `V1__premium_features_migration.sql` file in the root of this repository. Copy its entire contents and paste it into a new query in the Supabase SQL Editor.

3.  **Run the script:**
    Click the "Run" button. This single script will:
    -   Create all necessary tables (`user_stats`, `achievements`, `item_scores`, `blocked_users`, etc.).
    -   Apply all required table alterations (e.g., adding `reputation_score` to `users`).
    -   Create all the powerful SQL functions for recommendations, gamification, and analytics.
    -   Seed the database with the initial set of achievements.

## 🛠️ Tech Stack

-   **Frontend:** Flutter
-   **Backend:** Supabase (PostgreSQL, Auth, Storage)
-   **State Management:** `setState` / `FutureBuilder` (easily adaptable to Riverpod or other solutions)
-   **Database:** PostgreSQL with PostGIS for geospatial queries.

This project is the result of a massive effort to build a production-grade application from the ground up, integrating some of the most advanced features found in modern mobile apps. Enjoy!
