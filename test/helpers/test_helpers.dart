import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_product_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_list_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/blocs/admin_category_form_bloc.dart';
import 'package:freshbox_app/features/admin/presentation/admin_products_page.dart';
import 'package:freshbox_app/features/admin/presentation/admin_categories_page.dart';

Widget createTestableProductsPage({
  required AdminProductListBloc productListBloc,
  required AdminProductFormBloc productFormBloc,
}) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => BlocProvider.value(
            value: productListBloc,
            child: BlocProvider.value(
              value: productFormBloc,
              child: const AdminProductsPage(),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget createTestableCategoriesPage({
  required AdminCategoryListBloc categoryListBloc,
  required AdminCategoryFormBloc categoryFormBloc,
}) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/admin/categories',
          builder: (context, state) => BlocProvider.value(
            value: categoryListBloc,
            child: BlocProvider.value(
              value: categoryFormBloc,
              child: const AdminCategoriesPage(),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget createTestableProductsView({
  required AdminProductListBloc productListBloc,
  required AdminProductFormBloc productFormBloc,
}) {
  return MaterialApp(
    home: BlocProvider.value(
      value: productListBloc,
      child: BlocProvider.value(
        value: productFormBloc,
        child: const AdminProductsPage(),
      ),
    ),
  );
}

Widget createTestableCategoriesView({
  required AdminCategoryListBloc categoryListBloc,
  required AdminCategoryFormBloc categoryFormBloc,
}) {
  return MaterialApp(
    home: BlocProvider.value(
      value: categoryListBloc,
      child: BlocProvider.value(
        value: categoryFormBloc,
        child: const AdminCategoriesPage(),
      ),
    ),
  );
}

Future<void> pumpWidgetAndSettle(
  WidgetTester tester,
  Widget widget, {
  Duration duration = const Duration(milliseconds: 100),
}) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle(duration);
}

extension on WidgetTester {
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }
}