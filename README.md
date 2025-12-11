# 📱 Baddel - The Tinder-Shopping App

Baddel is a hyper-local mobile marketplace that uses the "Swipe" gesture to facilitate fast, intuitive, and engaging buying, selling, and swapping of items. The primary goal is to reduce the time it takes to negotiate a deal from hours (on traditional platforms) to minutes.

This project is currently in active development, focusing on the core user experience as defined in the [Product Blueprint](https://gist.github.com/Sad-Gihub/2b36f731c19b22b27419e186a2468d2b).

---

## ✨ Features Implemented (Phase 1)

*   **Phone Authentication:** Secure sign-in and sign-up using OTP (One-Time Password) sent to the user's phone number.
*   **The Deck:** The main screen where users can browse items from other users in a familiar swipe-card interface.
    *   Swipe Left to Pass.
    *   Swipe Right to open the Action Sheet.
*   **The Garage:** A personal space where users can see all the items they have uploaded for sale or swap.
*   **Item Upload:** Users can upload new items by picking an image from their gallery, adding a title, description, and price.
*   **Cash Offer System:** When a user swipes right, they can make an immediate cash offer on an item, which is then recorded in the backend.

---

## 🛠️ Technology Stack

*   **Mobile Framework:** [Flutter](https://flutter.dev/) (Dart)
    *   **State Management/DI:** `get_it` for service location.
    *   **UI Packages:** `flutter_card_swiper` for the main deck, `image_picker` for selecting photos.
*   **Backend:** [Supabase](https://supabase.io/)
    *   **Authentication:** Supabase Auth for OTP phone sign-in.
    *   **Database:** PostgreSQL with PostGIS for geospatial queries.
    *   **Storage:** Supabase Storage for user-uploaded item images.
*   **Image Processing (Planned):** [Cloudinary](httpss://cloudinary.com/) for AI-based background removal and enhancement.

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   An account on [Supabase](https://supabase.io/).
*   Flutter SDK installed on your local machine. You can find the installation guide [here](https://docs.flutter.dev/get-started/install).

### Setup

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/baddel.git
    ```

2.  **Set up the Supabase Backend:**
    *   Create a new project on Supabase.
    *   Navigate to the **SQL Editor** and run the contents of the `baddel_schema.sql` file to set up the necessary tables and policies.
    *   In your Supabase project settings, go to **Storage** and create a new bucket named `items`. Make it a public bucket.

3.  **Configure Environment Variables:**
    *   In the root of the project, create a `.env` file.
    *   Copy your Supabase **Project URL** and **anon public key** into the `.env` file like this:
        ```env
        SUPABASE_URL=YOUR_SUPABASE_URL
        SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
        ```

4.  **Run the App:**
    *   Install the dependencies:
        ```sh
        flutter pub get
        ```
    *   Run the application:
        ```sh
        flutter run
        ```

---

This README provides a clear and concise guide to the Baddel project, its current state, and how to get involved.
