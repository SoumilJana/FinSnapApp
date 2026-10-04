# FinSnap 💸

A smart, AI-powered personal finance assistant that eliminates the friction of manual budget tracking. FinSnap uses on-device OCR and cloud AI to instantly parse and categorize your spending from payment screenshots and bank statement PDFs.

## 🚀 Why FinSnap?
Tracking expenses manually is tedious, and connecting bank accounts directly can be a privacy concern or technically unreliable. FinSnap bridges the gap. Whenever you make a payment (via UPI, GPay, PhonePe, etc.), you simply "Share" the success screenshot to FinSnap. 

The app acts as your personal financial analyst: it reads the receipt, figures out who you paid, how much it was, categorizes it, and tracks your "Useless/Impulse" spending to actively help you curb bad financial habits.

## 💡 How It Helps
- **Zero Friction Entry**: No typing required. Just share a screenshot or import a PDF statement.
- **Smart Auto-Categorization**: The AI knows that Blinkit = Groceries and Uber = Transport.
- **Bulk Bank Statement Import**: Catch up on months of spending in seconds by bulk importing your PDF bank statements.
- **Guilt Monitor**: Visually tracks impulse purchases to hold you accountable to your budget limits.

## 🛠️ Tech Stack
- **Framework**: Flutter (Dart)
- **OCR Engine**: Google ML Kit (On-device text extraction)
- **AI Brain**: Google Gemini 3.x API (gemini-3.6-flash & gemini-3.1-pro-preview)
- **Database**: Hybrid Architecture (SQLite Local Cache + Firebase Cloud Firestore)

## ✨ Current Features
- [x] **Native OS Share Integration**: Receives images directly from the Android Share Sheet.
- [x] **Offline OCR**: Instantly extracts raw text from screenshots securely on-device.
- [x] **AI Parsing Engine**: Converts messy text into clean structured data (Merchant, Amount, Date, Category).
- [x] **Bulk PDF Import**: Send whole bank statements directly to Gemini Pro for mass extraction.
- [x] **Hybrid Database**: Local SQLite for blazing-fast reads, backed by Firebase Firestore for real-time cloud sync.
- [x] **Dynamic Dashboard**: Automatically recalculates budget, spent today, and impulse totals.

## 🗺️ Future Roadmap
- [x] **Refine AI Parsing & PDF Import (Hybrid Approach)**: Keep the on-device OCR for instant, offline "pending" saves to maintain zero-friction logging. Then, send the raw screenshot image directly to Gemini's vision model in the background to perfectly correct any OCR mistakes (like misreading the '₹' symbol).
- [x] **Transaction Details & Edit Screen**: Click on any transaction to view or edit its details manually to fix any mistakes the AI made.
- [x] **Background Auto-Save Flow**: Save screenshots instantly as pending, and let the AI categorize them completely in the background for true zero-friction.
- [x] **Income Tracking**: Support logging money received (Credits), not just money spent (Debits).
- [ ] **Guilt Monitor Widget**: Build out psychological friction widgets and chart breakdowns.
- [x] **Full Cloud Wipe Button**: A secure setting to wipe both local and cloud databases simultaneously.

## 📜 Version History

### **v0.1.0 - Alpha (Current)**
- Fully operational Hybrid Database (SQLite + Firestore).
- Added Bulk PDF Bank Statement Import capabilities using Gemini 3.1 Pro.
- Updated AI Engine to Gemini 3.x models for improved accuracy and speed.
- Dynamic Dashboard UI now calculates directly from the synced local database.
- Initial project setup, Android intent sharing, and minimal Fintech UI implementation.
