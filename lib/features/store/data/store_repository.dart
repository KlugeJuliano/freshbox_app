

import 'package:freshbox_app/core/network/api_endpoint.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/store/domain/store.dart';

class StoreRepository {

  StoreRepository(this.dioClient);

  final DioClient dioClient;

  Future<Store> getStore()async {

    final response = await dioClient.get(ApiEndpoint.clientStore);
  
    print(response.data['data']);

    return Store.fromJson(response.data['data']);
  }
}