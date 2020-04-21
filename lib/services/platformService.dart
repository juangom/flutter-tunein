import 'package:connectivity/connectivity.dart';

class PlatformService{

  Future<bool> isOnWifi() async {
    ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return false;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
  }




}