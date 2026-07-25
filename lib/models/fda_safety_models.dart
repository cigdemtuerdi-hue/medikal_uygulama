/// Simulated FDA recall / safety check outcome for listing flows.
enum FdaSafetyStatus {
  idle,
  checking,
  verified,
  recall,
}

class FdaRecallNotice {
  const FdaRecallNotice({
    required this.brand,
    required this.model,
    required this.recallId,
    required this.summary,
  });

  final String brand;
  final String model;
  final String recallId;
  final String summary;
}

class FdaSafetyCheckResult {
  const FdaSafetyCheckResult({
    required this.status,
    this.recall,
    this.checkedLabel,
  });

  final FdaSafetyStatus status;
  final FdaRecallNotice? recall;
  final String? checkedLabel;

  bool get isRecall => status == FdaSafetyStatus.recall;
  bool get isVerified => status == FdaSafetyStatus.verified;
  bool get canPublish => status == FdaSafetyStatus.verified;
}
