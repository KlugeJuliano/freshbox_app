enum ProductUnit {
  kg,
  un,
  bandeja,
  maco,
  cx,
  lt,
  pct,
  unknown;

  /// Valores aceitos pelo backend (StoreProductRequest):
  /// ['kg', 'un', 'bandeja', 'maço', 'cx', 'lt', 'pct']
  static ProductUnit fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'kg':
        return ProductUnit.kg;
      case 'un':
        return ProductUnit.un;
      case 'bandeja':
        return ProductUnit.bandeja;
      case 'maço': // valor real da API
      case 'maco': // alias sem acento
        return ProductUnit.maco;
      case 'cx': // valor real da API
      case 'caixa': // alias legado
        return ProductUnit.cx;
      case 'lt':
        return ProductUnit.lt;
      case 'pct':
        return ProductUnit.pct;
      default:
        return ProductUnit.unknown;
    }
  }

  /// Valor a ser enviado/validado pelo backend.
  /// Usar sempre este getter em payloads — nunca `.name`.
  String get apiValue => switch (this) {
        ProductUnit.kg => 'kg',
        ProductUnit.un => 'un',
        ProductUnit.bandeja => 'bandeja',
        ProductUnit.maco => 'maço',
        ProductUnit.cx => 'cx',
        ProductUnit.lt => 'lt',
        ProductUnit.pct => 'pct',
        ProductUnit.unknown => 'un',
      };

  String get label => switch (this) {
        ProductUnit.kg => 'kg',
        ProductUnit.un => 'un',
        ProductUnit.bandeja => 'bandeja',
        ProductUnit.maco => 'maço',
        ProductUnit.cx => 'cx',
        ProductUnit.lt => 'lt',
        ProductUnit.pct => 'pct',
        ProductUnit.unknown => 'un',
      };
}
