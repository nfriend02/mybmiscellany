import 'package:flutter/widgets.dart';

import 'app/MybApp.dart';
import 'core/firebase/firebaseBootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.init();
  runApp(const MybApp());
}
