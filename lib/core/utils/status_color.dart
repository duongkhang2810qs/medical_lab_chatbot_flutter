import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

Color getStatusColor(String? status) {
  switch (status) {
    case 'High':
    case 'Low':
      return AppColors.danger;
    case 'Normal':
      return AppColors.success;
    default:
      return AppColors.warning;
  }
}
