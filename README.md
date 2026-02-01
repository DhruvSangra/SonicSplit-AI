# 🎵 SonicSplit AI: Studio-Grade Audio Stem Separator

**SonicSplit AI** is a high-performance mobile application that leverages Deep Learning to isolate individual tracks (Vocals, Drums, Bass, and Piano/Other) from any audio file. Built for musicians, DJs, and producers who need crystal-clear stem separation on the go.

---

## 🚀 Key Features

- **Ultra-Precision Separation**: Powered by Meta's **Demucs v4 (Hybrid Transformer)** model.
- **Studio Quality**: Implements a 4-shift inference pattern to eliminate artifacts and "bleeding" between tracks.
- **Real-time 4-Channel Mixer**: Independent volume faders for each stem with synchronized, zero-latency playback.
- **GPU-Accelerated Backend**: Seamlessly connects to a CUDA-enabled FastAPI server for rapid processing.
- **Remote-First Architecture**: Integrated secure tunneling via Ngrok with custom header bypass for mobile-to-cloud communication.

---

## 🛠️ Technical Stack

### **Frontend (Mobile)**

- **Framework**: Flutter (Dart)
- **Audio Engine**: `just_audio` with multi-player synchronization.
- **UI/UX**: Minimalist Dark Mode, custom faders, and asynchronous state management.

### **Backend (AI Engine)**

- **Framework**: FastAPI (Python)
- **Model**: Meta Demucs `htdemucs_ft` (Fine-Tuned).
- **Inference**: CUDA / PyTorch.
- **Tunneling**: Ngrok.

---

## 🏗️ Architecture & Logic

1. **The Request Pipeline**: The Flutter app sends a multi-part POST request to the FastAPI server.
2. **The "Smart Detection" Logic**: Backend handles diverse file naming conventions by normalizing inputs to a temporary buffer, ensuring consistent Demucs output directory mapping.
3. **The HQ Processing**: Using `--shifts=4` and `--overlap=0.4`, the model scans the audio multiple times to provide "Zero Noise" output.
4. **The Response**: Stems are dynamically zipped, served as a `FileResponse`, and reconstructed locally on the mobile device's directory for playback.

---

## 🔧 Installation & Setup

### **1. Backend (Google Colab / Local GPU)**

- Clone the repository.
- Install dependencies: `pip install demucs fastapi uvicorn pyngrok`.
- Set your Ngrok Auth Token and run the server script.

### **2. Frontend (Flutter)**

- Update the `backendUrl` in `lib/main.dart` with your Ngrok public URL.
- Run `flutter pub get`.
- Connect your device and run `flutter run`.

---

## 👨‍💻 Author

**Dhruv Sangra**

- **LeetCode Knight (Rating: 1909)**
- **Software Engineer @ MAQ Software**
- **B.Tech @ IIIT Lucknow (2025 Grad)**

---

## 📜 License

This project is licensed under the **MIT License**.
