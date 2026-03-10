import 'package:flutter/foundation.dart';

class AppProvider extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
