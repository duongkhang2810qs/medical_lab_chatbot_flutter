import 'package:flutter/material.dart';

import '../../../../core/utils/status_color.dart';
import '../../../ocr/domain/models/ocr_item.dart';

class ConfirmedDataDrawer extends StatelessWidget {
  const ConfirmedDataDrawer({
    required this.items,
    super.key,
  });

  final List<OcrItem> items;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
            color: Theme.of(context).colorScheme.primary,
            child: const Text(
              'Bảng Dữ Liệu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Chưa có dữ liệu nào được gửi.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.testName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        trailing: Text(
                          '${item.value} ${item.unit}',
                          style: TextStyle(
                            color: getStatusColor(item.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'Tham chiếu: ${item.refMin ?? ''} - ${item.refMax ?? ''}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
