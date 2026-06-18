import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../ocr/domain/models/ocr_item.dart';

class ChatApiService {
  ChatApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> sendMessage({
    required String text,
    required String sessionId,
  }) async {
    final data = await _postJson(
      endpoint: '${AppConfig.chatApiBase}/chat',
      body: <String, dynamic>{
        'text': text,
        'session_id': sessionId,
      },
    );

    return data['answer']?.toString() ?? 'Máy chủ không trả về nội dung.';
  }

  Future<String> analyze({
    required List<OcrItem> indicators,
    required String sessionId,
  }) async {
    final data = await _postJson(
      endpoint: '${AppConfig.chatApiBase}/analyze',
      body: <String, dynamic>{
        'indicators': indicators.map((item) => item.toJson()).toList(),
        'session_id': sessionId,
      },
    );

    return data['summary']?.toString() ?? 'Máy chủ không trả về kết quả phân tích.';
  }

  Future<Map<String, dynamic>> _postJson({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: const <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(body),
          )
          .timeout(AppConfig.chatTimeout);

      final decoded = _decodeResponse(response);
      if (decoded['status'] != 'success') {
        throw AppException(
          decoded['message']?.toString() ?? 'Máy chủ xử lý yêu cầu thất bại.',
        );
      }
      return decoded;
    } on TimeoutException catch (error) {
      throw AppException('AI phản hồi quá lâu. Vui lòng thử lại.', cause: error);
    } on SocketException catch (error) {
      throw AppException('Không thể kết nối tới máy chủ. Hãy kiểm tra IP và mạng.', cause: error);
    } on http.ClientException catch (error) {
      throw AppException('Kết nối tới máy chủ bị gián đoạn.', cause: error);
    } on FormatException catch (error) {
      throw AppException('Dữ liệu máy chủ trả về không hợp lệ.', cause: error);
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException('Máy chủ trả về mã lỗi HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response is not a JSON object.');
    }
    return decoded;
  }

  void dispose() => _client.close();
}
