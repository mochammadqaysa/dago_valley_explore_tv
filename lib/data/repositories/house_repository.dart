import 'package:dago_valley_explore_tv/data/models/payload/housing_response_model.dart';
import 'package:dago_valley_explore_tv/data/providers/network/apis/housing_api.dart';
import 'package:dago_valley_explore_tv/domain/entities/payload/housing_response.dart';
import 'package:dago_valley_explore_tv/domain/repositories/house_repository.dart';

class HouseRepositoryImpl extends HouseRepository {
  @override
  Future<HousingResponse> fetchHousingData() async {
    final response = await HousingApi.fetchHousingData().request();

    // Debug: Print response type and structure
    print('📡 API Response Type: ${response.runtimeType}');
    if (response is String) {
      print(
        '📄 Response (first 500 chars): ${response.substring(0, response.length > 500 ? 500 : response.length)}',
      );
    } else if (response is Map) {
      print('📦 Response keys: ${response.keys.toList()}');
      print(
        '🏠 Housing field: ${response["housing"] != null ? "exists (${(response["housing"] as List?)?.length ?? 0} items)" : "NULL"}',
      );
      print(
        '📌 Versions field: ${response["versions"] != null ? "exists" : "NULL"}',
      );
    }

    // Validate response is not HTML (Cloudflare challenge page)
    if (response is String && response.trim().startsWith('<!DOCTYPE')) {
      throw Exception(
        'API returned HTML instead of JSON. This is likely a Cloudflare challenge page. '
        'Please check your API configuration or try again later.',
      );
    }

    // Ensure response is a Map
    if (response is! Map<String, dynamic>) {
      throw Exception(
        'Invalid response type: expected Map<String, dynamic> but got ${response.runtimeType}. '
        'Response: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}',
      );
    }

    return HousingResponseModel.fromJson(response);
  }
}
