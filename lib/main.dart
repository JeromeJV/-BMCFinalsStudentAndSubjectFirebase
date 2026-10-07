import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'page_form.dart';

/// Sinisimulan ang Flutter app at kinokonekta ito sa Firebase bago ipakita ang UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

/// Root widget na nagtatakda ng tema at unang page ng app.
class MyApp extends StatelessWidget {
  /// Gumagawa ng root widget; ginagamit ang [key] para sa widget identity.
  const MyApp({super.key});

  /// Binubuo ang pangunahing Material app at ipinapakita ang [FormPage].
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biodata Form',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FormPage(),
    );
  }
}
