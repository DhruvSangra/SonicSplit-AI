import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const SonicSplitApp());
}

class SonicSplitApp extends StatelessWidget {
  const SonicSplitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SonicSplit',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.deepPurpleAccent,
          thumbColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // ⚠️⚠️⚠️ YAHAN APNA NGROK URL DAALO (Bina last slash ke) ⚠️⚠️⚠️
  final String backendUrl = "https://doddering-carin-unabasing.ngrok-free.dev"; 

  bool isProcessing = false;
  String statusMessage = "Ready to Split 🎵";
  
  // Audio Players
  final AudioPlayer _vocalsPlayer = AudioPlayer();
  final AudioPlayer _drumsPlayer = AudioPlayer();
  final AudioPlayer _bassPlayer = AudioPlayer();
  final AudioPlayer _otherPlayer = AudioPlayer();
  
  bool isPlaying = false;
  
  // Volumes (0.0 to 1.0)
  double _vocalsVol = 1.0;
  double _drumsVol = 1.0;
  double _bassVol = 1.0;
  double _otherVol = 1.0;

  @override
  void dispose() {
    _vocalsPlayer.dispose();
    _drumsPlayer.dispose();
    _bassPlayer.dispose();
    _otherPlayer.dispose();
    super.dispose();
  }

  Future<void> pickAndProcess() async {
    // 1. Permission (Android 13+ might need explicit check, basic storage for now)
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // 2. Pick File
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null) return;

    setState(() {
      isProcessing = true;
      statusMessage = "Uploading to AI Engine... 🚀";
    });

    try {
      File file = File(result.files.single.path!);
      
      // 3. Upload Request
      var request = http.MultipartRequest('POST', Uri.parse('$backendUrl/separate'));

      // 👇👇👇 YE DO LINES ADD KARO (Ngrok Warning Bypass) 👇👇👇
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.headers['User-Agent'] = 'SonicSplitApp'; 
      // 👆👆👆 YAHAN TAK ADD KARO

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      var streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        setState(() => statusMessage = "Checking Response...");
        
        var response = await http.Response.fromStream(streamedResponse);
        
        // 🔍 DEBUGGING START (Ye batayega ki file kya hai)
        print("-------------------------------------------------");
        print("📥 Server Response Size: ${response.bodyBytes.length} bytes");
        
        // Agar file text/html hai toh shuru ke 500 akshar print karo
        if (response.bodyBytes.length > 0) {
            String contentStart = String.fromCharCodes(response.bodyBytes.take(500));
            print("📜 File Content Preview:\n$contentStart");
        } else {
            print("❌ File Khaali hai (0 bytes)!");
        }
        print("-------------------------------------------------");
        // 🔍 DEBUGGING END

        final directory = await getApplicationDocumentsDirectory();
        final zipPath = '${directory.path}/stems.zip';
        final zipFile = File(zipPath);
        await zipFile.writeAsBytes(response.bodyBytes);

        // 5. Unzip
        setState(() => statusMessage = "Unzipping Stems... 📂");
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            File('${directory.path}/$filename')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
        }
        
        // 6. Load Players
        await _loadStem(_vocalsPlayer, directory.path, "vocals.wav");
        await _loadStem(_drumsPlayer, directory.path, "drums.wav");
        await _loadStem(_bassPlayer, directory.path, "bass.wav");
        await _loadStem(_otherPlayer, directory.path, "other.wav");

        setState(() {
          isProcessing = false;
          statusMessage = "Ready to Mix! 🎛️";
        });
      } else {
        throw Exception("Server Error: ${streamedResponse.statusCode}");
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
        statusMessage = "Error: $e";
      });
      print("Error details: $e");
    }
  }

  Future<void> _loadStem(AudioPlayer player, String dirPath, String filename) async {
    final dir = Directory(dirPath);
    try {
      final entities = dir.listSync(recursive: true);
      final file = entities.firstWhere(
        (e) => e.path.endsWith(filename),
        orElse: () => throw Exception("$filename not found"),
      );
      await player.setFilePath(file.path);
      await player.setLoopMode(LoopMode.one);
    } catch (e) {
      print("Could not load $filename: $e");
    }
  }

  void togglePlay() {
    if (isPlaying) {
      _vocalsPlayer.pause();
      _drumsPlayer.pause();
      _bassPlayer.pause();
      _otherPlayer.pause();
    } else {
      _vocalsPlayer.play();
      _drumsPlayer.play();
      _bassPlayer.play();
      _otherPlayer.play();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SonicSplit AI"), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Box
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isProcessing) 
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 20, height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                    ),
                  Flexible(child: Text(statusMessage, style: const TextStyle(color: Colors.white70))),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : pickAndProcess,
                icon: const Icon(Icons.upload_file),
                label: const Text("SELECT SONG & SPLIT"),
                style: ElevatedButton.styleFrom(
                  // FIX 3: Used 'primary' instead of 'backgroundColor' for old Flutter
                  primary: Colors.deepPurpleAccent,
                ),
              ),
            ),
            
            const Divider(height: 40, color: Colors.grey),

            // Mixers
            Expanded(
              child: ListView(
                children: [
                  _buildFader("🎤 VOCALS", _vocalsVol, (v) {
                    setState(() => _vocalsVol = v);
                    _vocalsPlayer.setVolume(v);
                  }),
                  _buildFader("🥁 DRUMS", _drumsVol, (v) {
                    setState(() => _drumsVol = v);
                    _drumsPlayer.setVolume(v);
                  }),
                  _buildFader("🎸 BASS", _bassVol, (v) {
                    setState(() => _bassVol = v);
                    _bassPlayer.setVolume(v);
                  }),
                  _buildFader("🎹 MUSIC", _otherVol, (v) {
                    setState(() => _otherVol = v);
                    _otherPlayer.setVolume(v);
                  }),
                ],
              ),
            ),

            // Master Play Button
            GestureDetector(
              onTap: togglePlay,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isPlaying ? Colors.redAccent : Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: (isPlaying ? Colors.red : Colors.green).withOpacity(0.5), blurRadius: 20)
                  ]
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFader(String label, double val, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text("${(val * 100).toInt()}%", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Slider(
          value: val,
          onChanged: onChanged,
          activeColor: Colors.deepPurpleAccent,
          inactiveColor: Colors.grey[800],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}