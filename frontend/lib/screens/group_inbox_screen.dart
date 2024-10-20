import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'group_message_screen.dart'; // Import your GroupMessageScreen
import '../utils/api_constant.dart'; // Import the ApiConstants

class GroupInboxScreen extends StatefulWidget {
  final String userId;

  GroupInboxScreen({required this.userId});

  @override
  _GroupInboxScreenState createState() => _GroupInboxScreenState();
}

class _GroupInboxScreenState extends State<GroupInboxScreen> {
  List<Map<String, dynamic>> _groupChats = [];
  List<String> _categorizedInterests = []; // To store user's interests

  @override
  void initState() {
    super.initState();
    _fetchGroupChats();
  }

  Future<void> _fetchGroupChats() async {
    try {
      // Fetch the user's categorized interests
      final userResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile/${widget.userId}'), // Update to your user API endpoint
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        _categorizedInterests = List<String>.from(userData['categorizedInterests']);
      } else {
        _handleError('Failed to load user data: ${userResponse.body}');
        return; // Exit if user data fetch fails
      }

      // Fetch group chats that match categorized interests
      if (_categorizedInterests.isNotEmpty) {
        final groupResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/group/chat/${widget.userId}'), // Your updated API endpoint to get group chats
        );

        if (groupResponse.statusCode == 200) {
          final List<dynamic> allGroupChats = jsonDecode(groupResponse.body);
          setState(() {
            // Filter group chats based on categorized interests
            _groupChats = allGroupChats
                .where((chat) => _categorizedInterests.contains(chat['title']))
                .cast<Map<String, dynamic>>()
                .toList();
          });
        } else {
          _handleError('Failed to load group chats: ${groupResponse.body}');
        }
      }
    } catch (error) {
      _handleError('Failed to load group chats: ${error.toString()}');
    }
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToGroupMessages(String groupChatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupMessageScreen(
          userId: widget.userId,
          groupChatId: groupChatId, // Pass the group chat ID
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Inbox'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _groupChats.isEmpty // Show a loading indicator or message if there are no group chats
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _groupChats.length,
                itemBuilder: (context, index) {
                  final groupChat = _groupChats[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        groupChat['title'], // Use the title based on categorized interests
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      onTap: () => _navigateToGroupMessages(groupChat['_id']), // Navigate with group chat ID
                    ),
                  );
                },
              ),
      ),
    );
  }
}
