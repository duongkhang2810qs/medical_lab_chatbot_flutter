import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/ocr_item.dart';
import '../../domain/ontology/medical_ontology.dart';
import '../widgets/ocr_item_card.dart';

class OcrReviewScreen extends StatefulWidget {
  const OcrReviewScreen({
    required this.ocrData,
    super.key,
  });

  final List<OcrItem> ocrData;

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  late final List<OcrItem> _data;

  @override
  void initState() {
    super.initState();
    _data = widget.ocrData.map((item) => item.copy()).toList();
  }

  void _addNewRow() {
    final defaultTest = MedicalOntology.testOptions.first;
    final defaultUnit = MedicalOntology.unitOntology[defaultTest]?.first ?? '';

    setState(() {
      _data.add(
        OcrItem(testName: defaultTest, value: '', unit: defaultUnit),
      );
    });
  }

  void _confirm() {
    _data.removeWhere(
      (item) => item.testName.trim().isEmpty && item.value.trim().isEmpty,
    );
    Navigator.of(context).pop<List<OcrItem>>(_data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kiểm tra Dữ liệu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addNewRow,
            tooltip: 'Thêm chỉ số',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _Legend(text: '🔴 Bất thường', color: AppColors.danger),
                _Legend(text: '🟢 Bình thường', color: AppColors.success),
                _Legend(text: '🟡 Trống/Lỗi', color: AppColors.warning),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _data.length,
              itemBuilder: (context, index) {
                final item = _data[index];
                return OcrItemCard(
                  key: ObjectKey(item),
                  item: item,
                  onDelete: () => setState(() => _data.remove(item)),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    'XÁC NHẬN & PHÂN TÍCH',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _confirm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}
