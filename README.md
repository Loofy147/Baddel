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
