import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String mobile;
  
  const ChatScreen({Key? key, required this.mobile}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Predefined AI responses
  final Map<String, String> _aiResponses = {
    'hello': 'Hello! How can I help you today?',
    'hi': 'Hi there! What can I do for you?',
    'how are you': 'I\'m doing great! Thanks for asking. How are you?',
    'what is your name': 'I\'m your AI assistant. You can call me Assistant!',
    'help': 'I\'m here to help! You can ask me questions and I\'ll do my best to assist you.',
    'weather': 'I don\'t have real-time weather data, but I hope it\'s nice where you are!',
    'time': 'I don\'t have access to real-time data, but you can check the time on your device.',
    'joke': 'Why don\'t scientists trust atoms? Because they make up everything!',
    'thank you': 'You\'re welcome! I\'m glad I could help.',
    'thanks': 'You\'re welcome! Feel free to ask if you need anything else.',
    'bye': 'Goodbye! Have a great day!',
    'default': 'I understand you\'re asking about that. While I don\'t have specific information on this topic, I\'m here to help with any questions you might have!'
  };

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Load previous chat history from backend
  Future<void> _loadChatHistory() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/chat-history/${widget.mobile}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _messages = (data['messages'] as List)
                .map((msg) => ChatMessage.fromJson(msg))
                .toList();
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  // Send message and get AI response
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI thinking delay
    await Future.delayed(Duration(milliseconds: 500));

    // Get AI response
    String aiResponse = _getAIResponse(text);
    
    final aiMessage = ChatMessage(
      text: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(aiMessage);
      _isTyping = false;
    });

    _scrollToBottom();

    // Save both messages to database
    await _saveChatToDatabase(userMessage, aiMessage);
  }

  // Get AI response based on user input
  String _getAIResponse(String userInput) {
    String input = userInput.toLowerCase().trim();
    
    // Check for exact matches first
    if (_aiResponses.containsKey(input)) {
      return _aiResponses[input]!;
    }
    
    // Check for partial matches
    for (String key in _aiResponses.keys) {
      if (input.contains(key)) {
        return _aiResponses[key]!;
      }
    }
    
    // Return default response if no match found
    return _aiResponses['default']!;
  }

  // Save chat messages to database
  Future<void> _saveChatToDatabase(ChatMessage userMessage, ChatMessage aiMessage) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/save-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': widget.mobile,
          'userMessage': userMessage.toJson(),
          'aiMessage': aiMessage.toJson(),
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to save chat to database');
      }
    } catch (e) {
      print('Error saving chat: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AI is typing'),
            SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}