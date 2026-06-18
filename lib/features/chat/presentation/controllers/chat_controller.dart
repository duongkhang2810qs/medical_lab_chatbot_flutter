import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../ocr/data/services/ocr_api_service.dart';
import '../../../ocr/domain/models/ocr_item.dart';
import '../../data/services/chat_api_service.dart';
import '../../domain/models/chat_message.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    ChatApiService? chatApiService,
    OcrApiService? ocrApiService,
    Uuid? uuid,
  })  : _chatApiService = chatApiService ?? ChatApiService(),
        _ocrApiService = ocrApiService ?? OcrApiService(),
        _uuid = uuid ?? const Uuid() {
    _sessionId = _uuid.v4();
  }

  static const String _welcomeMessage =
      'Xin chào! Tôi là Trợ lý phân tích xét nghiệm máu. '
      'Bạn có thể tải ảnh lên để trích xuất chỉ số, hoặc đặt câu hỏi trực tiếp cho tôi ở ô bên dưới nhé.';

  final ChatApiService _chatApiService;
  final OcrApiService _ocrApiService;
  final Uuid _uuid;

  late String _sessionId;
  bool _isLoading = false;
  bool _hasConfirmedImage = false;
  List<OcrItem> _confirmedData = <OcrItem>[];
  final List<ChatMessage> _messages = <ChatMessage>[
    const ChatMessage(text: _welcomeMessage, isUser: false),
  ];

  bool get isLoading => _isLoading;
  bool get hasConfirmedImage => _hasConfirmedImage;
  List<OcrItem> get confirmedData => List.unmodifiable(_confirmedData);
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isLoading) return;

    _beginRequest(
      userMessage: ChatMessage(text: text, isUser: true),
      typingText: 'Đang phân tích...',
    );

    try {
      final answer = await _chatApiService.sendMessage(
        text: text,
        sessionId: _sessionId,
      );
      _finishRequest(ChatMessage(text: answer, isUser: false));
    } on AppException catch (error) {
      _finishRequest(ChatMessage(text: '❌ ${error.message}', isUser: false));
    } catch (_) {
      _finishRequest(
        const ChatMessage(
          text: '❌ Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
          isUser: false,
        ),
      );
    }
  }

  Future<List<OcrItem>?> extractImage(String imagePath) async {
    if (_isLoading) return null;

    _beginRequest(
      userMessage: ChatMessage(
        text: 'Vui lòng phân tích ảnh này.',
        isUser: true,
        imagePath: imagePath,
      ),
      typingText: 'Đang trích xuất chỉ số...',
    );

    try {
      final items = await _ocrApiService.extract(imagePath);
      _finishRequest(
        const ChatMessage(
          text: '✅ Đã trích xuất xong. Hãy kiểm tra lại bảng dữ liệu.',
          isUser: false,
        ),
      );
      return items;
    } on AppException catch (error) {
      _finishRequest(ChatMessage(text: '❌ ${error.message}', isUser: false));
      return null;
    } catch (_) {
      _finishRequest(
        const ChatMessage(
          text: '❌ Đã xảy ra lỗi khi xử lý ảnh.',
          isUser: false,
        ),
      );
      return null;
    }
  }

  Future<void> confirmAndAnalyze(List<OcrItem> data) async {
    if (_isLoading) return;

    _confirmedData = data.map((item) => item.copy()).toList();
    _hasConfirmedImage = true;

    _beginRequest(
      userMessage: const ChatMessage(
        text: 'Đây là dữ liệu đã xác nhận. Hãy phân tích giúp tôi.',
        isUser: true,
      ),
      typingText: 'Đang phân tích y khoa...',
    );

    try {
      final summary = await _chatApiService.analyze(
        indicators: _confirmedData,
        sessionId: _sessionId,
      );
      _finishRequest(ChatMessage(text: summary, isUser: false));
    } on AppException catch (error) {
      _finishRequest(ChatMessage(text: '❌ ${error.message}', isUser: false));
    } catch (_) {
      _finishRequest(
        const ChatMessage(
          text: '❌ Đã xảy ra lỗi khi phân tích dữ liệu.',
          isUser: false,
        ),
      );
    }
  }

  void startNewConversation() {
    _sessionId = _uuid.v4();
    _isLoading = false;
    _hasConfirmedImage = false;
    _confirmedData = <OcrItem>[];
    _messages
      ..clear()
      ..add(
        const ChatMessage(
          text: 'Đã tạo phiên trò chuyện mới! Vui lòng tải lên phiếu xét nghiệm khác để tôi hỗ trợ nhé.',
          isUser: false,
        ),
      );
    notifyListeners();
  }

  void _beginRequest({
    required ChatMessage userMessage,
    required String typingText,
  }) {
    _isLoading = true;
    _messages
      ..add(userMessage)
      ..add(ChatMessage(text: typingText, isUser: false, isTyping: true));
    notifyListeners();
  }

  void _finishRequest(ChatMessage responseMessage) {
    _removeTypingMessage();
    _messages.add(responseMessage);
    _isLoading = false;
    notifyListeners();
  }

  void _removeTypingMessage() {
    final index = _messages.lastIndexWhere((message) => message.isTyping);
    if (index >= 0) _messages.removeAt(index);
  }

  @override
  void dispose() {
    _chatApiService.dispose();
    _ocrApiService.dispose();
    super.dispose();
  }
}
