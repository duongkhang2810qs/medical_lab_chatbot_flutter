import 'package:flutter/material.dart';

import '../../../../core/utils/status_color.dart';
import '../../domain/models/ocr_item.dart';
import '../../domain/ontology/medical_ontology.dart';

class OcrItemCard extends StatefulWidget {
  const OcrItemCard({
    required this.item,
    required this.onDelete,
    super.key,
  });

  final OcrItem item;
  final VoidCallback onDelete;

  @override
  State<OcrItemCard> createState() => _OcrItemCardState();
}

class _OcrItemCardState extends State<OcrItemCard>
    with AutomaticKeepAliveClientMixin<OcrItemCard> {
  late final TextEditingController _valueController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final List<DropdownMenuItem<String>> _testDropdownItems;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.item.value);
    _minController = TextEditingController(text: widget.item.refMin?.toString() ?? '');
    _maxController = TextEditingController(text: widget.item.refMax?.toString() ?? '');
    _testDropdownItems = MedicalOntology.testOptions
        .map(
          (value) => DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final allowedUnits = <String>[
      ...?MedicalOntology.unitOntology[widget.item.testName],
    ];
    if (allowedUnits.isEmpty) allowedUnits.add(widget.item.unit);
    if (widget.item.unit.isNotEmpty && !allowedUnits.contains(widget.item.unit)) {
      allowedUnits.insert(0, widget.item.unit);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: getStatusColor(widget.item.status),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: MedicalOntology.testOptions.contains(widget.item.testName)
                            ? widget.item.testName
                            : null,
                        hint: Text(
                          widget.item.testName.isEmpty
                              ? 'Chọn tên'
                              : widget.item.testName,
                        ),
                        items: _testDropdownItems,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            widget.item.testName = value;
                            final units = MedicalOntology.unitOntology[value];
                            if (units != null && units.isNotEmpty) {
                              widget.item.unit = units.first;
                            }
                            widget.item.recalculateStatus();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    style: TextStyle(
                      color: getStatusColor(widget.item.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Kết quả',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        widget.item.value = value;
                        widget.item.recalculateStatus();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: allowedUnits.contains(widget.item.unit)
                            ? widget.item.unit
                            : null,
                        items: allowedUnits
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value.isEmpty ? '(không đơn vị)' : value,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => widget.item.unit = value);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Text(
                  'Tham chiếu: ',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Min',
                      isDense: true,
                      border: UnderlineInputBorder(),
                      filled: false,
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        widget.item.refMin = _parseNumber(value);
                        widget.item.recalculateStatus();
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Max',
                      isDense: true,
                      border: UnderlineInputBorder(),
                      filled: false,
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        widget.item.refMax = _parseNumber(value);
                        widget.item.recalculateStatus();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', '.'));
  }
}
