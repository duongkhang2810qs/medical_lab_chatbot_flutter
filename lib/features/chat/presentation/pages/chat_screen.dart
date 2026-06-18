import 'package:flutter/material.dart';

import '../../../ocr/data/services/document_image_service.dart';
import '../../../ocr/domain/models/ocr_item.dart';
import '../../../ocr/presentation/pages/ocr_review_screen.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/confirmed_data_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DocumentImageService _documentImageService = DocumentImageService();
  late final ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController()..addListener(_handleControllerUpdate);
  }

  @override
  void dispose() {
    _chatController
      ..removeListener(_handleControllerUpdate)
      ..dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleControllerUpdate() => _scrollToBottom();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _chatController.isLoading) return;
    _textController.clear();
    await _chatController.sendMessage(text);
  }

  Future<void> _pickImage() async {
    try {
      final imagePath = await _documentImageService.pickFromGallery();
      if (imagePath != null) await _processImage(imagePath);
    } catch (_) {
      _showSnackBar('Lỗi mở thư viện ảnh!');
    }
  }

  Future<void> _scanDocument() async {
    try {
      final imagePath = await _documentImageService.scanDocument();
      if (imagePath != null) await _processImage(imagePath);
    } catch (_) {
      _showSnackBar('Lỗi mở máy quét hoặc bạn đã hủy quét!');
    }
  }

  Future<void> _processImage(String imagePath) async {
    final extractedItems = await _chatController.extractImage(imagePath);
    if (!mounted || extractedItems == null) return;

    final confirmedItems = await Navigator.of(context).push<List<OcrItem>>(
      MaterialPageRoute<List<OcrItem>>(
        builder: (_) => OcrReviewScreen(ocrData: extractedItems),
      ),
    );

    if (!mounted || confirmedItems == null) return;
    await _chatController.confirmAndAnalyze(confirmedItems);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _chatController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '📋 Trợ lý Xét nghiệm máu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Phân tích phiếu mới',
                onPressed: () {
                  _textController.clear();
                  _chatController.startNewConversation();
                },
              ),
              Builder(
                builder: (drawerContext) => IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'Xem chỉ số đã xác nhận',
                  onPressed: () => Scaffold.of(drawerContext).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: ConfirmedDataDrawer(items: _chatController.confirmedData),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatController.messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(
                      message: _chatController.messages[index],
                    );
                  },
                ),
              ),
              ChatInputArea(
                controller: _textController,
                isLoading: _chatController.isLoading,
                showImageActions: !_chatController.hasConfirmedImage,
                onSend: _sendMessage,
                onPickImage: _pickImage,
                onScanDocument: _scanDocument,
              ),
            ],
          ),
        );
      },
    );
  }
}
