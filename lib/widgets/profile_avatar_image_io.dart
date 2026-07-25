import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider? profileAvatarImage(String? imagePath) {
  if (imagePath == null || !File(imagePath).existsSync()) {
    return null;
  }
  return FileImage(File(imagePath));
}
