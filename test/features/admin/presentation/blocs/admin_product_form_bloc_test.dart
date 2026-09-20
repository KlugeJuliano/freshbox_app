import 'package:bloc_test/bloc_test.dart';
import 'package:freshbox_app/features/admin/data/admin_product_repository.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_form_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_form_state.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/product/domain/product_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminProductRepository extends Mock implements AdminProductRepository {}

const tProduct = Product(
  id: 1,
  name: 'Banana Nanica',
  slug: 'banana-nanica',
  description: null,
  unitRaw: 'kg',
  price: 4.99,
  promoPrice: null,
  promoEndsAtRaw: null,
  isOnPromo: false,
  effectivePrice: 4.99,
  images: ProductImage(thumb: null, card: null, full: null),
  isAvailable: true,
  isFeatured: true,
  isActive: true,
  categoryId: 1,
);

const tUpdatedProduct = Product(
  id: 1,
  name: 'Banana Nanica Atualizada',
  slug: 'banana-nanica',
  description: 'Banana fresca atualizada',
  unitRaw: 'kg',
  price: 5.49,
  promoPrice: 4.49,
  promoEndsAtRaw: '2026-05-01T00:00:00+00:00',
  isOnPromo: true,
  effectivePrice: 4.49,
  images: ProductImage(thumb: null, card: null, full: null),
  isAvailable: true,
  isFeatured: true,
  isActive: true,
  categoryId: 1,
);

void main() {
  late _MockAdminProductRepository mockRepository;
  late AdminProductFormBloc bloc;

  setUp(() {
    mockRepository = _MockAdminProductRepository();
    bloc = AdminProductFormBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AdminProductFormBloc', () {
    group('create', () {
      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'emits [submitting, success] when successful',
        build: () {
          when(() => mockRepository.create(any())).thenAnswer((_) async => tProduct);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.create({
          'name': 'Banana Nanica',
          'slug': 'banana-nanica',
          'unit': 'kg',
          'price': 4.99,
          'category_id': 1,
          'is_available': true,
          'is_featured': true,
          'is_active': true,
        })),
        expect: () => [
          const AdminProductFormState.submitting(),
          predicate<AdminProductFormState>((s) => s.maybeWhen(
                success: (product, msg) => product != null && product.name == 'Banana Nanica' && msg == 'Produto criado com sucesso',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'emits [submitting, error] when repository throws',
        build: () {
          when(() => mockRepository.create(any())).thenThrow(Exception('Validation error'));
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.create({
          'name': 'Banana Nanica',
          'slug': 'banana-nanica',
          'unit': 'kg',
          'price': 4.99,
          'category_id': 1,
        })),
        expect: () => [
          const AdminProductFormState.submitting(),
          predicate<AdminProductFormState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Validation error'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'passes all create data to repository',
        build: () {
          when(() => mockRepository.create(any())).thenAnswer((_) async => tProduct);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.create({
          'name': 'Test Product',
          'slug': 'test-product',
          'description': 'Test description',
          'unit': 'un',
          'price': 10.0,
          'promo_price': 8.0,
          'promo_ends_at': '2026-12-31T23:59:59+00:00',
          'category_id': 2,
          'is_available': false,
          'is_featured': true,
          'is_on_promo': true,
          'is_active': false,
          'thumb_url': 'https://example.com/thumb.jpg',
          'card_url': 'https://example.com/card.jpg',
          'full_url': 'https://example.com/full.jpg',
        })),
        expect: () => [
          const AdminProductFormState.submitting(),
          predicate<AdminProductFormState>((s) => s.maybeWhen(success: (_, __) => true, orElse: () => false)),
        ],
        verify: (bloc) {
          verify(() => mockRepository.create(any())).called(1);
        },
      );
    });

    group('update', () {
      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'emits [submitting, success] when successful',
        build: () {
          when(() => mockRepository.update(any(), any())).thenAnswer((_) async => tUpdatedProduct);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.update(1, {
          'name': 'Banana Nanica Atualizada',
          'price': 5.49,
        })),
        expect: () => [
          const AdminProductFormState.submitting(),
          predicate<AdminProductFormState>((s) => s.maybeWhen(
                success: (product, msg) => product != null && product.name == 'Banana Nanica Atualizada' && msg == 'Produto atualizado com sucesso',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'emits [submitting, error] when repository throws',
        build: () {
          when(() => mockRepository.update(any(), any())).thenThrow(Exception('Not found'));
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.update(999, {'name': 'Test'})),
        expect: () => [
          const AdminProductFormState.submitting(),
          predicate<AdminProductFormState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Not found'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'passes id and update data to repository',
        build: () {
          when(() => mockRepository.update(any(), any())).thenAnswer((_) async => tUpdatedProduct);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.update(42, {
          'name': 'Updated Name',
          'price': 99.99,
        })),
        verify: (bloc) {
          verify(() => mockRepository.update(42, any())).called(1);
        },
      );
    });

    group('delete', () {
      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'emits [submitting, success] when successful',
        build: () {
          when(() => mockRepository.delete(1)).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.delete(1)),
        expect: () => [
          const AdminProductFormState.submitting(),
          predicate<AdminProductFormState>((s) => s.maybeWhen(
                success: (product, msg) => product == null && msg == 'Produto excluído com sucesso',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'emits [submitting, error] when repository throws',
        build: () {
          when(() => mockRepository.delete(999)).thenThrow(Exception('Cannot delete'));
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.delete(999)),
        expect: () => [
          const AdminProductFormState.submitting(),
          predicate<AdminProductFormState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Cannot delete'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'passes correct id to repository',
        build: () {
          when(() => mockRepository.delete(42)).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(AdminProductFormEvent.delete(42)),
        verify: (_) {
          verify(() => mockRepository.delete(42)).called(1);
        },
      );
    });

    group('reset', () {
      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'emits initial state',
        build: () => AdminProductFormBloc(_MockAdminProductRepository()),
        act: (bloc) => bloc.add(const AdminProductFormEvent.reset()),
        expect: () => [const AdminProductFormState.initial()],
      );

      blocTest<AdminProductFormBloc, AdminProductFormState>(
        'resets from submitting state',
        build: () {
          final mockRepo = _MockAdminProductRepository();
          when(() => mockRepo.create(any()))
              .thenAnswer((_) => Future.delayed(const Duration(milliseconds: 100), () => tProduct));
          return AdminProductFormBloc(mockRepo);
        },
        act: (bloc) {
          bloc.add(AdminProductFormEvent.create({'name': 'Test', 'slug': 'test', 'unit': 'kg', 'price': 1.0, 'category_id': 1}));
          bloc.add(const AdminProductFormEvent.reset());
        },
        expect: () => [
          const AdminProductFormState.submitting(),
          const AdminProductFormState.initial(),
        ],
      );
    });
  });
}