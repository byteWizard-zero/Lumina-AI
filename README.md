# 🌌 Lumina: Immersive AI Friend & Companion

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)

> "Lumina is more than a chatbot—it's a digital confidante. Designed to talk, listen, and remember like a real friend."

**Lumina** is a premium, cross-platform mobile companion application built with Flutter and powered by a FastAPI backend. Unlike transactional AI assistants, Lumina is specifically designed to simulate real-world texting friendships. It features dynamic personality tailoring based on onboarding assessments, persistent memory via Supabase, Google OAuth integration, text-to-speech (TTS) services, and an atmospheric glassmorphic UI.

---

## ✨ Features

* **🎭 Personality-Adaptive Engine:** Starts with a psychological onboarding assessment that customizes the companion's tone, empathy level, boundary rules, and speech patterns.
* **💬 Human-Centric Messaging UI:** Modern, edge-to-edge chat window featuring dynamic message bubbles, ambient entrance animations, realistic typing indicators, and clean rate-limit warning banners.
* **🔊 Speech-to-Text & Immersive Voice:** Built-in speech services allow users to dictate messages and listen to spoken responses with custom soundscapes.
* **💾 Supabase Session Ledger:** Secure authentication via Google Sign-In, coupled with PostgreSQL database tables tracking your conversation history permanently.
* **📴 Resilience Features:** Connection state observers display glassmorphic offline overlays when network connectivity is lost, synchronizing cache once online.
* **⚙️ Scalable FastAPI Backend:** Light, fast backend architecture hosted on Render, containing modular routers for authentication, session handling, onboarding profiles, and rate-limiting.

---

## 🛠️ Tech Stack & Architecture

### Mobile Client
* **Framework:** Flutter (Dart UI Lifecycle Engine)
* **API Connector:** Dio (HTTP client with custom interceptors)
* **Local Storage:** Path Provider & Package Info Plus

### Python Backend
* **Web Framework:** FastAPI (Python 3.11)
* **Server Orchestration:** Uvicorn
* **Database Driver:** Supabase Python SDK (PostgreSQL Integration)

---

## 🚀 Installation & Setup

### For Android Users (APK Download)
To quickly install Lumina on your Android device:
1. Navigate to the **Releases** tab of this repository.
2. Download the latest `Lumina_vX.X.X.apk` file.
3. Install the APK on your device (ensure "Install from Unknown Sources" is enabled in settings).

### Mobile Client Setup
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/byteWizard-zero/Lumina-AI.git
   cd Lumina-AI/client
   ```
2. **Setup Environment Variables:**
   Create an `.env` file inside `client/assets/` and fill in your keys:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anonymous-key
   BACKEND_BASE_URL=http://10.0.2.2:8000
   GOOGLE_CLIENT_ID=your-google-oauth-client-id
   GITHUB_REPO_OWNER=byteWizard-zero
   GITHUB_REPO_NAME=Lumina-AI
   ```
3. **Run Mobile App:**
   ```bash
   flutter pub get
   flutter run
   ```

### Backend Setup
1. **Navigate to Backend Directory:**
   ```bash
   cd ../backend
   ```
2. **Setup virtualenv and install dependencies:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows use venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. **Configure Environment Variables:**
   Create a `.env` file in `backend/`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-supabase-service-role-key
   JWT_SECRET=your_jwt_signing_secret
   ```
4. **Start Web Server:**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
