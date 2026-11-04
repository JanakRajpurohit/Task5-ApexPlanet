import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

bool get isFirebaseConfigured {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    return ![
      options.apiKey,
      options.appId,
      options.messagingSenderId,
      options.projectId,
    ].any((value) => value.startsWith('YOUR_') || value.isEmpty);
  } on UnsupportedError {
    return false;
  }
}

String get firebaseSetupMessage {
  if (kIsWeb) {
    return 'Web is not configured for Firebase. From the project folder run '
        '"dart pub global run flutterfire_cli:flutterfire configure '
        '--project=crave-4418b" and select both Android and Web.';
  }
  return 'Run "flutterfire configure" from the project folder to generate '
      'Firebase options for this platform, then restart the app.';
}
