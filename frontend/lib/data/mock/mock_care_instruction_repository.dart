import '../../models/care_instruction.dart';
import '../../repositories/care_instruction_repository.dart';

class MockCareInstructionRepository implements CareInstructionRepository {
  static const _instanceToSpecies = {
    'plant-001': 'species-tomato',
    'plant-002': 'species-basil',
    'plant-003': 'species-courgette',
  };

  final List<CareInstruction> _instructions = [
    // ── species-tomato (5 instructions) ──
    const CareInstruction(
      instructionId: 'ci-tomato-01',
      speciesId: 'species-tomato',
      title: 'Watering schedule',
      body:
          'Water deeply once or twice a week rather than little and often. '
          'Aim for the base of the plant to keep foliage dry and reduce '
          'the risk of blight. Consistency prevents blossom end rot.',
      sourceType: SourceType.rhs,
      sourceUrl: 'https://www.rhs.org.uk/vegetables/tomatoes/grow-your-own',
      aiVerified: true,
      aiConfidence: 0.95,
    ),
    const CareInstruction(
      instructionId: 'ci-tomato-02',
      speciesId: 'species-tomato',
      title: 'Side-shoot pinching',
      body:
          'For cordon (indeterminate) varieties, pinch out side shoots that '
          'grow in the leaf axils while they are small. This directs energy '
          'into fruit production rather than excess foliage.',
      sourceType: SourceType.book,
      aiVerified: true,
      aiConfidence: 0.88,
      submittedByLabel: 'From "Veg in One Bed" by Huw Richards',
    ),
    const CareInstruction(
      instructionId: 'ci-tomato-03',
      speciesId: 'species-tomato',
      title: 'Feeding regime',
      body:
          'Once the first truss of fruit has set, feed weekly with a '
          'high-potash tomato fertiliser. Dilute to half strength if using '
          'liquid feed to avoid salt build-up in containers.',
      sourceType: SourceType.forum,
      aiVerified: false,
      submittedByLabel: 'GardenersWorld forum user',
    ),
    const CareInstruction(
      instructionId: 'ci-tomato-04',
      speciesId: 'species-tomato',
      title: 'Blight prevention',
      body:
          'Improve air circulation by spacing plants at least 45 cm apart. '
          'Remove lower leaves once fruit trusses above them have ripened. '
          'Avoid overhead watering in humid weather.',
      sourceType: SourceType.rhs,
      sourceUrl: 'https://www.rhs.org.uk/disease/tomato-blight',
      aiVerified: true,
      aiConfidence: 0.92,
    ),
    const CareInstruction(
      instructionId: 'ci-tomato-05',
      speciesId: 'species-tomato',
      title: 'Companion planting tip',
      body:
          'Plant basil nearby — many gardeners find it helps deter aphids '
          'and whitefly, and some say it improves the flavour of the fruit. '
          'Marigolds around the bed also help with pest control.',
      sourceType: SourceType.other,
      aiVerified: false,
      submittedByLabel: 'Added by you',
    ),

    // ── species-basil (5 instructions) ──
    const CareInstruction(
      instructionId: 'ci-basil-01',
      speciesId: 'species-basil',
      title: 'Watering basics',
      body:
          'Keep the soil consistently moist but never waterlogged. Basil '
          'hates sitting in wet soil — ensure pots have drainage holes. '
          'Water in the morning so leaves dry before evening.',
      sourceType: SourceType.rhs,
      sourceUrl: 'https://www.rhs.org.uk/herbs/basil/grow-your-own',
      aiVerified: true,
      aiConfidence: 0.93,
    ),
    const CareInstruction(
      instructionId: 'ci-basil-02',
      speciesId: 'species-basil',
      title: 'Pinching for bushiness',
      body:
          'Regularly pinch off the growing tips once the plant has three '
          'sets of leaves. This encourages branching and prevents the plant '
          'from bolting to flower too early.',
      sourceType: SourceType.book,
      aiVerified: true,
      aiConfidence: 0.90,
      submittedByLabel: 'From "The Herb Garden" by Sarah Garland',
    ),
    const CareInstruction(
      instructionId: 'ci-basil-03',
      speciesId: 'species-basil',
      title: 'Dealing with aphids',
      body:
          'Blast aphids off with a gentle jet of water, or introduce '
          'ladybirds to the area. Neem oil spray works as a last resort '
          'but rinse leaves before harvesting.',
      sourceType: SourceType.forum,
      aiVerified: false,
      submittedByLabel: 'AllotmentOnline member',
    ),
    const CareInstruction(
      instructionId: 'ci-basil-04',
      speciesId: 'species-basil',
      title: 'Temperature sensitivity',
      body:
          'Basil is frost-tender and prefers temperatures above 15°C. '
          'Bring pots indoors or cover with fleece if night temperatures '
          'drop. Cold stress causes blackened leaves.',
      sourceType: SourceType.rhs,
      sourceUrl: 'https://www.rhs.org.uk/herbs/basil',
      aiVerified: true,
      aiConfidence: 0.97,
    ),
    const CareInstruction(
      instructionId: 'ci-basil-05',
      speciesId: 'species-basil',
      title: 'Harvesting technique',
      body:
          'Always harvest from the top down, cutting just above a leaf '
          'pair. Never strip more than a third of the plant at once. '
          'Frequent light harvests keep the plant productive all summer.',
      sourceType: SourceType.other,
      aiVerified: false,
      submittedByLabel: 'Added by you',
    ),

    // ── species-courgette (5 instructions) ──
    const CareInstruction(
      instructionId: 'ci-courgette-01',
      speciesId: 'species-courgette',
      title: 'Watering and mulching',
      body:
          'Courgettes are thirsty plants — water deeply every other day in '
          'warm weather. Mulch around the base with straw or compost to '
          'retain moisture and suppress weeds.',
      sourceType: SourceType.rhs,
      sourceUrl: 'https://www.rhs.org.uk/vegetables/courgettes/grow-your-own',
      aiVerified: true,
      aiConfidence: 0.94,
    ),
    const CareInstruction(
      instructionId: 'ci-courgette-02',
      speciesId: 'species-courgette',
      title: 'Powdery mildew management',
      body:
          'Remove affected leaves promptly and bin them — do not compost. '
          'Improve air circulation by thinning dense foliage. A weekly '
          'diluted milk spray (1:9 ratio) can help prevent recurrence.',
      sourceType: SourceType.book,
      aiVerified: true,
      aiConfidence: 0.85,
      submittedByLabel: 'From "RHS Pests & Diseases" handbook',
    ),
    const CareInstruction(
      instructionId: 'ci-courgette-03',
      speciesId: 'species-courgette',
      title: 'Pollination help',
      body:
          'If fruits are forming but rotting before growing, poor '
          'pollination may be the cause. Hand-pollinate by transferring '
          'pollen from male to female flowers with a small brush.',
      sourceType: SourceType.forum,
      aiVerified: false,
      submittedByLabel: 'GrowVeg community tip',
    ),
    const CareInstruction(
      instructionId: 'ci-courgette-04',
      speciesId: 'species-courgette',
      title: 'Harvest regularly',
      body:
          'Pick courgettes when they are 10–20 cm long for the best '
          'flavour and texture. Regular harvesting encourages the plant '
          'to keep producing new fruit throughout the season.',
      sourceType: SourceType.rhs,
      sourceUrl: 'https://www.rhs.org.uk/vegetables/courgettes',
      aiVerified: true,
      aiConfidence: 0.91,
    ),
    const CareInstruction(
      instructionId: 'ci-courgette-05',
      speciesId: 'species-courgette',
      title: 'Slug and snail defence',
      body:
          'Young courgette plants are slug magnets. Use copper tape around '
          'pots, beer traps, or organic slug pellets. Check plants at dusk '
          'when slugs are most active.',
      sourceType: SourceType.other,
      aiVerified: false,
      submittedByLabel: 'Added by you',
    ),
  ];

  @override
  Future<List<CareInstruction>> getInstructionsForSpecies(
    String speciesId, {
    String? sourceTypeFilter,
  }) async {
    var results = _instructions
        .where((i) => i.speciesId == speciesId)
        .toList();

    if (sourceTypeFilter != null) {
      final filterType = SourceType.values.firstWhere(
        (t) => t.name == sourceTypeFilter,
        orElse: () => SourceType.other,
      );
      results = results.where((i) => i.sourceType == filterType).toList();
    }

    return results;
  }

  @override
  Future<List<CareInstruction>> getInstructionsForPlant(
    String instanceId,
  ) async {
    final speciesId = _instanceToSpecies[instanceId];
    if (speciesId == null) {
      throw Exception('Unknown plant instance: $instanceId');
    }
    return getInstructionsForSpecies(speciesId);
  }
}
