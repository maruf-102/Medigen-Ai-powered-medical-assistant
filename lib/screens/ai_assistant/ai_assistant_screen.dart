import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // NEW
import 'package:flutter_tts/flutter_tts.dart';   // NEW

// --- !!! IMPORTANT: PASTE YOUR API KEY HERE !!! ---
const String _apiKey = "paste Your API key Brother!!";
// --------------------------------------------------

// Model for chat message
class ChatMessage {
  final String text;
  final bool isUser;
  final Timestamp timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Image Picker & TTS
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

  late final GenerativeModel _model;
  late final GenerativeModel _visionModel; // NEW: Model for images
  late final ChatSession _chat;

  late final Stream<QuerySnapshot> _messagesStream;
  List<Content> _chatHistory = [];

  bool _isLoading = false;

  // Tracks which message is currently being spoken
  int? _playingIndex;

  final String _aiDisclaimer =
      "Hello! I'm your AI Health Assistant. Please remember, I am an AI and not a medical professional. Always consult a doctor for medical advice.";

  @override
  void initState() {
    super.initState();

    // 1. Standard Text Model
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(
          "You are MediGen. You must follow these rules: "
              "1. NEVER provide a diagnosis or prescribe medication. "
              "2. If the user sends a prescription image, summarize the instructions clearly but add a warning to verify with a pharmacist. "
              "3. Keep answers supportive."
      ),
    );

    // 2. Vision Model (for images)
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(currentUser?.uid)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();

    _loadChatHistory();

    // Setup TTS
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _playingIndex = null; // Stop showing the active icon
      });
    });
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Stop speaking when leaving screen
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    if (currentUser == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentUser!.uid)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();

    _chatHistory = [];
    if (snapshot.docs.isEmpty) {
      await _saveMessageToFirestore(_aiDisclaimer, false);
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      _chatHistory.add(Content(
        data['isUser'] ? 'user' : 'model',
        [TextPart(data['text'])],
      ));
    }
    _chat = _model.startChat(history: _chatHistory);
    _scrollToBottom();
  }

  Future<void> _saveMessageToFirestore(String text, bool isUser) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentUser!.uid)
        .collection('messages')
        .add({
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.now(),
    });
  }

  // --- NEW: Function to Analyze Prescription Image ---
  Future<void> _pickAndAnalyzeImage() async {
    try {
      // Pick image from camera or gallery
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery); // Change to .camera to take a photo
      if (photo == null) return;

      setState(() { _isLoading = true; });

      // 1. Show user we are working
      const userPrompt = "I have uploaded a prescription/medical image. Please summarize it.";
      await _saveMessageToFirestore("📷 [Uploaded an Image]", true);

      // 2. Read image bytes
      final Uint8List imageBytes = await File(photo.path).readAsBytes();

      // 3. Send to Gemini Vision Model
      final prompt = TextPart("Analyze this medical image. Summarize the medications, dosages, and instructions found. Do not hallucinate information.");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _visionModel.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final aiText = response.text;
      if (aiText == null) {
        _addErrorResponse("Could not analyze image.");
        return;
      }

      // 4. Save response
      await _saveMessageToFirestore(aiText, false);

      // Update local history for context
      _chatHistory.add(Content.multi([TextPart(userPrompt)]));
      _chatHistory.add(Content.model([TextPart(aiText)]));

    } catch (e) {
      _addErrorResponse("Image Error: $e");
    } finally {
      setState(() { _isLoading = false; });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final String text = _controller.text;
    if (text.isEmpty || currentUser == null) return;

    await _saveMessageToFirestore(text, true);
    setState(() { _isLoading = true; });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final aiText = response.text;

      if (aiText == null) {
        _addErrorResponse("Empty response.");
        return;
      }
      await _saveMessageToFirestore(aiText, false);

    } catch (e) {
      _addErrorResponse("Error: ${e.toString()}");
    } finally {
      setState(() { _isLoading = false; });
      _scrollToBottom();
    }
  }

  void _addErrorResponse(String errorText) async {
    await _saveMessageToFirestore("Error: $errorText", false);
  }

  // --- NEW: Speak Function ---
  Future<void> _speak(String text, int index) async {
    if (_playingIndex == index) {
      // If clicking the same bubble, stop.
      await _flutterTts.stop();
      setState(() { _playingIndex = null; });
    } else {
      setState(() { _playingIndex = index; });
      await _flutterTts.speak(text);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data?.docs
                    .map((doc) => ChatMessage.fromFirestore(doc))
                    .toList() ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == messages.length) {
                      return _buildMessageBubble(
                          ChatMessage(text: "...", isUser: false, timestamp: Timestamp.now()),
                          index: -1, isLoading: true
                      );
                    }
                    final message = messages[index];
                    return _buildMessageBubble(message, index: index);
                  },
                );
              },
            ),
          ),

          // --- Input Bar ---
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.white,
            child: Row(
              children: [
                // --- NEW: Camera Button ---
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.teal),
                  onPressed: _isLoading ? null : _pickAndAnalyzeImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type or upload prescription...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.teal),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {required int index, bool isLoading = false}) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.topRight : Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // --- NEW: Speaker Icon for AI messages ---
                if (!isUser && !isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => _speak(message.text, index),
                      child: Icon(
                        _playingIndex == index ? Icons.stop_circle : Icons.volume_up,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),

                Flexible(
                  child: ChatBubble(
                    clipper: ChatBubbleClipper1(type: isUser ? BubbleType.sendBubble : BubbleType.receiverBubble),
                    backGroundColor: isUser ? Colors.teal : Colors.white,
                    child: Text(
                      message.text,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 10, right: 10),
              child: Text(
                DateFormat('h:mm a').format(message.timestamp.toDate()),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
