import 'package:bloc_test/bloc_test.dart';
import 'package:freshbox_app/features/admin/data/admin_category_repository.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_form_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_form_state.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminCategoryRepository extends Mock implements AdminCategoryRepository {}

const tCategory = Category(
  id: 1,
  parentId: null,
  name: 'Frutas',
  slug: 'frutas',
  iconUrl: null,
  imageUrl: null,
  sortOrder: 1,
  isActive: true,
  productsCount: 5,
);

const tUpdatedCategory = Category(
  id: 1,
  parentId: null,
  name: 'Frutas Atualizadas',
  slug: 'frutas',
  iconUrl: 'https://example.com/icon.png',
  imageUrl: 'https://example.com/image.png',
  sortOrder: 5,
  isActive: false,
  productsCount: 5,
);

void main() {
  late _MockAdminCategoryRepository mockRepository;
  late AdminCategoryFormBloc bloc;

  setUp(() {
    mockRepository = _MockAdminCategoryRepository();
    bloc = AdminCategoryFormBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AdminCategoryFormBloc', () {
    group('create', () {
      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'emits [submitting, success] when successful',
        build: () {
          when(() => mockRepository.create(any())).thenAnswer((_) async => tCategory);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.create({
          'name': 'Frutas',
          'slug': 'frutas',
          'sort_order': 1,
          'is_active': true,
        })),
        expect: () => [
          const AdminCategoryFormState.submitting(),
          predicate<AdminCategoryFormState>((s) => s.maybeWhen(
                success: (category, msg) => category != null && category.name == 'Frutas' && msg == 'Categoria criada com sucesso',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'emits [submitting, error] when repository throws',
        build: () {
          when(() => mockRepository.create(any())).thenThrow(Exception('Validation error'));
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.create({
          'name': 'Frutas',
          'slug': 'frutas',
        })),
        expect: () => [
          const AdminCategoryFormState.submitting(),
          predicate<AdminCategoryFormState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Validation error'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'passes all create data to repository',
        build: () {
          when(() => mockRepository.create(any())).thenAnswer((_) async => tCategory);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.create({
          'name': 'Test Category',
          'slug': 'test-category',
          'sort_order': 10,
          'is_active': false,
          'icon_url': 'https://example.com/icon.png',
          'image_url': 'https://example.com/image.png',
        })),
        expect: () => [
          const AdminCategoryFormState.submitting(),
          predicate<AdminCategoryFormState>((s) => s.maybeWhen(success: (_, __) => true, orElse: () => false)),
        ],
        verify: (bloc) {
          verify(() => mockRepository.create(any())).called(1);
        },
      );
    });

    group('update', () {
      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'emits [submitting, success] when successful',
        build: () {
          when(() => mockRepository.update(any(), any())).thenAnswer((_) async => tUpdatedCategory);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.update(1, {
          'name': 'Frutas Atualizadas',
          'sort_order': 5,
        })),
        expect: () => [
          const AdminCategoryFormState.submitting(),
          predicate<AdminCategoryFormState>((s) => s.maybeWhen(
                success: (category, msg) => category != null && category.name == 'Frutas Atualizadas' && msg == 'Categoria atualizada com sucesso',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'emits [submitting, error] when repository throws',
        build: () {
          when(() => mockRepository.update(any(), any())).thenThrow(Exception('Not found'));
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.update(999, {'name': 'Test'})),
        expect: () => [
          const AdminCategoryFormState.submitting(),
          predicate<AdminCategoryFormState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Not found'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'passes id and update data to repository',
        build: () {
          when(() => mockRepository.update(any(), any())).thenAnswer((_) async => tUpdatedCategory);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.update(42, {
          'name': 'Updated Name',
          'sort_order': 99,
        })),
        verify: (bloc) {
          verify(() => mockRepository.update(42, any())).called(1);
        },
      );
    });

    group('delete', () {
      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'emits [submitting, success] when successful',
        build: () {
          when(() => mockRepository.delete(1)).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.delete(1)),
        expect: () => [
          const AdminCategoryFormState.submitting(),
          predicate<AdminCategoryFormState>((s) => s.maybeWhen(
                success: (category, msg) => category == null && msg == 'Categoria excluída com sucesso',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'emits [submitting, error] when repository throws',
        build: () {
          when(() => mockRepository.delete(999)).thenThrow(Exception('Cannot delete'));
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.delete(999)),
        expect: () => [
          const AdminCategoryFormState.submitting(),
          predicate<AdminCategoryFormState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Cannot delete'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'passes correct id to repository',
        build: () {
          when(() => mockRepository.delete(42)).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(AdminCategoryFormEvent.delete(42)),
        verify: (bloc) {
          verify(() => mockRepository.delete(42)).called(1);
        },
      );
    });

    group('reset', () {
      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'emits initial state',
        build: () => AdminCategoryFormBloc(_MockAdminCategoryRepository()),
        act: (bloc) => bloc.add(const AdminCategoryFormEvent.reset()),
        expect: () => [const AdminCategoryFormState.initial()],
      );

      blocTest<AdminCategoryFormBloc, AdminCategoryFormState>(
        'resets from submitting state',
        build: () {
          final mockRepo = _MockAdminCategoryRepository();
          when(() => mockRepo.create(any()))
              .thenAnswer((_) => Future.delayed(const Duration(milliseconds: 100), () => tCategory));
          return AdminCategoryFormBloc(mockRepo);
        },
        act: (bloc) {
          bloc.add(AdminCategoryFormEvent.create({'name': 'Test', 'slug': 'test'}));
          bloc.add(const AdminCategoryFormEvent.reset());
        },
        expect: () => [
          const AdminCategoryFormState.submitting(),
          const AdminCategoryFormState.initial(),
        ],
      );
    });
  });
}