import 'package:baddel/models/conversation_model.dart';
import 'package:baddel/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Conversation> conversations = [
    Conversation(
      id: '1',
      userName: 'Amine',
      lastMessage: 'Is the PS5 still available?',
      userImageUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
      timestamp: '10:42 AM',
    ),
    Conversation(
      id: '2',
      userName: 'Fatima',
      lastMessage: 'Okay, I can do 140,000 DA for the iPhone.',
      userImageUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026705d',
      timestamp: 'Yesterday',
    ),
    Conversation(
      id: '3',
      userName: 'Karim',
      lastMessage: 'It\'s a match! Let\'s discuss the swap.',
      userImageUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026706d',
      timestamp: '2 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches & Chats'),
      ),
      body: ListView.separated(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return ConversationTile(conversation: conversations[index]);
        },
        separatorBuilder: (context, index) => const Divider(height: 0),
      ),
    );
  }
}
