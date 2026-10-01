import 'package:flutter/widgets.dart';

import 'app/MybApp.dart';
import 'core/firebase/firebaseBootstrap.dart';
import 'core/web/configureUrl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrl();
  await FirebaseBootstrap.init();
  runApp(const MybApp());
}
