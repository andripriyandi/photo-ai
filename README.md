# Photo AI – Test Project

A small **single-screen Flutter app** that turns a user’s portrait into multiple AI-generated “remix” scenes.

This project implements the technical brief:

- Flutter app with **one main screen**
- **Firebase Anonymous Auth**
- **Firebase Storage** for original + generated images
- **Cloud Firestore** for metadata
- **Firebase Cloud Functions (TypeScript)** to call the **Gemini image generation API** (or NanoBanana-compatible endpoint)
- Original + generated images stored in Firebase and displayed in the app

The UI is designed as a **clean, Apple Design Award–style single screen**: simple hierarchy, modern typography, smooth transitions, and responsive layout.

---

## 1. Tech Stack

### Frontend (Flutter)

- Flutter (Material)
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `cloud_functions`
- `image_picker`

Additional points:

- Uses **Anonymous Auth** only — no email/password or social providers.
- Connects to **Firebase Emulator Suite** in development, and can be pointed to production Firebase if deployed.
- The main UI is a **single page** (`photo_ai_page.dart`) that:
  - Lets the user pick a portrait from the device
  - Shows upload & generation progress
  - Displays original + generated images in a responsive layout.

### Backend (Firebase)

- Firebase Authentication (Anonymous)
- Cloud Firestore
- Cloud Storage
- Cloud Functions (Node 20, **TypeScript**)
- Google Gemini image generation API (via HTTPS call inside the Function)

Additional points:

- All AI calls and secrets stay in **Cloud Functions**.
- The client never stores or exposes the Gemini API key.
- Firestore stores per-user session metadata under `users/{uid}/sessions/{sessionId}`.
- Storage stores original + generated images grouped per session.

---

## 2. High-Level Flow

1. **App initialization**

   - Flutter app starts.
   - `firebase_core` initializes Firebase.
   - User is automatically signed in **anonymously** via `FirebaseAuth.instance.signInAnonymously()` if not already authenticated.

2. **User selects a portrait**

   - From the single main screen, the user taps a button to select an image from the gallery (using `image_picker`).
   - Only portrait-style images are expected (no strict enforcement, but the UX is optimized for faces).

3. **Upload original image**

   - The app uploads the original image to **Cloud Storage** under a per-user, per-session path, for example:
     - `uploads/{uid}/{sessionId}/original.jpg`
   - After upload, the app calls a **callable Cloud Function**: `generateImages`.

4. **Call Cloud Function: `generateImages`**

   - The client sends:
     - `originalImagePath` – the Storage path of the uploaded image
     - `styles` – an array of style prompts (e.g., `"Cyberpunk city"`, `"Fantasy forest"`, etc.)
     - `sessionId` – a unique ID (generated on the client, e.g., a timestamp or UUID)
   - Example request payload:
     ```json
     {
       "originalImagePath": "uploads/UID/SESSION_ID/original.jpg",
       "styles": ["Cyberpunk city", "Fantasy forest", "Noir detective"],
       "sessionId": "SESSION_ID"
     }
     ```

5. **Cloud Function: download + call Gemini**

   - The function:
     - Resolves the Storage bucket and downloads the original image.
     - Calls the **Gemini image generation API** (or NanoBanana-compatible endpoint) for each style.
     - For each generated image, stores it back to Storage under the same session:
       - `uploads/{uid}/{sessionId}/generated_{index}.jpg`
     - Returns a list of **generated Storage paths** to the client:
       ```ts
       interface GenerateImagesResponse {
         originalImagePath: string;
         generatedImagePaths: string[];
       }
       ```

6. **Store metadata in Firestore**

   - After receiving the function response, the client writes a document to:
     - `users/{uid}/sessions/{sessionId}`
   - Example document shape:
     ```json
     {
       "sessionId": "SESSION_ID",
       "createdAt": "2025-12-03T12:00:00.000Z",
       "originalImagePath": "uploads/UID/SESSION_ID/original.jpg",
       "generatedImagePaths": [
         "uploads/UID/SESSION_ID/generated_0.jpg",
         "uploads/UID/SESSION_ID/generated_1.jpg",
         "uploads/UID/SESSION_ID/generated_2.jpg"
       ],
       "styles": ["Cyberpunk city", "Fantasy forest", "Noir detective"],
       "status": "completed",
       "errorMessage": null
     }
     ```

7. **Display in the UI**

   - The app converts the Storage paths into **download URLs** (via `getDownloadURL`).
   - The main screen shows:
     - The **original portrait**.
     - The set of **generated “remix” scenes** in a responsive grid.
   - The layout adapts to phone/tablet sizes while remaining a single main screen.

8. **Error handling**
   - If something fails (upload, function call, or Firestore write), the app:
     - Shows a user-friendly error message.
     - Keeps the UI in a safe state, without exposing any technical details or secrets.

All AI calls and secrets stay in the **Cloud Function**, not in the client.

---

## 3. Project Structure

```text
photo_ai_test/
├─ lib/
│  ├─ main.dart
│  ├─ firebase_options.dart          # generated by `flutterfire configure`
│  └─ features/
│     ├─ domain/
│     │  ├─ entities/
│     │  │  └─ photo_session.dart
│     │  └─ repositories/
│     │     └─ photo_session_repository.dart
│     ├─ data/
│     │  └─ repositories/
│     │     └─ photo_session_repository_impl.dart
│     └─ presentation/
│        └─ pages/
│           └─ photo_ai_page.dart
├─ functions/
│  ├─ src/
│  │  └─ index.ts                    # Cloud Function: generateImages
│  ├─ lib/                           # compiled JS output
│  ├─ package.json
│  ├─ tsconfig.json
│  └─ .eslintrc.js (optional)
├─ firestore.rules
├─ storage.rules
└─ README.md
```