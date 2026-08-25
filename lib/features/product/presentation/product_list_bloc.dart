import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_repository.dart';
import '../domain/product.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';
import 'product_list_type.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final ProductRepository _repository;

  ProductListType _currentType = ProductListType.featured;
  String? _currentCategorySlug;
  String? _currentSearchQuery;
  Timer? _debounceTimer;

  ProductListBloc(this._repository) : super(const ProductListState.initial()) {
    on<ProductListEvent>((event, emit) async {
      await event.when(
        loadFeatured: (page) => _onLoadFeatured(page, emit),
        loadPromo: (page) => _onLoadPromo(page, emit),
        search: (query, page) => _onSearchDebounced(query, page, emit),
        loadByCategory: (categorySlug, page) =>
            _onLoadByCategory(categorySlug, page, emit),
        loadMore: () => _onLoadMore(emit),
        refresh: () => _onRefresh(emit),
        changeType: (type) => _onChangeType(type, emit),
      );
    });
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadFeatured(int page, Emitter<ProductListState> emit) async {
    _currentType = ProductListType.featured;
    _currentCategorySlug = null;
    _currentSearchQuery = null;
    await _loadProducts(
      emit,
      page: page,
      loader: (page) => _repository.getFeatured(page: page),
    );
  }

  Future<void> _onLoadPromo(int page, Emitter<ProductListState> emit) async {
    _currentType = ProductListType.promo;
    _currentCategorySlug = null;
    _currentSearchQuery = null;
    await _loadProducts(
      emit,
      page: page,
      loader: (page) => _repository.getPromo(page: page),
    );
  }

  Future<void> _onSearchDebounced(
      String query, int page, Emitter<ProductListState> emit) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query, page, emit);
    });
  }

  Future<void> _executeSearch(
      String query, int page, Emitter<ProductListState> emit) async {
    _currentType = ProductListType.search;
    _currentCategorySlug = null;
    _currentSearchQuery = query;
    await _loadProducts(
      emit,
      page: page,
      loader: (page) => _repository.search(query, page: page),
    );
  }

  Future<void> _onLoadByCategory(
      String categorySlug, int page, Emitter<ProductListState> emit) async {
    _currentType = ProductListType.category;
    _currentCategorySlug = categorySlug;
    _currentSearchQuery = null;
    await _loadProducts(
      emit,
      page: page,
      loader: (page) => _repository.getByCategory(categorySlug, page: page),
    );
  }

  Future<void> _onLoadMore(Emitter<ProductListState> emit) async {
    final currentState = state;
    final hasReachedMax = currentState.maybeWhen(
      loaded: (type, products, hasReachedMax) => hasReachedMax,
      orElse: () => true,
    );
    if (hasReachedMax) return;

    final currentPage = currentState.maybeWhen(
      loaded: (type, products, hasReachedMax) => products.currentPage,
      orElse: () => 1,
    );
    final nextPage = currentPage + 1;

    Future<Paginated<Product>> Function(int) loader;
    switch (_currentType) {
      case ProductListType.featured:
        loader = (page) => _repository.getFeatured(page: page);
        break;
      case ProductListType.promo:
        loader = (page) => _repository.getPromo(page: page);
        break;
      case ProductListType.search:
        if (_currentSearchQuery == null) return;
        loader = (page) => _repository.search(_currentSearchQuery!, page: page);
        break;
      case ProductListType.category:
        if (_currentCategorySlug == null) return;
        loader = (page) =>
            _repository.getByCategory(_currentCategorySlug!, page: page);
        break;
    }

    try {
      final newPage = await loader(nextPage);
      final currentProducts = currentState.maybeWhen(
        loaded: (type, products, hasReachedMax) => products.data,
        orElse: () => <Product>[],
      );
      final combinedProducts = [
        ...currentProducts,
        ...newPage.data,
      ];
      final updatedPaginated = Paginated<Product>(
        data: combinedProducts,
        currentPage: newPage.currentPage,
        lastPage: newPage.lastPage,
        total: newPage.total,
      );
      emit(ProductListState.loaded(
        type: _currentType,
        products: updatedPaginated,
        hasReachedMax: newPage.currentPage >= newPage.lastPage,
      ));
    } catch (e) {
      emit(ProductListState.error(e.toString(), failedType: _currentType));
    }
  }

  Future<void> _onRefresh(Emitter<ProductListState> emit) async {
    await _dispatchInitialLoad(emit);
  }

  Future<void> _onChangeType(
      ProductListType type, Emitter<ProductListState> emit) async {
    _currentType = type;
    await _dispatchInitialLoad(emit);
  }

  Future<void> _dispatchInitialLoad(Emitter<ProductListState> emit) async {
    switch (_currentType) {
      case ProductListType.featured:
        add(const ProductListEvent.loadFeatured());
        break;
      case ProductListType.promo:
        add(const ProductListEvent.loadPromo());
        break;
      case ProductListType.search:
        if (_currentSearchQuery != null) {
          add(ProductListEvent.search(_currentSearchQuery!));
        }
        break;
      case ProductListType.category:
        if (_currentCategorySlug != null) {
          add(ProductListEvent.loadByCategory(_currentCategorySlug!));
        }
        break;
    }
  }

  Future<void> _loadProducts(
    Emitter<ProductListState> emit, {
    required int page,
    required Future<Paginated<Product>> Function(int) loader,
  }) async {
    if (page == 1) {
      emit(ProductListState.loading(currentType: _currentType));
    }

    try {
      final result = await loader(page);
      emit(ProductListState.loaded(
        type: _currentType,
        products: result,
        hasReachedMax: result.currentPage >= result.lastPage,
      ));
    } catch (e) {
      emit(ProductListState.error(e.toString(), failedType: _currentType));
    }
  }
}
