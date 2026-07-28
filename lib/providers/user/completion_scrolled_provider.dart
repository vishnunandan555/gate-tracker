import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompletionIsScrolledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setScrolled(bool val) {
    state = val;
  }
}

final completionIsScrolledProvider = NotifierProvider<CompletionIsScrolledNotifier, bool>(() {
  return CompletionIsScrolledNotifier();
});
