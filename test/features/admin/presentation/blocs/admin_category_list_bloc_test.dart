import 'package:bloc_test/bloc_test.dart';
import 'package:freshbox_app/features/admin/data/admin_category_repository.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_list_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_list_state.dart';
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

const tCategory2 = Category(
  id: 2,
  parentId: null,
  name: 'Verduras',
  slug: 'verduras',
  iconUrl: null,
  imageUrl: null,
  sortOrder: 2,
  isActive: true,
  productsCount: 3,
);

void main() {
  late _MockAdminCategoryRepository mockRepository;
  late AdminCategoryListBloc bloc;

  setUp(() {
    mockRepository = _MockAdminCategoryRepository();
    bloc = AdminCategoryListBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AdminCategoryListBloc', () {
    group('load', () {
      blocTest<AdminCategoryListBloc, AdminCategoryListState>(
        'emits [loading, loaded] when successful',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => [tCategory, tCategory2]);
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminCategoryListEvent.load()),
        expect: () => [
          const AdminCategoryListState.loading(),
          predicate<AdminCategoryListState>((s) => s.maybeWhen(
                loaded: (categories) => categories.length == 2 && categories.first.name == 'Frutas',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryListBloc, AdminCategoryListState>(
        'emits [loading, error] when repository throws',
        build: () {
          when(() => mockRepository.getAll()).thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminCategoryListEvent.load()),
        expect: () => [
          const AdminCategoryListState.loading(),
          predicate<AdminCategoryListState>((s) => s.maybeWhen(
                error: (msg) => msg.contains('Network error'),
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryListBloc, AdminCategoryListState>(
        'emits [loading, loaded] with empty list when no categories',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => <Category>[]);
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminCategoryListEvent.load()),
        expect: () => [
          const AdminCategoryListState.loading(),
          predicate<AdminCategoryListState>((s) => s.maybeWhen(
                loaded: (categories) => categories.isEmpty,
                orElse: () => false,
              )),
        ],
      );
    });

    group('refresh', () {
      blocTest<AdminCategoryListBloc, AdminCategoryListState>(
        'emits [loading, loaded] when successful (same as load)',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => [tCategory]);
          return bloc;
        },
        act: (bloc) => bloc.add(const AdminCategoryListEvent.refresh()),
        expect: () => [
          const AdminCategoryListState.loading(),
          predicate<AdminCategoryListState>((s) => s.maybeWhen(
                loaded: (categories) => categories.length == 1,
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminCategoryListBloc, AdminCategoryListState>(
        'can be called multiple times',
        build: () {
          when(() => mockRepository.getAll()).thenAnswer((_) async => [tCategory]);
          return bloc;
        },
        act: (bloc) {
          bloc.add(const AdminCategoryListEvent.load());
          bloc.add(const AdminCategoryListEvent.refresh());
        },
        expect: () => [
          const AdminCategoryListState.loading(),
          predicate<AdminCategoryListState>((s) => s.maybeWhen(loaded: (_) => true, orElse: () => false)),
          const AdminCategoryListState.loading(),
          predicate<AdminCategoryListState>((s) => s.maybeWhen(loaded: (_) => true, orElse: () => false)),
        ],
      );
    });
  });
}