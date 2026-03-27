import 'dart:io';

void main() async {
  final dir = Directory('lib');
  List<FileSystemEntity> files = dir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = await file.readAsString();
      if (content.contains('AppColors.backgroundDark')) {
        content = content.replaceAll('AppColors.backgroundDark', 'AppColors.backgroundLight');
        await file.writeAsString(content);
        // Log update
        // print('Updated ${file.path}');
      }
    }
  }
}
