import 'package:flutter/material.dart';
import 'thread_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medigen/models/forum_thread_model.dart'; // Import your new model
import 'package:timeago/timeago.dart' as timeago; // We'll add this package
import 'create_thread_screen.dart';

class ForumScreen extends StatelessWidget {
  const ForumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a Stream that listens to the 'forumThreads' collection,
    // ordered by the most recent activity
    final Stream<QuerySnapshot> _threadsStream = FirebaseFirestore.instance
        .collection('forumThreads')
        .where('isDeleted', isEqualTo: false) // <-- ADD THIS LINE
        .orderBy('lastActivity', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Community Forum'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- Header ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Forum',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Join the conversation. Share, learn, and connect.',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateThreadScreen(),
                      ),
                    );
                    // TODO: Open a 'Create New Thread' dialog or screen
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Start New Discussion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Table Header ---
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOPIC',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'LAST ACTIVITY',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // --- Forum List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _threadsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                // 1. Handle Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Handle Error State
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // 3. Handle No Data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No discussions found.'));
                }

                // 4. If we have data, build the list
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    ForumThread thread = ForumThread.fromFirestore(document);
                    return _ForumThreadCard(thread: thread);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// This is the custom widget for each thread in the list,
// styled to match your 'Forum.png' design
class _ForumThreadCard extends StatelessWidget {
  final ForumThread thread;

  const _ForumThreadCard({required this.thread});

  // Helper to get a color based on category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'mental health':
        return Colors.blue;
      case 'nutrition':
        return Colors.green;
      case 'fitness':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThreadDetailScreen(
                threadId: thread.id,
                threadTitle: thread.title,
                authorId: thread.authorId, // <-- ADD THIS
              ),
            ),
          );
          // TODO: Navigate to thread detail page
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Side: Topic Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12.0),
// ... inside _ForumThreadCard
                    Wrap(
                      spacing: 12.0, // Horizontal space between items
                      runSpacing: 8.0, // Vertical space if it wraps to a new line
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(thread.category)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            thread.category,
                            style: TextStyle(
                              color: _getCategoryColor(thread.category),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Author
                        Text(
                          'by ${thread.authorName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // ...
                  ],
                ),
              ),

              const SizedBox(width: 16.0),

              // Right Side: Activity Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${thread.replyCount} replies',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'by ${thread.lastActivityBy}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    // Convert timestamp to a "time ago" format
                    timeago.format(thread.lastActivity.toDate()),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}