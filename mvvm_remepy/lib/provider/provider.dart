import '../observer/observer.dart';
import 'consumer.dart';

mixin class Provider<T> {
  final Set<Consumer> _consumers = <Consumer>{};

  static const onViewLoadedEvent = 'onViewLoadedEvent';

  Consumer get root {
    return _consumers.first;
  }

  void addConsumer(Consumer<T> consumer) {
    _consumers.add(consumer);
  }

  void removeConsumer(Consumer<T> consumer) {
    _consumers.remove(consumer);
  }

  void notify() {
    for (Consumer element in _consumers) {
      element.onNotify();
    }
  }

  void notifyAlert(AlertModel alertModel) {
    for (Consumer element in _consumers) {
      element.onAlert(alertModel);
    }
  }

  void emitEvent(EventInfo info) {
    for (Consumer consumer in List.from(_consumers)) {
      consumer.onEvent(info);
    }
  }

  void notifyNavigate(NavigateModel navigateModel) {
    for (Consumer element in _consumers) {
      element.onNavigate(navigateModel);
    }
  }
}
