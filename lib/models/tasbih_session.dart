class TasbihSession {
  final String zikrId;
  final int count;
  final int target;
  final DateTime date;

  const TasbihSession({
    required this.zikrId,
    required this.count,
    required this.target,
    required this.date,
  });

  TasbihSession copyWith({
    String? zikrId,
    int? count,
    int? target,
    DateTime? date,
  }) {
    return TasbihSession(
      zikrId: zikrId ?? this.zikrId,
      count: count ?? this.count,
      target: target ?? this.target,
      date: date ?? this.date,
    );
  }
}





