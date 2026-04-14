import 'package:todo_list/domain/entities/battle_unit_definition.dart';

abstract class BattleCatalogRepository {
  Future<List<BattleUnitDefinitionEntity>> getUnitDefinitions();

  Future<BattleUnitDefinitionEntity?> getUnitDefinition(String unitId);

  Future<void> saveUnitDefinition(BattleUnitDefinitionEntity definition);

  Future<void> deleteUnitDefinition(String unitId);
}
