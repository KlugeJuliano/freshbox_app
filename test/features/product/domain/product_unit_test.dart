import 'package:flutter_test/flutter_test.dart';
import 'package:freshbox_app/features/product/domain/product_unit.dart';

void main() {
  group('ProductUnit.fromString', () {
    test('parseia todos os valores aceitos pela API', () {
      expect(ProductUnit.fromString('kg'), ProductUnit.kg);
      expect(ProductUnit.fromString('un'), ProductUnit.un);
      expect(ProductUnit.fromString('bandeja'), ProductUnit.bandeja);
      expect(ProductUnit.fromString('maço'), ProductUnit.maco);
      expect(ProductUnit.fromString('cx'), ProductUnit.cx);
      expect(ProductUnit.fromString('lt'), ProductUnit.lt);
      expect(ProductUnit.fromString('pct'), ProductUnit.pct);
    });

    test('aceita aliases sem acento e legados', () {
      expect(ProductUnit.fromString('maco'), ProductUnit.maco);
      expect(ProductUnit.fromString('caixa'), ProductUnit.cx);
    });

    test('é case-insensitive e faz trim', () {
      expect(ProductUnit.fromString(' KG '), ProductUnit.kg);
      expect(ProductUnit.fromString('Bandeja'), ProductUnit.bandeja);
    });

    test('valores desconhecidos caem em unknown', () {
      expect(ProductUnit.fromString('duzia'), ProductUnit.unknown);
      expect(ProductUnit.fromString('dz'), ProductUnit.unknown);
      expect(ProductUnit.fromString(''), ProductUnit.unknown);
      expect(ProductUnit.fromString('xyz'), ProductUnit.unknown);
    });
  });

  group('ProductUnit.apiValue', () {
    test('gera exatamente os valores validados pelo backend', () {
      for (final unit in ProductUnit.values) {
        expect(
          unit.apiValue,
          anyOf(
            'kg',
            'un',
            'bandeja',
            'maço',
            'cx',
            'lt',
            'pct',
          ),
          reason: '${unit.name} deve enviar valor aceito pela API',
        );
      }
    });

    test('apiValue é idempotente via fromString', () {
      for (final unit
          in ProductUnit.values.where((u) => u != ProductUnit.unknown)) {
        expect(ProductUnit.fromString(unit.apiValue), unit,
            reason: '${unit.name} -> apiValue -> fromString');
      }
    });
  });
}
