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
