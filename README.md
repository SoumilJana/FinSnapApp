# FinSnap

FinSnap is a smart, AI-powered personal finance and budget tracking application built with Flutter. It completely automates the tedious process of manual expense logging by allowing you to simply share or upload payment screenshots. 

Using advanced on-device and cloud AI, FinSnap intelligently extracts the merchant, amount, date, and automatically categorizes your transactions in seconds.

### 📱 [Download the latest APK here](https://github.com/SoumilJana/FinSnapApp/raw/main/releases/FinSnapApp-v1.0.14.apk)

## ✨ Features

*   **AI Receipt Parsing**: Share a screenshot of any payment confirmation (UPI, Bank Transfer, etc.) directly to the app. FinSnap reads it using a fallback OCR system and Requesty's powerful LLMs to extract exact details.
*   **Intelligent Categorization**: AI automatically categorizes expenses (Groceries, Transport, Entertainment, etc.) and tags them with metadata like "Impulse Buy" or "Necessity".
*   **Android Share Intent Integration**: You don't even need to open the app! Share a screenshot directly from your payment app to FinSnap, and it will process it in the background and pop you right back.
*   **Smart Fallback**: If the AI takes longer than 10 seconds, the app falls back to a lightning-fast offline OCR parser so you are never left waiting.

## 📱 App Pages & Navigation

FinSnap consists of several core pages, each designed to give you complete control and visibility over your finances:

*   **🏠 Home Page**: The main dashboard. Shows your total balance, recent transactions, daily income/expense overview, and quick action buttons to manually add or scan new transactions.
*   **📊 Analytics Page**: Dive deep into your spending data. It features beautiful charts detailing your budget utilization, categorical breakdown (e.g., Food vs. Transport), Necessity vs. Discretionary splits, and month-over-month spending trends.
*   **💡 AI Insights**: A proactive financial health dashboard. Features a personalized "Smart Summary" written by an LLM based on your recent activity, forecasts your end-of-month burn rate, tracks total "Impulse" purchases, and flags spending anomalies (e.g., sudden spikes in dining). It also houses the **AI Transaction Auditor** which reviews unclassified transactions and suggests fixes.
*   **🤖 AI CFO (Chat)**: Your personal AI Chartered Accountant. It has direct context of all your transactions. You can ask it questions like "Where can I cut costs this month?" or "Did I spend too much on cabs last week?" and get precise, data-backed answers.
*   **📝 Review & Edit**: Dedicated screens to review AI-parsed transactions, manually edit amounts/categories, and add custom notes to help the AI learn your specific spending habits for future audits.

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
