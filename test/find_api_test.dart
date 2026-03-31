import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('.dart_tool/package_config.json');
  final jsonStr = file.readAsStringSync();
  final config = jsonDecode(jsonStr);
  for (var pkg in config['packages']) {
    if (pkg['name'] == 'flutter_local_notifications') {
      final rootUri = pkg['rootUri'];
      print('FLN_ROOT: \$rootUri');
      final path = Uri.parse(rootUri).toFilePath();
      print('FLN_PATH: \$path');
      final pluginFile = File('\$path/lib/src/flutter_local_notifications_plugin.dart');
      if (pluginFile.existsSync()) {
        final content = pluginFile.readAsStringSync();
        for (var line in content.split('\n')) {
          if (line.contains('initialize(')) {
            print('LINE: \$line');
          }
        }
      }
    }
  }
}
