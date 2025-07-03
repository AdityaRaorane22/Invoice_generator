import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String mobile;
  
  const ChatScreen({Key? key, required this.mobile}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  // Predefined AI responses with more personality
  final Map<String, String> _aiResponses = {
    'hello': '👋 Hello! How can I help you today?',
    'hi': '🙋‍♂️ Hi there! What can I do for you?',
    'how are you': '😊 I\'m doing great! Thanks for asking. How are you?',
    'what is your name': '🤖 I\'m your AI assistant. You can call me SmartBot!',
    'help': '🆘 I\'m here to help! You can ask me questions and I\'ll do my best to assist you.',
    'weather': '🌤️ I don\'t have real-time weather data, but I hope it\'s nice where you are!',
    'time': '⏰ I don\'t have access to real-time data, but you can check the time on your device.',
    'joke': '😂 Why don\'t scientists trust atoms? Because they make up everything!',
    'thank you': '🙏 You\'re welcome! I\'m glad I could help.',
    'thanks': '😊 You\'re welcome! Feel free to ask if you need anything else.',
    'bye': '👋 Goodbye! Have a great day!',
    'good morning': '🌅 Good morning! Hope you have a wonderful day ahead!',
    'good evening': '🌆 Good evening! How has your day been?',
    'good night': '🌙 Good night! Sweet dreams!',
    'how to': '💡 That\'s a great question! I\'d love to help you learn something new.',
    'price': '💰 For pricing information, please check with our sales team or visit our website.',
    'invoice': '📄 I can help you with invoice-related queries! What do you need to know?',
    'product': '📦 Tell me more about which product you\'re interested in!',
    'default': '🤔 I understand you\'re asking about that. While I don\'t have specific information on this topic, I\'m here to help with any questions you might have!'
  };

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: Curves.easeInOut),
    );
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
    _typingAnimationController.repeat();

    // Simulate AI thinking delay
    await Future.delayed(Duration(milliseconds: 1000 + (text.length * 50)));

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

    _typingAnimationController.stop();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),
              
              // Chat Messages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Chat Header
                      _buildChatHeader(),
                      
                      // Messages List
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isTyping) {
                              return _buildTypingIndicator();
                            }
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                      ),
                      
                      // Message Input
                      _buildMessageInput(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartBot AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Always here to help',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Clear Chat'),
                  content: Text('Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _messages.clear());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Color(0xFF3b82f6),
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Chat Assistant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e3c72),
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF10b981),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFF10b981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: message.isUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFF3b82f6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: Color(0xFF3b82f6),
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
            ],
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [Color(0xFF3b82f6), Color(0xFF2563eb)],
                      )
                    : null,
                color: message.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Color(0xFF1e3c72),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (message.isUser) ...[
              SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10b981), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF3b82f6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: Color(0xFF3b82f6),
                size: 18,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SmartBot is typing',
                    style: TextStyle(
                      color: Color(0xFF1e3c72),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _typingAnimation,
                    builder: (context, child) {
                      return Row(
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color(0xFF3b82f6).withOpacity(
                                ((_typingAnimation.value + index * 0.3) % 1.0),
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  prefixIcon: Icon(
                    Icons.message_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
                onSubmitted: _sendMessage,
                textInputAction: TextInputAction.send,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3b82f6), Color(0xFF2563eb)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3b82f6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _sendMessage(_messageController.text),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
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
    _typingAnimationController.dispose();
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