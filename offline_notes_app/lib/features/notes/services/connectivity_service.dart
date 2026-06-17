import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity connectivity = Connectivity();

  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<bool> get connectionStream {
    return connectivity.onConnectivityChanged.map(
      (result) => !result.contains(ConnectivityResult.none),
    );
  }
}
