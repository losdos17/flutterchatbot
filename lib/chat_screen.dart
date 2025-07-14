import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, String>> messages = [];
  TextEditingController controller = TextEditingController();

  Future<void> sendMessage(String text) async {
    setState(() {
      messages.add({'sender': 'user', 'text': text});
    });
    controller.clear();

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        messages.add({'sender': 'bot', 'text': data['response'] ?? ''});
      });
    } else {
      setState(() {
        messages.add({'sender': 'bot', 'text': 'Hata oluştu.'});
      });
    }
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg['sender'] == 'user';
    final avatar = CircleAvatar(
      radius: 22,
      backgroundImage: AssetImage(isUser ? 'assets/user.png' : 'assets/bot.png'),
      backgroundColor: Colors.grey[400],
    );
    final bubble = Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      decoration: BoxDecoration(
        color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(isUser ? 22 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        msg['text'] ?? '',
        style: TextStyle(
          color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isUser
            ? [bubble, SizedBox(width: 8), avatar]
            : [avatar, SizedBox(width: 8), bubble],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sohbet')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        sendMessage(controller.text.trim());
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 