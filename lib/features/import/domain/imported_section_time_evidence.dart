import '../../timetable/domain/section_time_settings.dart';

enum ImportedSectionTimeEvidenceKind {
  explicitRanges,
  startTimesWithDurationFallback,
}

class ImportedSectionTimeEvidence {
  const ImportedSectionTimeEvidence({
    required this.settings,
    required this.kind,
  });

  final SectionTimeSettings settings;
  final ImportedSectionTimeEvidenceKind kind;

  bool get hasExplicitEndTimes =>
      kind == ImportedSectionTimeEvidenceKind.explicitRanges;

  bool get usesDurationFallback => !hasExplicitEndTimes;
}
