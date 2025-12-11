import 'package:baddel/models/conversation_model.dart';
import 'package:flutter/material.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const ConversationTile({Key? key, required this.conversation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(conversation.userImageUrl),
        radius: 28,
      ),
      title: Text(
        conversation.userName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        conversation.timestamp,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      onTap: () {
        // TODO: Navigate to the individual chat screen
      },
    );
  }
}
