import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:freshbox_app/features/admin/data/admin_banner_repository.dart';
import 'package:freshbox_app/features/admin/domain/banner.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_form_event.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_banner_form_state.dart';
import 'package:freshbox_app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminBannerRepository extends Mock
    implements AdminBannerRepository {}

const tBanner = Banner(
  id: 1,
  title: 'Promo',
  linkTypeRaw: 'product',
  linkValue: 'banana-nanica',
  priority: 10,
  isActive: true,
);

void main() {
  late _MockAdminBannerRepository mockRepository;
  late AdminBannerFormBloc bloc;

  final tempDir = Directory.systemTemp.createTempSync('banner_bloc_test');
  late File imageFile;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(File('x'));
  });

  setUp(() {
    imageFile = File('${tempDir.path}/banner.jpg')
      ..writeAsBytesSync(List.filled(8, 1));
  });

  setUp(() {
    mockRepository = _MockAdminBannerRepository();
    bloc = AdminBannerFormBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('AdminBannerFormBloc', () {
    group('create', () {
      blocTest<AdminBannerFormBloc, AdminBannerFormState>(
        'emits [submitting, success] with image on success',
        build: () {
          when(() => mockRepository.create(any(), any()))
              .thenAnswer((_) async => tBanner);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminBannerFormEvent.create(
          {
            'title': 'Promo',
            'priority': '10',
            'is_active': 'true',
          },
          imageFile,
        )),
        expect: () => [
          const AdminBannerFormState.submitting(),
          predicate<AdminBannerFormState>((s) => s.maybeWhen(
                success: (banner, msg) =>
                    banner != null &&
                    banner.id == 1 &&
                    msg == 'Banner criado com sucesso',
                orElse: () => false,
              )),
        ],
      );

      blocTest<AdminBannerFormBloc, AdminBannerFormState>(
        'emits [submitting, error] with friendly message on ApiException',
        build: () {
          when(() => mockRepository.create(any(), any())).thenThrow(
            ApiException(message: 'Erro de validação.', statusCode: 422),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(AdminBannerFormEvent.create(
          {'title': 'Promo'},
          imageFile,
        )),
        expect: () => [
          const AdminBannerFormState.submitting(),
          predicate<AdminBannerFormState>((s) => s.maybeWhen(
                error: (msg) => msg == 'Erro de validação.',
                orElse: () => false,
              )),
        ],
      );
    });

    group('update', () {
      blocTest<AdminBannerFormBloc, AdminBannerFormState>(
        'emits [submitting, success] without image (optional)',
        build: () {
          when(() => mockRepository.update(any(), any(),
                  imageFile: any(named: 'imageFile'),
                  imageMobileFile: any(named: 'imageMobileFile')))
              .thenAnswer((_) async => tBanner);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminBannerFormEvent.update(
          1,
          {'priority': '20'},
        )),
        expect: () => [
          const AdminBannerFormState.submitting(),
          predicate<AdminBannerFormState>((s) => s.maybeWhen(
                success: (banner, msg) =>
                    banner != null && msg == 'Banner atualizado com sucesso',
                orElse: () => false,
              )),
        ],
        verify: (_) {
          verify(() => mockRepository.update(
                1,
                {'priority': '20'},
                imageFile: null,
                imageMobileFile: null,
              )).called(1);
        },
      );
    });

    group('delete', () {
      blocTest<AdminBannerFormBloc, AdminBannerFormState>(
        'emits [submitting, success] with null banner',
        build: () {
          when(() => mockRepository.delete(1)).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(AdminBannerFormEvent.delete(1)),
        expect: () => [
          const AdminBannerFormState.submitting(),
          predicate<AdminBannerFormState>((s) => s.maybeWhen(
                success: (banner, msg) =>
                    banner == null && msg == 'Banner excluído com sucesso',
                orElse: () => false,
              )),
        ],
      );
    });

    group('toggle', () {
      blocTest<AdminBannerFormBloc, AdminBannerFormState>(
        'emits [submitting, success] with updated banner',
        build: () {
          final inactive = Banner(
            id: 1,
            title: 'Promo',
            linkTypeRaw: 'product',
            linkValue: 'banana-nanica',
            priority: 10,
            isActive: false,
          );
          when(() => mockRepository.toggle(1))
              .thenAnswer((_) async => inactive);
          return bloc;
        },
        act: (bloc) => bloc.add(AdminBannerFormEvent.toggle(1)),
        expect: () => [
          const AdminBannerFormState.submitting(),
          predicate<AdminBannerFormState>((s) => s.maybeWhen(
                success: (banner, msg) =>
                    banner != null &&
                    !banner.isActive &&
                    msg == 'Banner desativado',
                orElse: () => false,
              )),
        ],
      );
    });
  });
}
