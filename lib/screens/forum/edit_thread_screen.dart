import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditThreadScreen extends StatefulWidget {
  final String threadId;
  final String originalTitle;
  final String originalCategory;
  const EditThreadScreen({
    super.key,
    required this.threadId,
    required this.originalTitle,
    required this.originalCategory,
  });

  @override
  State<EditThreadScreen> createState() => _EditThreadScreenState();
}

class _EditThreadScreenState extends State<EditThreadScreen> {
  late TextEditingController _titleController;
  late TextEditingController _postController;
  String? _selectedCategory;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _originalPostId; // The doc ID of the first post

  final List<String> _categories = ['Mental Health', 'Nutrition', 'Fitness', 'General'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.originalTitle);
    _postController = TextEditingController();
    _selectedCategory = widget.originalCategory;
    _loadOriginalPost();
  }

  // Load the content of the original post
  Future<void> _loadOriginalPost() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('forumThreads')
          .doc(widget.threadId)
          .collection('replies')
          .orderBy('timestamp')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        _originalPostId = doc.id; // Save the post's doc ID
        _postController.text = doc.data()['content'] ?? '';
      }
    } catch (e) {
      // Handle error
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate() || _originalPostId == null) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Update the main thread document
      await FirebaseFirestore.instance
          .collection('forumThreads')
          .doc(widget.threadId)
          .update({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
      });

      // 2. Update the original post content
      await FirebaseFirestore.instance
          .collection('forumThreads')
          .doc(widget.threadId)
          .collection('replies')
          .doc(_originalPostId)
          .update({
        'content': _postController.text.trim(),
      });

      if (mounted) Navigator.of(context).pop(); // Go back
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Edit Discussion'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Discussion Title'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select a Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (v) => (v == null) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _postController,
                decoration: const InputDecoration(
                  labelText: 'Your Post',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                minLines: 5,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}