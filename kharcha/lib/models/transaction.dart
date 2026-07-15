enum TransactionSource { voice, scan, manual }

class Transaction {
  final String id;
  final String merchant;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String method;
  final TransactionSource source;
  final bool isIncome;

  Transaction({
    required this.id,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.method = 'Cash',
    this.source = TransactionSource.manual,
    this.isIncome = false,
  });
}
