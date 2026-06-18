class OcrItem {
  OcrItem({
    required this.testName,
    required this.value,
    required this.unit,
    this.refMin,
    this.refMax,
    this.status,
  });

  factory OcrItem.fromJson(Map<String, dynamic> json) {
    final refRange = json['ref_range'];
    final refRangeMap = refRange is Map<String, dynamic> ? refRange : null;

    final item = OcrItem(
      testName: json['test_name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      refMin: _toDouble(refRangeMap?['ref_min']),
      refMax: _toDouble(refRangeMap?['ref_max']),
      status: json['status']?.toString(),
    );

    item.recalculateStatus();
    return item;
  }

  String testName;
  String value;
  String unit;
  double? refMin;
  double? refMax;
  String? status;

  OcrItem copy() => OcrItem(
        testName: testName,
        value: value,
        unit: unit,
        refMin: refMin,
        refMax: refMax,
        status: status,
      );

  void recalculateStatus() {
    final numericValue = double.tryParse(value.replaceAll(',', '.'));

    if (numericValue == null) {
      status = null;
      return;
    }

    if (refMin != null && numericValue < refMin!) {
      status = 'Low';
    } else if (refMax != null && numericValue > refMax!) {
      status = 'High';
    } else if (refMin != null || refMax != null) {
      status = 'Normal';
    } else {
      status = null;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'test_name': testName,
        'value': value,
        'unit': unit,
        'ref_range': <String, dynamic>{
          'ref_min': refMin,
          'ref_max': refMax,
        },
        'status': status,
      };

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
