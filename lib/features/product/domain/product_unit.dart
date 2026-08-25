enum ProductUnit {
  kg,
  un,
  bandeja,
  pct,
  caixa,
  duzia,
  unknown;

  static ProductUnit fromString(String value) => ProductUnit.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => ProductUnit.unknown,
      );

  String get label => switch (this) {
        ProductUnit.kg => 'kg',
        ProductUnit.un => 'un',
        ProductUnit.bandeja => 'bandeja',
        ProductUnit.pct => 'pct',
        ProductUnit.caixa => 'cx',
        ProductUnit.duzia => 'dz',
        ProductUnit.unknown => 'un',
      };
}
