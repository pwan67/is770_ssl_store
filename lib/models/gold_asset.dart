class GoldAsset {
  final String id;
  final String name;
  final double weight; // in Baht
  final String category;
  final DateTime acquisitionDate;
  final double acquisitionPrice;
  final String status; // 'owned', 'sold', 'pawned'
  final double? loanAmount;
  final DateTime? pawnDate;
  final DateTime? dueDate;
  final double? interestRate;

  GoldAsset({
    required this.id,
    required this.name,
    required this.weight,
    required this.category,
    required this.acquisitionDate,
    required this.acquisitionPrice,
    this.status = 'owned',
    this.loanAmount,
    this.pawnDate,
    this.dueDate,
    this.interestRate,
  });

  GoldAsset copyWith({
    String? status,
    double? loanAmount,
    DateTime? pawnDate,
    DateTime? dueDate,
    double? interestRate,
    bool clearLoan = false, // Helper to nullify loan fields when redeeming
  }) {
    return GoldAsset(
      id: id,
      name: name,
      weight: weight,
      category: category,
      acquisitionDate: acquisitionDate,
      acquisitionPrice: acquisitionPrice,
      status: status ?? this.status,
      loanAmount: clearLoan ? null : (loanAmount ?? this.loanAmount),
      pawnDate: clearLoan ? null : (pawnDate ?? this.pawnDate),
      dueDate: clearLoan ? null : (dueDate ?? this.dueDate),
      interestRate: clearLoan ? null : (interestRate ?? this.interestRate),
    );
  }
}
