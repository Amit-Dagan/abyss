import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_model.dart';
import 'package:todo_list/service_locator.dart';

class UnitLibraryViewModel extends ViewModel<UnitLibraryModel> {
  final BattleCatalogRepository _catalogRepository =
      sl<BattleCatalogRepository>();

  UnitLibraryViewModel({required super.model});

  Future<void> loadUnits() async {
    model.status = UnitLibraryStatus.loading;
    notify();

    try {
      model.units = await _catalogRepository.getUnitDefinitions();
      model.status = UnitLibraryStatus.ready;
      model.errorMessage = null;
      notify();
    } catch (error) {
      model.status = UnitLibraryStatus.failure;
      model.errorMessage = error.toString();
      notify();
    }
  }

  @override
  void onViewLoaded(data) {
    super.onViewLoaded(data);
    loadUnits();
  }

  @override
  void onViewResumed() {
    super.onViewResumed();
    loadUnits();
  }
}
