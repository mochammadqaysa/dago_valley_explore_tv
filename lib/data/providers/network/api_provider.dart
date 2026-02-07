import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_request_representable.dart';

class APIProvider {
  static const requestTimeOut = Duration(seconds: 25);
  final _client = http.Client();

  static final _singleton = APIProvider();
  static APIProvider get instance => _singleton;

  Future request(APIRequestRepresentable request, {int retries = 3}) async {
    int attempt = 0;

    while (attempt < retries) {
      try {
        attempt++;
        print('🌐 API Request attempt $attempt/$retries: ${request.url}');
        print('📤 Method: ${request.method.string}');
        print('📤 Headers: ${request.headers}');

        final uri = Uri.parse(request.url);
        http.Response response;

        // Make HTTP request based on method
        switch (request.method) {
          case HTTPMethod.get:
            response = await _client
                .get(uri, headers: request.headers)
                .timeout(requestTimeOut);
            break;
          case HTTPMethod.post:
            response = await _client
                .post(uri, headers: request.headers, body: request.body)
                .timeout(requestTimeOut);
            break;
          case HTTPMethod.put:
            response = await _client
                .put(uri, headers: request.headers, body: request.body)
                .timeout(requestTimeOut);
            break;
          case HTTPMethod.delete:
            response = await _client
                .delete(uri, headers: request.headers)
                .timeout(requestTimeOut);
            break;
          case HTTPMethod.patch:
            response = await _client
                .patch(uri, headers: request.headers, body: request.body)
                .timeout(requestTimeOut);
            break;
        }

        final result = _returnResponse(response);

        // Check if response is HTML (Cloudflare challenge)
        if (result is String && result.trim().startsWith('<!DOCTYPE')) {
          print('⚠️ Received Cloudflare challenge page on attempt $attempt');

          if (attempt < retries) {
            print(
              '⏳ Waiting 6 seconds for Cloudflare challenge to complete...',
            );
            await Future.delayed(Duration(seconds: 6));
            continue; // Retry
          } else {
            throw FetchDataException(
              'Cloudflare challenge failed after $retries attempts. '
              'Please check your API configuration or whitelist your IP.',
            );
          }
        }

        // Check if response is valid but empty
        if (result is Map &&
            result['housing'] is List &&
            (result['housing'] as List).isEmpty) {
          print('⚠️ Received empty housing data on attempt $attempt');

          if (attempt < retries) {
            print('⏳ Waiting 3 seconds before retry...');
            await Future.delayed(Duration(seconds: 3));
            continue; // Retry
          }
        }

        print('✅ API request successful on attempt $attempt');
        return result;
      } on TimeoutException catch (_) {
        if (attempt >= retries) {
          throw TimeOutException(null);
        }
        print('⏳ Timeout on attempt $attempt, retrying in 2 seconds...');
        await Future.delayed(Duration(seconds: 2));
      } on SocketException {
        throw FetchDataException('No Internet connection');
      } catch (e) {
        if (attempt >= retries) {
          rethrow;
        }
        print('⚠️ Error on attempt $attempt: $e');
        await Future.delayed(Duration(seconds: 2));
      }
    }

    throw FetchDataException('Failed after $retries attempts');
  }

  dynamic _returnResponse(http.Response response) {
    print('📊 Response Status Code: ${response.statusCode}');
    print('📊 Response Headers: ${response.headers}');
    print('📊 Raw Response Body Length: ${response.body.length} characters');

    // Log first 1000 characters of raw response
    if (response.body.isNotEmpty) {
      final rawPreview = response.body.substring(
        0,
        response.body.length > 1000 ? 1000 : response.body.length,
      );
      print('📊 Raw Response Body (first 1000 chars):\n$rawPreview');
    }

    // Parse response body
    dynamic body;
    try {
      // Try to parse as JSON
      body = json.decode(response.body);
      print('✅ Successfully parsed response as JSON');
    } catch (e) {
      // If not JSON, use raw string
      body = response.body;
      print('⚠️ Failed to parse as JSON, using raw string: $e');
    }

    // Log response body preview
    if (body is String) {
      final preview = body.substring(0, body.length > 200 ? 200 : body.length);
      print('📊 Response Body Preview: $preview');
    } else if (body is Map) {
      print('📊 Response Body Keys: ${body.keys.toList()}');
    }

    switch (response.statusCode) {
      case 200:
        print('✅ Status 200: Success');
        return body;
      case 400:
        print('❌ Status 400: Bad Request');
        throw BadRequestException(body.toString());
      case 401:
      case 403:
        print('❌ Status ${response.statusCode}: Unauthorized/Forbidden');
        throw UnauthorisedException(body.toString());
      case 404:
        print('❌ Status 404: Not Found');
        throw BadRequestException('Not found');
      case 429:
        print('❌ Status 429: Too Many Requests (Rate Limited)');
        throw FetchDataException(
          'Rate limited by Cloudflare. Please try again later.',
        );
      case 500:
        print('❌ Status 500: Internal Server Error');
        throw FetchDataException('Internal Server Error');
      case 503:
        print('❌ Status 503: Service Unavailable (Cloudflare)');
        throw FetchDataException(
          'Service temporarily unavailable. Cloudflare may be blocking the request.',
        );
      case 520:
      case 521:
      case 522:
      case 523:
      case 524:
      case 525:
      case 526:
      case 527:
        print('❌ Status ${response.statusCode}: Cloudflare Error');
        throw FetchDataException(
          'Cloudflare error ${response.statusCode}. The origin server may be down or unreachable.',
        );
      default:
        print('❌ Status ${response.statusCode}: Unexpected status code');
        print('❌ Response body: $body');
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode : ${response.statusCode}',
        );
    }
  }
}

class AppException implements Exception {
  final code;
  final message;
  final details;

  AppException({this.code, this.message, this.details});

  String toString() {
    return "[$code]: $message \n $details";
  }
}

class FetchDataException extends AppException {
  FetchDataException(String? details)
    : super(
        code: "fetch-data",
        message: "Error During Communication",
        details: details,
      );
}

class BadRequestException extends AppException {
  BadRequestException(String? details)
    : super(
        code: "invalid-request",
        message: "Invalid Request",
        details: details,
      );
}

class UnauthorisedException extends AppException {
  UnauthorisedException(String? details)
    : super(code: "unauthorised", message: "Unauthorised", details: details);
}

class InvalidInputException extends AppException {
  InvalidInputException(String? details)
    : super(code: "invalid-input", message: "Invalid Input", details: details);
}

class AuthenticationException extends AppException {
  AuthenticationException(String? details)
    : super(
        code: "authentication-failed",
        message: "Authentication Failed",
        details: details,
      );
}

class TimeOutException extends AppException {
  TimeOutException(String? details)
    : super(
        code: "request-timeout",
        message: "Request TimeOut",
        details: details,
      );
}
