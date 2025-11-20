import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateThreadScreen extends StatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _titleController = TextEditingController();
  final _postController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = ['Mental Health', 'Nutrition', 'Fitness', 'General'];

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    setState(() { _isLoading = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("You must be logged in to post.");
      return;
    }

    try {
      // 1. Get the user's name from the 'users' collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final authorName = userDoc.data()?['fullName'] ?? 'Anonymous';

      // 2. Create the new thread document
      final newThreadRef =
      await FirebaseFirestore.instance.collection('forumThreads').add({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'authorName': authorName,
        'authorId': user.uid,
        'replyCount': 1, // The post itself is the first "reply"
        'lastActivity': Timestamp.now(),
        'lastActivityBy': authorName,
        'createdAt': Timestamp.now(),
        'isDeleted': false, // <-- ADD THIS LINE
      });

      // 3. Add the user's post as the first reply in the 'replies' sub-collection
      await newThreadRef.collection('replies').add({
        'content': _postController.text.trim(),
        'authorName': authorName,
        'authorId': user.uid,
        'timestamp': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to the forum list
      _showSuccess("Discussion started successfully!");

    } catch (e) {
      _showError("Error creating post: $e");
    }

    setState(() { _isLoading = false; });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Start New Discussion'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Title Field ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Discussion Title',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Category Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select a Category'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Post Content Field ---
              TextFormField(
                controller: _postController,
                decoration: const InputDecoration(
                  labelText: 'Your Post',
                  hintText: 'Share your thoughts, questions, or experiences...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 10,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write your post.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post Discussion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}