import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/bootstrap/firebase_bootstrap.dart';

void main() {
  test('Firebase bootstrap is disabled by default until configured', () async {
    final result = await FirebaseBootstrap.initialize();

    expect(result.state, FirebaseBootstrapState.disabled);
    expect(result.isInitialized, isFalse);
  });
}
