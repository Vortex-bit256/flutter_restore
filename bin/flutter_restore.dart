import 'dart:io';

import 'package:flutter_restore/flutter_restore.dart';

Future<void> main(List<String> arguments) async {
  final exitCode = await runFlutterRestore(
    arguments,
    stdout: stdout,
    stderr: stderr,
  );
  exit(exitCode);
}
