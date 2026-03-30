import '../observer/observer.dart';

abstract class Consumer<T> {
  void onNotify();
  void onEvent(EventInfo info);
  void onNavigate(NavigateModel navigateModel);
  void onAlert(AlertModel alertModel);
}
