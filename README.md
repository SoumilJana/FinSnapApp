# FinSnap

FinSnap is a smart, AI-powered personal finance and budget tracking application built with Flutter. It completely automates the tedious process of manual expense logging by allowing you to simply share or upload payment screenshots. 

Using advanced on-device and cloud AI, FinSnap intelligently extracts the merchant, amount, date, and automatically categorizes your transactions in seconds.

### 📱 [Download the latest APK here](https://github.com/SoumilJana/FinSnapApp/raw/main/releases/FinSnapApp-v1.0.6.apk)

## ✨ Features

*   **AI Receipt Parsing**: Share a screenshot of any payment confirmation (UPI, Bank Transfer, etc.) directly to the app. FinSnap reads it using a fallback OCR system and Requesty's powerful LLMs to extract exact details.
*   **Intelligent Categorization**: AI automatically categorizes expenses (Groceries, Transport, Entertainment, etc.) and tags them with metadata like "Impulse Buy" or "Necessity".
*   **Android Share Intent Integration**: You don't even need to open the app! Share a screenshot directly from your payment app to FinSnap, and it will process it in the background and pop you right back.
*   **Smart Fallback**: If the AI takes longer than 10 seconds, the app falls back to a lightning-fast offline OCR parser so you are never left waiting.
*   **Interactive Analytics**: View monthly breakdowns, spending trends, and categorize your cash flow seamlessly.
*   **AI Financial CFO**: Chat with an AI assistant that analyzes your spending patterns, gives you personalized insights, and helps you optimize your budget.

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (v3.19+)
*   Android Studio / Xcode for emulators
*   An Android Device (For testing the Share Intent behavior)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/SoumilJana/FinSnapApp.git
    cd FinSnapApp
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure API Keys:**
    You will need to provide your own API keys for the AI models to work. Open `lib/transaction_parser.dart` and replace the placeholder keys at the top of the file:
    ```dart
    static const String _openRouterApiKey = 'YOUR_OPENROUTER_API_KEY';
    static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';
    static const String _requestyApiKey = 'YOUR_REQUESTY_API_KEY';
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

## 🛠 Tech Stack

*   **Framework**: Flutter & Dart
*   **Database**: SQLite (via `sqflite`) for local persistence
*   **AI Models**: Gemini & Gemma 4-31b-it (via Requesty / OpenRouter)
*   **State Management**: ValueNotifiers
*   **Platform Integrations**: `receive_sharing_intent` for Android Share Menu

## 🚧 Current Status
FinSnap is currently in active prototyping and testing. 

## 📝 License
This project is for personal use and portfolio purposes.
