// lib/ui/screens/chat/premium_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class PremiumChatScreen extends StatefulWidget {
  final String offerId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const PremiumChatScreen({
    super.key,
    required this.offerId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<PremiumChatScreen> createState() => _PremiumChatScreenState();
}

class _PremiumChatScreenState extends State<PremiumChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  List<ChatMessage> _messages = [];
  bool _otherUserTyping = false;
  Timer? _typingTimer;
  Timer? _typingDebounce;
  String? _lastTypingNotification;

  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMessages();
    _listenToMessages();
    _listenToTypingStatus();

    _messageController.addListener(_onTextChanged);
  }

  void _setupAnimations() {
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _sendButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    _typingTimer?.cancel();
    _typingDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*, sender:users!sender_id(id, phone)')
          .eq('offer_id', widget.offerId)
          .order('created_at', ascending: true);

      setState(() {
        _messages = (response as List)
            .map((json) => ChatMessage.fromJson(json))
            .toList();
      });

      _scrollToBottom();
      _markMessagesAsRead();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _listenToMessages() {
    _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('offer_id', widget.offerId)
        .order('created_at', ascending: true)
        .listen((data) {
          setState(() {
            _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
          });

          _scrollToBottom(animate: true);
          _markMessagesAsRead();
        });
  }

  void _listenToTypingStatus() {
    // In production, use Supabase Realtime Presence or a dedicated typing table
    // For now, simulate with polling
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final status = await _supabase
            .from('typing_status')
            .select('is_typing, updated_at')
            .eq('offer_id', widget.offerId)
            .eq('user_id', widget.otherUserId)
            .maybeSingle();

        if (status != null) {
          final lastUpdate = DateTime.parse(status['updated_at']);
          final isRecent = DateTime.now().difference(lastUpdate).inSeconds < 5;

          setState(() {
            _otherUserTyping = status['is_typing'] && isRecent;
          });
        }
      } catch (e) {
        // Silent fail
      }
    });
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText) {
      _sendButtonController.forward();
      _notifyTyping(true);
    } else {
      _sendButtonController.reverse();
      _notifyTyping(false);
    }

    // Debounce typing notifications
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 500), () {
      _notifyTyping(hasText);
    });
  }

  Future<void> _notifyTyping(bool isTyping) async {
    try {
      final now = DateTime.now().toIso8601String();
      if (_lastTypingNotification == now) return; // Prevent spam

      _lastTypingNotification = now;

      await _supabase
          .from('typing_status')
          .upsert({
            'offer_id': widget.offerId,
            'user_id': _supabase.auth.currentUser!.id,
            'is_typing': isTyping,
            'updated_at': now,
          });

      // Auto-clear after 3 seconds
      if (isTyping) {
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          _notifyTyping(false);
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _notifyTyping(false);

    try {
      // Optimistic UI update
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _supabase.auth.currentUser!.id,
        content: content,
        createdAt: DateTime.now(),
        isRead: false,
        isSent: false,
      );

      setState(() {
        _messages.add(tempMessage);
      });

      _scrollToBottom(animate: true);

      // Send to server
      await _supabase.from('messages').insert({
        'offer_id': widget.offerId,
        'sender_id': _supabase.auth.currentUser!.id,
        'content': content,
      });

      // Update sent status
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = tempMessage.copyWith(isSent: true);
        }
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final unreadMessages = _messages
          .where((m) =>
            m.senderId != _supabase.auth.currentUser!.id &&
            !m.isRead
          )
          .map((m) => m.id)
          .toList();

      if (unreadMessages.isNotEmpty) {
        await _supabase
            .from('messages')
            .update({'is_read': true})
            .in_('id', unreadMessages);
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _scrollToBottom({bool animate = false}) {
    if (!_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_otherUserTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.otherUserId}',
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2962FF),
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(
                      widget.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _otherUserTyping ? 'typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: _otherUserTyping
                        ? const Color(0xFF00E676)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 16),
            Text(
              'Start the conversation!',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _supabase.auth.currentUser!.id;
        final showDate = _shouldShowDate(index);

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.createdAt),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;

    final current = _messages[index].createdAt;
    final previous = _messages[index - 1].createdAt;

    return current.day != previous.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String label;
    if (date.day == now.day) {
      label = 'Today';
    } else if (date.day == yesterday.day) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[800])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2962FF).withOpacity(0.2),
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2962FF) : Colors.grey[900],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : message.isSent
                                  ? Icons.done
                                  : Icons.access_time,
                          size: 14,
                          color: message.isRead
                              ? const Color(0xFF00E676)
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF2962FF).withOpacity(0.2),
            child: Text(
              widget.otherUserName[0].toUpperCase(),
              style: const TextStyle(fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.15;
        final animValue = (value - delay).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, -4 * (animValue < 0.5 ? animValue * 2 : (1 - animValue) * 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ScaleTransition(
            scale: _sendButtonAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2962FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2962FF).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF00E676)),
              title: const Text('Share Location', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement location sharing
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Block User', style: TextStyle(color: Colors.white)),
              onTap: () {
                // TODO: Implement blocking
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('Report User', style: TextStyle(color: Colors.white)),
              onTap: () {
                // TODO: Implement reporting
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Data Models
class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final bool isSent;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.isSent = true,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      isSent: true,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    bool? isSent,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
    );
  }
}

// SQL for typing status table
/*
CREATE TABLE IF NOT EXISTS typing_status (
  offer_id UUID REFERENCES offers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT false,
  updated_at TIMESTPTZ DEFAULT NOW(),
  PRIMARY KEY (offer_id, user_id)
);
*/
