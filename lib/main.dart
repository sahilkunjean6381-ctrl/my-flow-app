import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(const FlowAiApp());

class FlowAiApp extends StatelessWidget {
  const FlowAiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D14),
      ),
      home: const FlowCanvasScreen(),
    );
  }
}

class SceneItem {
  String actionText;
  String? generatedUrl;
  bool isProcessing;
  SceneItem({required this.actionText, this.generatedUrl, this.isProcessing = false});
}

class FlowCanvasScreen extends StatefulWidget {
  const FlowCanvasScreen({super.key});
  @override
  State<FlowCanvasScreen> createState() => _FlowCanvasScreenState();
}

class _FlowCanvasScreenState extends State<FlowCanvasScreen> {
  File? _charImg;
  final picker = ImagePicker();
  String _charTag = "Young village boy in blue kurta, 3D Pixar style";
  bool _isRunning = false;

  List<SceneItem> scenes = [
    SceneItem(actionText: "Walking in village courtyard, smiling at camera"),
    SceneItem(actionText: "Talking with hand gestures, close-up face"),
  ];

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _charImg = File(picked.path));
  }

  Future<void> _runBatch() async {
    setState(() => _isRunning = true);
    for (var scene in scenes) {
      if (scene.actionText.isEmpty) continue;
      setState(() => scene.isProcessing = true);
      final seed = Random().nextInt(999999);
      final prompt = Uri.encodeComponent("$_charTag, ${scene.actionText}, 8k, sharp");
      final url = "https://image.pollinations.ai/prompt/$prompt?width=576&height=1024&seed=$seed&nologo=true";
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          setState(() {
            scene.generatedUrl = url;
            scene.isProcessing = false;
          });
        }
      } catch (e) {
        setState(() => scene.isProcessing = false);
      }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("⚡ Flow AI Studio"), backgroundColor: const Color(0xFF111827)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🧠 MASTER CHARACTER NODE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  leading: _charImg != null ? Image.file(_charImg!, width: 40, height: 40, fit: BoxFit.cover) : const Icon(Icons.person, color: Colors.cyanAccent),
                  title: Text(_charImg != null ? "Character Photo Locked" : "Tap to pick character photo", style: const TextStyle(fontSize: 12)),
                  onTap: _pickImage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...scenes.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(10), border: const Border(left: BorderSide(color: Colors.amber, width: 4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Scene 0${e.key + 1}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                TextField(
                  controller: TextEditingController(text: e.value.actionText),
                  onChanged: (val) => e.value.actionText = val,
                  decoration: const InputDecoration(hintText: "Enter scene action"),
                ),
                if (e.value.isProcessing) const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()))
                else if (e.value.generatedUrl != null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.network(e.value.generatedUrl!))
              ],
            ),
          )),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        color: const Color(0xFF111827),
        child: ElevatedButton(
          onPressed: _isRunning ? null : _runBatch,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(14)),
          child: Text(_isRunning ? "Processing Batch..." : "⚡ Run Complete Batch"),
        ),
      ),
    );
  }
}
