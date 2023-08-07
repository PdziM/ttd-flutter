import 'package:clean_architecture/data/http/http_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:faker/faker.dart';

import 'package:clean_architecture/infra/http/http_adapter.dart';

class ClientSpy extends Mock implements Client {}

void main() {
  late Client client;
  late HttpAdapter sut;
  late String url;
  late Map<String, String> headers;

  setUp(() {
    client = ClientSpy();
    sut = HttpAdapter(client: client);
    url = faker.internet.httpUrl().replaceAll('http://', '');
    headers = {
      'content-type': 'application/json',
      'accept': 'application/json',
    };
  });

  group('shared', () {
    test('Should throw ServerError if invalid method provided', () async {
      final future = sut.request(url: url, method: 'invalid_method');

      expect(future, throwsA(HttpError.serverError));
    });
  });

  group('post', () {
    When mockRequest() => when(
          () => client.post(Uri.http(url), headers: any(named: 'headers')),
        );

    void mockResponse(
        {required int statusCode, String body = '{"any_key": "any_value"}'}) {
      mockRequest().thenAnswer((_) async => Response(body, statusCode));
    }

    void mockError() {
      mockRequest().thenThrow(Exception());
    }

    setUp(() {
      mockResponse(statusCode: 200);
    });

    test('Should call post with correct values', () async {
      await sut.request(url: url, method: 'post');

      verify(
        () => client.post(Uri.http(url), headers: headers),
      ).called(1);
    });

    test('Should call post without body', () async {
      await sut.request(url: url, method: 'post');

      verify(
        () => client.post(Uri.http(url), headers: any(named: 'headers')),
      ).called(1);
    });

    test('Should return data if post returns 200', () async {
      final response = await sut.request(url: url, method: 'post');

      expect(response, {'any_key': 'any_value'});
    });

    test('Should return null if post returns 200 with no data', () async {
      mockResponse(statusCode: 200, body: '{}');

      final response = await sut.request(url: url, method: 'post');

      expect(response, {});
    });

    test('Should return null if post returns 204', () async {
      mockResponse(statusCode: 200, body: '{}');

      final response = await sut.request(url: url, method: 'post');

      expect(response, {});
    });

    test('Should return BadRequestError if post returns 400', () async {
      mockResponse(statusCode: 400);

      final future = sut.request(url: url, method: 'post');

      expect(future, throwsA(HttpError.badRequest));
    });

    test('Should return UnauthorizedError if post returns 400', () async {
      mockResponse(statusCode: 401);

      final future = sut.request(url: url, method: 'post');

      expect(future, throwsA(HttpError.unauthorized));
    });

    test('Should return Forbidden if post returns 400', () async {
      mockResponse(statusCode: 403);

      final future = sut.request(url: url, method: 'post');

      expect(future, throwsA(HttpError.forbidden));
    });

    test('Should return NotFound if post returns 400', () async {
      mockResponse(statusCode: 404);

      final future = sut.request(url: url, method: 'post');

      expect(future, throwsA(HttpError.notFound));
    });

    test('Should return ServerError if post returns 500', () async {
      mockResponse(statusCode: 500);

      final future = sut.request(url: url, method: 'post');

      expect(future, throwsA(HttpError.serverError));
    });

    test('Should return ServerError if post throw', () async {
      mockError();

      final future = sut.request(url: url, method: 'post');

      expect(future, throwsA(HttpError.serverError));
    });
  });
}
