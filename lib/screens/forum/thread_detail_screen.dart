import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'edit_thread_screen.dart'; // <-- NEW IMPORT

// (OriginalPost and Reply models remain the same)
class OriginalPost {
  final String id; // <-- NEW: Added ID
  final String content;
  final String authorName;
  final String authorId; // <-- NEW: Added authorId
  final Timestamp timestamp;

  OriginalPost({
    required this.id, // <-- NEW
    required this.content,
    required this.authorName,
    required this.authorId, // <-- NEW
    required this.timestamp,
  });

  factory OriginalPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OriginalPost(
      id: doc.id, // <-- NEW
      content: data['content'] ?? '...',
      authorName: data['authorName'] ?? 'Unknown',
      authorId: data['authorId'] ?? '', // <-- NEW
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class Reply {
  final String id; // <-- NEW: Added ID
  final String content;
  final String authorName;
  final String authorId; // <-- NEW: Added authorId
  final Timestamp timestamp;

  Reply({
    required this.id, // <-- NEW
    required this.content,
    required this.authorName,
    required this.authorId, // <-- NEW
    required this.timestamp,
  });

  factory Reply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reply(
      id: doc.id, // <-- NEW
      content: data['content'] ?? '...',
      authorName: data['authorName'] ?? 'Unknown',
      authorId: data['authorId'] ?? '', // <-- NEW
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class ThreadDetailScreen extends StatefulWidget {
  final String threadId;
  final String threadTitle;
  final String authorId; // <-- NEW: Added authorId

  const ThreadDetailScreen({
    super.key,
    required this.threadId,
    required this.threadTitle,
    required this.authorId, // <-- NEW
  });

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isPosting = false;

  // NEW: Store the loaded post and its category
  OriginalPost? _originalPost;
  String? _threadCategory;

  // This fetches the *first* post in the 'replies' sub-collection
  Future<void> _fetchOriginalPost() async {
    // 1. Get the original post
    final snapshot = await FirebaseFirestore.instance
        .collection('forumThreads')
        .doc(widget.threadId)
        .collection('replies')
        .orderBy('timestamp', descending: false)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _originalPost = OriginalPost.fromFirestore(snapshot.docs.first);
    }

    // 2. Get the thread category
    final threadDoc = await FirebaseFirestore.instance
        .collection('forumThreads')
        .doc(widget.threadId)
        .get();
    if (threadDoc.exists) {
      _threadCategory = threadDoc.data()?['category'] ?? 'General';
    }
  }

  // --- NEW: Function to post a reply ---
  Future<void> _postReply() async {
    // (This function is the same as before)
    final content = _replyController.text.trim();
    if (content.isEmpty || currentUser == null) return;
    setState(() { _isPosting = true; });
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final authorName = userDoc.data()?['fullName'] ?? 'Anonymous';
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final threadRef = FirebaseFirestore.instance
            .collection('forumThreads')
            .doc(widget.threadId);
        final newReplyRef = threadRef.collection('replies').doc();
        transaction.set(newReplyRef, {
          'content': content,
          'authorName': authorName,
          'authorId': currentUser!.uid,
          'timestamp': Timestamp.now(),
        });
        transaction.update(threadRef, {
          'replyCount': FieldValue.increment(1),
          'lastActivity': Timestamp.now(),
          'lastActivityBy': authorName,
        });
      });
      _replyController.clear();
    } catch (e) {
      _showError('Error posting reply: $e');
    }
    setState(() { _isPosting = false; });
  }

  // --- NEW: Delete Thread Function (Soft Delete) ---
  Future<void> _onDeleteThread() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Thread'),
        content: const Text('Are you sure? This will hide the thread from the forum. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // We do a "soft delete" by setting a flag
        // This allows us to keep the replies in the database
        await FirebaseFirestore.instance
            .collection('forumThreads')
            .doc(widget.threadId)
            .update({'isDeleted': true}); // <-- SOFT DELETE

        if (mounted) Navigator.of(context).pop(); // Go back
      } catch (e) {
        _showError('Error deleting thread: $e');
      }
    }
  }

  // --- NEW: Edit Thread Function ---
  void _onEditThread() {
    if (_originalPost == null || _threadCategory == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditThreadScreen(
          threadId: widget.threadId,
          originalTitle: widget.threadTitle,
          originalCategory: _threadCategory!,
        ),
      ),
    );
  }

  // --- NEW: Error Helper ---
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.threadTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        elevation: 1,
        // --- NEW: Three-dot menu ---
        actions: [
          _buildMoreMenu(context),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.threadTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildOriginalPostCard(),
                  const Divider(height: 40, thickness: 1),
                  const Text('Replies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildRepliesList(),
                ],
              ),
            ),
          ),
          _buildReplyInputBar(),
        ],
      ),
    );
  }

  // --- NEW: Builds the menu button ---
  Widget _buildMoreMenu(BuildContext context) {
    // Check if the current user is the author of the thread
    if (currentUser?.uid == widget.authorId) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'edit') {
            _onEditThread();
          } else if (value == 'delete') {
            _onDeleteThread();
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.black54),
                SizedBox(width: 10),
                Text('Edit Thread'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 10),
                Text('Delete Thread', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );
    }
    // If not the author, show nothing
    return const SizedBox.shrink();
  }

  // This widget fetches and displays the original post
  Widget _buildOriginalPostCard() {
    return FutureBuilder(
      future: _fetchOriginalPost(), // This now loads the post into state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _originalPost == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_originalPost == null) {
          return const Text('Could not load original post.');
        }

        return _buildPostCard(
          authorName: _originalPost!.authorName,
          timestamp: _originalPost!.timestamp,
          content: _originalPost!.content,
          isOriginalPost: true,
        );
      },
    );
  }

  // This widget builds the list of replies
  Widget _buildRepliesList() {
    final repliesStream = FirebaseFirestore.instance
        .collection('forumThreads')
        .doc(widget.threadId)
        .collection('replies')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: repliesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading replies.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.length <= 1) { // <= 1 hides the OP
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No replies yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          );
        }

        final replies = snapshot.data!.docs.skip(1).toList(); // Skip the OP
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final reply = Reply.fromFirestore(replies[index]);
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildPostCard(
                authorName: reply.authorName,
                timestamp: reply.timestamp,
                content: reply.content,
              ),
            );
          },
        );
      },
    );
  }

  // Reusable card for both OP and replies
  Widget _buildPostCard({
    required String authorName,
    required Timestamp timestamp,
    required String content,
    bool isOriginalPost = false,
  }) {
    return Card(
      elevation: isOriginalPost ? 2 : 0, // Make replies blend more
      color: isOriginalPost ? Colors.white : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.teal)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(DateFormat.yMMMd().add_jm().format(timestamp.toDate()), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // The reply input bar
  Widget _buildReplyInputBar() {
    return Container(
      padding: EdgeInsets.only(
        top: 12.0,
        left: 12.0,
        right: 12.0,
        bottom: MediaQuery.of(context).padding.bottom + 12.0, // Safe area
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: 'Add a reply...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.all(16.0)),
            icon: _isPosting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Icon(Icons.send, color: Colors.white),
            onPressed: _isPosting ? null : _postReply,
          ),
        ],
      ),
    );
  }
}