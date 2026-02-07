import 'dart:io';

import '../api_endpoint.dart';
import '../api_provider.dart';
import '../api_request_representable.dart';

class HousingApi implements APIRequestRepresentable {
  HousingApi._();

  HousingApi.fetchHousingData();

  @override
  String get endpoint => APIEndpoint.housingData;

  String get path {
    return "/data";
  }

  @override
  HTTPMethod get method {
    return HTTPMethod.get;
  }

  Map<String, String> get headers => {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.acceptHeader: 'application/json, text/plain, */*',
    HttpHeaders.userAgentHeader:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9,id;q=0.8',
    'Accept-Encoding':
        'gzip, deflate', // Removed 'br' - http package doesn't auto-decompress Brotli
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
  };

  Map<String, String> get query {
    return {};
  }

  @override
  get body => null;

  Future request() {
    return APIProvider.instance.request(this);
  }

  @override
  String get url => endpoint + path;
}
