import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''

  dart test -p chrome test/web/test_runner_client_native_test.dart

''');
}
