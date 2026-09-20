class ImportPersistenceSequence {
  const ImportPersistenceSequence._();

  static Future<ImportPersistenceResult> run({
    required Future<void> Function() replaceTimetable,
    Future<void> Function()? persistSemesterMetadata,
    Future<void> Function()? persistSectionTimes,
    Future<void> Function()? persistDetectedApiPath,
  }) async {
    await replaceTimetable();

    final warnings = <String>[];
    await _runOptional(
      label: '保存学期信息',
      action: persistSemesterMetadata,
      warnings: warnings,
    );
    await _runOptional(
      label: '保存上课时间',
      action: persistSectionTimes,
      warnings: warnings,
    );
    await _runOptional(
      label: '保存接口路径',
      action: persistDetectedApiPath,
      warnings: warnings,
    );

    return ImportPersistenceResult(warnings: warnings);
  }

  static Future<void> _runOptional({
    required String label,
    required Future<void> Function()? action,
    required List<String> warnings,
  }) async {
    if (action == null) {
      return;
    }
    try {
      await action();
    } catch (error) {
      warnings.add('$label失败：$error');
    }
  }
}

class ImportPersistenceResult {
  ImportPersistenceResult({required List<String> warnings})
    : warnings = List<String>.unmodifiable(warnings);

  final List<String> warnings;
}
