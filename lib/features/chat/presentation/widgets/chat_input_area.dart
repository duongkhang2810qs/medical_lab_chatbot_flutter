import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  const ChatInputArea({
    required this.controller,
    required this.isLoading,
    required this.showImageActions,
    required this.onSend,
    required this.onPickImage,
    required this.onScanDocument,
    super.key,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool showImageActions;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onScanDocument;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            if (showImageActions) ...<Widget>[
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: isLoading ? Colors.grey : primary,
                  size: 28,
                ),
                onPressed: isLoading ? null : onPickImage,
                tooltip: 'Tải ảnh từ thư viện',
              ),
              IconButton(
                icon: Icon(
                  Icons.document_scanner,
                  color: isLoading ? Colors.grey : primary,
                  size: 28,
                ),
                onPressed: isLoading ? null : onScanDocument,
                tooltip: 'Quét phiếu xét nghiệm',
              ),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: isLoading ? 'Đang xử lý...' : 'Nhập câu hỏi...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: isLoading ? Colors.grey[300] : Colors.grey[200],
                ),
                onSubmitted: isLoading ? null : (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: isLoading ? Colors.grey : primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: isLoading ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
