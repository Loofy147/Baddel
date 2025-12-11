import 'package:flutter/material.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // To get current user ID

class ChatScreen extends StatefulWidget {
  final String offerId; // The "Room" ID
  final String otherUserName; // For Header

  const ChatScreen({super.key, required this.offerId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _service = SupabaseService();
  final _myId = Supabase.instance.client.auth.currentUser?.id;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    _service.sendMessage(widget.offerId, _controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Chat: ${widget.otherUserName}"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Color(0xFF00E676)),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📍 Share Location Feature coming soon!")));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // MESSAGE LIST
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getChatStream(widget.offerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _myId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF2962FF) : Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(msg['content'], style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT BAR
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2962FF)),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
