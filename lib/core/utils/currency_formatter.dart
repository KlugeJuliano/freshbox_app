import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$ ',
  decimalDigits: 2,
);

String formatCurrency(double value) {
  return _currencyFormatter.format(value);
}

extension CurrencyFormatter on double {
  String get formatted => formatCurrency(this);
}
