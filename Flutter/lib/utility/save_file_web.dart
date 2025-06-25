import 'dart:convert';
import 'package:web/web.dart';

Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
  final HTMLAnchorElement anchor = document.createElement('a') as HTMLAnchorElement
    ..href = 'data:application/octet-stream;base64,${base64Encode(bytes)}'
    ..style.display = 'none'
    ..download = fileName;

  document.body!.appendChild(anchor);

  anchor.click();
  document.body!.removeChild(anchor);
}
