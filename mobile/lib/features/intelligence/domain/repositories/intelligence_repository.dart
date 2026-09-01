import '../entities/data_intelligence.dart';

abstract interface class IntelligenceRepository {
  Future<DataIntelligence> getSummary();
}

class IntelligenceFailure implements Exception {
  const IntelligenceFailure();
}
