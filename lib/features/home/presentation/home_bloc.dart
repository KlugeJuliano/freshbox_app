import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/home_repository.dart';
import 'package:freshbox_app/core/network/paginated.dart';
import 'package:freshbox_app/features/category/domain/category.dart';
import 'package:freshbox_app/features/product/domain/product.dart';
import 'package:freshbox_app/features/store/domain/store.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository;

  HomeBloc(this._repository) : super(const HomeState.initial()) {
    on<HomeEvent>((event, emit) async {
      await event.when(
        loadHome: () => _onLoadHome(emit),
        refreshHome: () => _onRefreshHome(emit),
      );
    });
  }

  Future<void> _onLoadHome(Emitter<HomeState> emit) async {
    emit(const HomeState.loading());
    try {
      final results = await Future.wait([
        _repository.getStore(),
        _repository.getBanners(),
        _repository.getCategories(),
        _repository.getFeaturedProducts(),
        _repository.getPromoProducts(),
      ]);

      emit(HomeState.loaded(
        store: results[0] as Store,
        banners: results[1] as List<String>,
        categories: results[2] as List<Category>,
        featuredProducts: results[3] as Paginated<Product>,
        promoProducts: results[4] as Paginated<Product>,
      ));
    } catch (e) {
      emit(HomeState.error(e.toString()));
    }
  }

  Future<void> _onRefreshHome(Emitter<HomeState> emit) async {
    try {
      final results = await Future.wait([
        _repository.getStore(),
        _repository.getBanners(),
        _repository.getCategories(),
        _repository.getFeaturedProducts(),
        _repository.getPromoProducts(),
      ]);

      emit(HomeState.loaded(
        store: results[0] as Store,
        banners: results[1] as List<String>,
        categories: results[2] as List<Category>,
        featuredProducts: results[3] as Paginated<Product>,
        promoProducts: results[4] as Paginated<Product>,
      ));
    } catch (e) {
      emit(HomeState.error(e.toString()));
    }
  }
}