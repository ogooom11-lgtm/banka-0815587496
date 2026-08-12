class BankSettings {
  double randomDeductionMin;
  double randomDeductionMax;
  int salaryDay; // her ayın kaçında maaş yatacak
  String currency;
  String bankName;

  BankSettings({
    this.randomDeductionMin = 50,
    this.randomDeductionMax = 500,
    this.salaryDay = 1,
    this.currency = '₺',
    this.bankName = 'Arena Bank',
  });

  Map<String, dynamic> toJson() => {
        'randomDeductionMin': randomDeductionMin,
        'randomDeductionMax': randomDeductionMax,
        'salaryDay': salaryDay,
        'currency': currency,
        'bankName': bankName,
      };

  factory BankSettings.fromJson(Map<String, dynamic> json) => BankSettings(
        randomDeductionMin: (json['randomDeductionMin'] as num?)?.toDouble() ?? 50,
        randomDeductionMax: (json['randomDeductionMax'] as num?)?.toDouble() ?? 500,
        salaryDay: json['salaryDay'] ?? 1,
        currency: json['currency'] ?? '₺',
        bankName: json['bankName'] ?? 'Arena Bank',
      );
}
