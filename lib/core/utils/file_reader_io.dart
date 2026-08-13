import 'dart:io';

List<int>? getFileBytes(String path) {
  try {
    return File(path).readAsBytesSync();
  } catch (e) {
    return null;
  }
}
