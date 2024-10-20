import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/api_constant.dart'; // Import the ApiConstants

class GroupMessageScreen extends StatefulWidget {
  final String userId;
  final String groupChatId;

  GroupMessageScreen({required this.userId, required this.groupChatId});

  @override
  _GroupMessageScreenState createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  List<Map<String, dynamic>> _messages = [];
  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMessages(); // Fetch messages on initialization
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/group/message/${widget.groupChatId}'), // Your API endpoint
      );

      if (response.statusCode == 200) {
        final List<dynamic> messages = jsonDecode(response.body);
        setState(() {
          _messages = messages.cast<Map<String, dynamic>>(); // Cast messages to List<Map<String, dynamic>>
        });
      } else {
        _handleError('Failed to load messages: ${response.body}');
      }
    } catch (error) {
      _handleError('Failed to load messages: ${error.toString()}');
    }
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/group/message'), // Your API endpoint
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'groupId': widget.groupChatId,
            'senderId': widget.userId,
            'content': _messageController.text,
          }),
        );

        if (response.statusCode == 201) {
          _messageController.clear(); // Clear input after sending
          _fetchMessages(); // Refresh messages
        } else {
          _handleError('Failed to send message: ${response.body}');
        }
      } catch (error) {
        _handleError('Failed to send message: ${error.toString()}');
      }
    }
  }

  String _formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal(); // Convert to local time
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime); // Format the date and time as needed
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Group Messages'),
      backgroundColor: Colors.blueAccent,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
             itemBuilder: (context, index) {
  final message = _messages[index];
  final isMe = message['senderId']['_id'] == widget.userId; // Access the _id property

  // Debugging output
  print('Message senderId: ${message['senderId']}, Current userId: ${widget.userId}');

  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Show sender's name if the sender is not the current user
          if (!isMe) ...[
            Text(
              '${message['senderId']['firstName']} ${message['senderId']['lastName']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.0, // Smaller font size for the name
              ),
            ),
            SizedBox(height: 4.0), // Space between sender's name and message card
          ],
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message['content'] ?? 'No content',
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
                SizedBox(height: 4.0), // Space between message and timestamp
                Text(
                  _formatTimestamp(message['createdAt'] ?? message['timestamp']),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
},


            ),
          ),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Type a message',
              suffixIcon: IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
