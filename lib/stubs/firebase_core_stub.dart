// Stub file for Windows builds - provides no-op Firebase types
// This allows the code to compile without Firebase packages

class Firebase {
  static Future<void> initializeApp({dynamic options}) async {
    // No-op for Windows
  }
}

class FirebaseOptions {
  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.storageBucket,
    this.measurementId,
    this.iosBundleId,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? storageBucket;
  final String? measurementId;
  final String? iosBundleId;
}
