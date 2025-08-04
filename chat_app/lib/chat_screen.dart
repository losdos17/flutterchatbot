import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedIndex = 0; // 0: Sohbet, 1: Admin Paneli
  List<Map<String, String>> messages = [];
  TextEditingController controller = TextEditingController();

  // Sohbet geçmişi
  List<List<Map<String, String>>> chatHistory = [];
  int? _activeHistoryIndex; // null: aktif sohbet, 0+: geçmiş sohbet

  // Admin Paneli için değişkenler
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadResult;

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

  // Yeni sohbet başlatma
  void _startNewChat() {
    setState(() {
      // Sadece aktif sohbetteyken ve mesajlar boş değilse geçmişe ekle
      if (_activeHistoryIndex == null && messages.isNotEmpty) {
        chatHistory.insert(0, List<Map<String, String>>.from(messages));
      }
      messages.clear();
      controller.clear();
      _activeHistoryIndex = null;
    });
    Navigator.pop(context); // Drawer'ı kapat
  }

  // Geçmiş sohbeti yükle
  void _loadHistoryChat(int index) {
    setState(() {
      messages = List<Map<String, String>>.from(chatHistory[index]);
      _activeHistoryIndex = index;
    });
    Navigator.pop(context);
  }

  // Geçmiş sohbeti sil
  void _deleteHistoryChat(int index) {
    setState(() {
      chatHistory.removeAt(index);
      // Eğer silinen sohbet aktifse, aktif sohbeti temizle
      if (_activeHistoryIndex == index) {
        messages.clear();
        controller.clear();
        _activeHistoryIndex = null;
      } else if (_activeHistoryIndex != null && _activeHistoryIndex! > index) {
        // Silinen sohbet aktif sohbetten önceyse, aktif sohbet indeksini güncelle
        _activeHistoryIndex = _activeHistoryIndex! - 1;
      }
    });
  }

  // Excel dosyası seçme (mobil ve web için farklı olabilir)
  Future<void> _pickExcelFile() async {
    final typeGroup = XTypeGroup(
      label: 'excel',
      extensions: ['xlsx', 'xls'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
      });
    }
  }

  Future<void> _uploadExcelFile() async {
    if (_selectedFile == null) return;
    setState(() {
      _isUploading = true;
      _uploadResult = null;
    });
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:8000/upload_excel'));
      request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        setState(() {
          _uploadResult = 'Yükleme başarılı: $respStr';
        });
      } else {
        setState(() {
          _uploadResult = 'Yükleme başarısız (Kod: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _uploadResult = 'Yükleme hatası: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg['sender'] == 'user';
    final avatar = CircleAvatar(
      radius: 22,
      backgroundColor: isUser ? Colors.blue : Colors.grey[700],
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 26,
      ),
    );
    final bubble = Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFFE0E3FF) // Açık morumsu-gri ton (kullanıcı mesajı)
            : Theme.of(context).colorScheme.surfaceVariant,
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
          color: isUser ? Colors.black87 : Theme.of(context).colorScheme.onSurface,
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
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Sohbet' : 'Admin Paneli'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text('Menü', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Sohbet'),
              selected: _selectedIndex == 0 && _activeHistoryIndex == null,
              onTap: () {
                setState(() {
                  // Her zaman yeni boş sohbet başlat
                  if (_activeHistoryIndex == null && messages.isNotEmpty) {
                    chatHistory.insert(0, List<Map<String, String>>.from(messages));
                  }
                  messages.clear();
                  controller.clear();
                  _selectedIndex = 0;
                  _activeHistoryIndex = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Yeni Sohbet'),
              onTap: _startNewChat,
            ),
            if (chatHistory.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Geçmiş Sohbetler', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...List.generate(chatHistory.length, (i) => ListTile(
                leading: Icon(Icons.history),
                title: Text('Sohbet ${chatHistory.length - i}'),
                selected: _activeHistoryIndex == i,
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteHistoryChat(i),
                ),
                onTap: () => _loadHistoryChat(i),
              )),
              Divider(),
            ],
            ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text('Admin Paneli'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0 ? _buildChatBody(context) : _buildAdminPanel(context),
    );
  }

  Widget _buildChatBody(BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildAdminPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Excel Dosyası Yükle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.attach_file),
            label: Text(_selectedFile == null ? 'Dosya Seç' : 'Dosya Seçildi'),
            onPressed: _isUploading ? null : _pickExcelFile,
          ),
          if (_selectedFile != null) ...[
            SizedBox(height: 12),
            Text(_selectedFile!.path.split('/').last),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.upload_file),
              label: Text('Yükle'),
              onPressed: _isUploading ? null : _uploadExcelFile,
            ),
          ],
          if (_isUploading) ...[
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Yükleniyor...'),
          ],
          if (_uploadResult != null) ...[
            SizedBox(height: 24),
            Text(_uploadResult!, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
} 