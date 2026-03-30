import 'package:flutter/material.dart';
import 'package:mvvm_remepy/base_page.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_card.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_arguments.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_model.dart';
import 'package:todo_list/presentation/pages/unit_library/unit_library_view_model.dart';

class UnitLibraryScreen
    extends BasePage<UnitLibraryModel, UnitLibraryViewModel> {
  const UnitLibraryScreen({super.key, required super.viewModel});

  @override
  BasePageState<UnitLibraryModel, UnitLibraryViewModel, UnitLibraryScreen>
  createState() => _UnitLibraryScreenState();
}

class _UnitLibraryScreenState
    extends
        BasePageState<
          UnitLibraryModel,
          UnitLibraryViewModel,
          UnitLibraryScreen
        > {
  @override
  Color get backgroundColor => AppColors.backgroundColor;

  @override
  PreferredSizeWidget? get appBar => AppBar(
    title: Text(
      model.appBarTitle,
      style: const TextStyle(
        color: AppColors.whiteColor,
        fontWeight: FontWeight.w800,
      ),
    ),
    backgroundColor: AppColors.primaryColor,
  );

  @override
  Widget? get floatingActionButton => FloatingActionButton.extended(
    onPressed: () => _openEditor(),
    backgroundColor: AppColors.primaryColor,
    foregroundColor: Colors.white,
    icon: const Icon(Icons.add_rounded),
    label: const Text('Create Unit'),
  );

  @override
  Widget get body {
    switch (model.status) {
      case UnitLibraryStatus.initial:
      case UnitLibraryStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      case UnitLibraryStatus.failure:
        return Center(
          child: Text(
            model.errorMessage ?? 'Failed to load units',
            style: const TextStyle(color: AppColors.primaryColor),
          ),
        );
      case UnitLibraryStatus.ready:
        return SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth >= 760;
              final int crossAxisCount = wide ? 3 : 2;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 16),
                    if (model.units.isEmpty)
                      _buildEmptyState()
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: model.units.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: wide ? 0.72 : 0.66,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final BattleUnitDefinitionEntity unit =
                              model.units[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _openEditor(unitId: unit.id),
                            child: BattleUnitCard(
                              definition: unit,
                              compact: true,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.boxShadowColor,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design your unit roster',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'These cards are loaded from the local JSON catalog. Create new units here, then go back to the battle screen to place them on the board.',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.style_rounded, size: 38, color: AppColors.primaryColor),
          SizedBox(height: 10),
          Text(
            'No units yet',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create your first unit to start building the roster.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.primaryColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor({String? unitId}) async {
    await Navigator.pushNamed(
      context,
      '/unitEditor',
      arguments: UnitEditorArguments(unitId: unitId),
    );
    if (mounted) {
      viewModel.loadUnits();
    }
  }
}
