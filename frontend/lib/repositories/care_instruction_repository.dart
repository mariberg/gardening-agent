import '../models/care_instruction.dart';

abstract class CareInstructionRepository {
  Future<List<CareInstruction>> getInstructionsForSpecies(String speciesId, {String? sourceTypeFilter});
  Future<List<CareInstruction>> getInstructionsForPlant(String instanceId);
}
