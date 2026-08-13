# MCQ Exam App 🎓🚀

A modern, highly secure, and feature-rich MCQ (Multiple Choice Question) examination platform built with **Flutter** and **Firebase**. Designed to prevent cheating and provide a seamless experience for both Teachers and Students.

## 🌟 Key Features

### 👨‍🏫 For Teachers
*   **Secure Dashboard:** Teachers can securely register and log in to manage their exams.
*   **Advanced Test Creation:** Create exams with custom durations, names, and negative marking schemes (+4 / -1).
*   **Rich Full-Screen Editor:** Add and edit questions with a full-screen multiline editor.
*   **AI Question Generation:** Automatically generate high-quality questions using AI.
*   **Test Controls:** Toggle tests active/inactive in real-time.
*   **Detailed Analytics:** View student scores, correct/wrong answers, and overall performance in real-time.

### 👨‍🎓 For Students
*   **Anti-Cheating Mechanisms:** 
    *   **Question Shuffling:** Every student gets a unique order of questions.
    *   **Option Jumbling:** Options inside questions are randomized for every student.
    *   **Copy-Paste Block:** Right-click context menus are disabled to prevent copying questions to AI tools.
    *   **Auto-Submit on Tab Switch:** The test automatically submits if the student tries to change tabs or minimize the app.
*   **Seamless Navigation:** A beautiful bottom sheet grid navigator to jump to any question.
*   **Real-time Review:** Students can review their answers (green for correct, red for wrong) immediately after submitting the test.

## 🛠️ Tech Stack
*   **Frontend:** Flutter (Supports Android, iOS, and Web)
*   **Backend:** Firebase Firestore (NoSQL, Serverless Database)
*   **State Management:** Riverpod
*   **Architecture:** Clean & modern Glassmorphism UI

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (latest version)
*   Firebase Project setup

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   ```
2. Navigate to the project directory:
   ```bash
   cd "mcq app"
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### 🌐 Web Deployment (Vercel)
This app is fully compatible with Flutter Web. To deploy on Vercel:
1. Connect this GitHub repository to Vercel.
2. In Vercel Project Settings, override the Build Command with:
   `git clone https://github.com/flutter/flutter.git -b stable && ./flutter/bin/flutter build web`
3. Override Output Directory to: `build/web`
4. Deploy!

---
*Built with ❤️ using Flutter & Firebase.*
