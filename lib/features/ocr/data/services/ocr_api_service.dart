import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/ocr_item.dart';

class OcrApiService {
  OcrApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<OcrItem>> extract(String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.ocrApiBase}/extract'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      final streamedResponse = await _client
          .send(request)
          .timeout(AppConfig.ocrTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException('Máy chủ OCR trả về mã lỗi HTTP ${response.statusCode}.');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response is not a JSON object.');
      }

      if (decoded['status'] != 'success') {
        throw AppException(
          decoded['message']?.toString() ?? 'Không thể trích xuất dữ liệu từ ảnh.',
        );
      }

      final rawTable = decoded['ocr_table'];
      if (rawTable is! List) {
        throw const FormatException('ocr_table is not a list.');
      }

      return rawTable
          .whereType<Map>()
          .map((item) => OcrItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on TimeoutException catch (error) {
      throw AppException(
        'Gửi ảnh thất bại do hết thời gian chờ. Hãy kiểm tra mạng hoặc dung lượng ảnh.',
        cause: error,
      );
    } on SocketException catch (error) {
      throw AppException('Không thể kết nối tới máy chủ OCR.', cause: error);
    } on http.ClientException catch (error) {
      throw AppException('Kết nối OCR bị gián đoạn.', cause: error);
    } on FormatException catch (error) {
      throw AppException('Dữ liệu OCR trả về không hợp lệ.', cause: error);
    }
  }

  void dispose() => _client.close();
}
