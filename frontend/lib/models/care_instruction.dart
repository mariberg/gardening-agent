enum SourceType { rhs, forum, book, other }

class CareInstruction {
  final String instructionId;
  final String speciesId;
  final String title;
  final String body;
  final SourceType sourceType;
  final String? sourceUrl;
  final bool aiVerified;
  final double? aiConfidence;
  final String? submittedByLabel;

  const CareInstruction({
    required this.instructionId,
    required this.speciesId,
    required this.title,
    required this.body,
    required this.sourceType,
    this.sourceUrl,
    this.aiVerified = false,
    this.aiConfidence,
    this.submittedByLabel,
  });
}
