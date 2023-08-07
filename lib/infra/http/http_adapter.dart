import 'dart:convert';

import 'package:http/http.dart';

import '../../data/http/http_client.dart';
import '../../data/http/http_error.dart';

class HttpAdapter implements HttpClient {
  final Client client;

  HttpAdapter({required this.client});

  @override
  Future<Map>? request(
      {required String url, required String method, Object? body}) async {
    final headers = {
      'content-type': 'application/json',
      'accept': 'application/json',
    };

    Response response = Response('{}', 500);

    try {
      if (method == 'post') {
        response =
            await client.post(Uri.http(url), headers: headers, body: body);
      }
    } catch (e) {
      throw HttpError.serverError;
    }

    return _handleResponse(response);
  }

  Map _handleResponse(Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.body.isEmpty) {
      return {};
    } else if (response.statusCode == 400) {
      throw HttpError.badRequest;
    } else if (response.statusCode == 401) {
      throw HttpError.unauthorized;
    } else if (response.statusCode == 403) {
      throw HttpError.forbidden;
    } else if (response.statusCode == 404) {
      throw HttpError.notFound;
    } else {
      throw HttpError.serverError;
    }
  }
}
