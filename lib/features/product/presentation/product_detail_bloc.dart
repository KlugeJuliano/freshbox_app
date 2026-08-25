import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_repository.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductRepository _repository;

  ProductDetailBloc(this._repository)
      : super(const ProductDetailState.initial()) {
    on<ProductDetailEvent>((event, emit) async {
      await event.when(
        load: (slug) => _onLoad(slug, emit),
        refresh: (slug) => _onRefresh(slug, emit),
      );
    });
  }

  Future<void> _onLoad(String slug, Emitter<ProductDetailState> emit) async {
    emit(const ProductDetailState.loading());
    try {
      final product = await _repository.getDetail(slug);
      emit(ProductDetailState.loaded(product));
    } catch (e) {
      emit(ProductDetailState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(String slug, Emitter<ProductDetailState> emit) async {
    try {
      final product = await _repository.getDetail(slug);
      emit(ProductDetailState.loaded(product));
    } catch (e) {
      emit(ProductDetailState.error(e.toString()));
    }
  }
}
