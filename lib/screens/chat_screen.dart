import 'package:baddel/models/conversation_model.dart';
import 'package:baddel/services/supabase_service.dart';
import 'package:baddel/widgets/conversation_tile.dart';
import 'package.flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SupabaseClient _client = locator<SupabaseService>().client;
  late Stream<List<Conversation>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    _conversationsStream = _getConversationsStream();
  }

  Stream<List<Conversation>> _getConversationsStream() {
    final userId = _client.auth.currentUser!.id;
    return _client
        .from('chat_participants')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((participantData) async {
          final chatIds = participantData.map((data) => data['chat_id']).toList();
          if (chatIds.isEmpty) {
            return <Conversation>[];
          }

          final conversationsData = await _client
              .from('chats')
              .select('id, chat_participants!inner(user_id, users(phone_number)), messages!inner(content, created_at)')
              .in_('id', chatIds)
              .order('created_at', referencedTable: 'messages', ascending: false);

          return conversationsData.map((chatData) {
            final otherParticipant = (chatData['chat_participants'] as List)
                .firstWhere((p) => p['user_id'] != userId);
            final lastMessage = (chatData['messages'] as List).isNotEmpty
                ? chatData['messages'][0]['content']
                : 'No messages yet.';
            final timestamp = (chatData['messages'] as List).isNotEmpty
                ? chatData['messages'][0]['created_at']
                : chatData['created_at'];

            return Conversation(
              id: chatData['id'],
              userName: otherParticipant['users']['phone_number'] ?? 'Unknown User',
              lastMessage: lastMessage,
              userImageUrl: 'https://i.pravatar.cc/150?u=${otherParticipant['user_id']}',
              timestamp: timestamp,
            );
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches & Chats'),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final conversations = snapshot.data!;
          if (conversations.isEmpty) {
            return const Center(child: Text('You have no matches yet.'));
          }
          return ListView.separated(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return ConversationTile(conversation: conversations[index]);
            },
            separatorBuilder: (context, index) => const Divider(height: 0),
          );
        },
      ),
    );
  }
}
