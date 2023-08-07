import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clean_architecture/domain/helpers/domain_error.dart';

import 'package:clean_architecture/usecases/authentication.dart';

import 'package:clean_architecture/data/http/http_client.dart';
import 'package:clean_architecture/data/http/http_error.dart';

import 'package:clean_architecture/data/usecases/remote_authentication.dart';
import 'package:mocktail/mocktail.dart';

class HttpClientSpy extends Mock implements HttpClient {}

void main() {
  late HttpClient httpClient;
  late String url;
  late RemoteAuthentication sub;
  late AuthenticationParams params;

  Map mockValidData() =>
      {'accessToken': faker.guid.guid(), 'name': faker.person.name()};

  When mockRequest() => when(() => httpClient.request(
      url: any(named: 'url'),
      // url: Uri(),
      method: any(named: 'method'),
      body: any(named: 'body')));

  void mockHttpData(Map data) {
    mockRequest().thenAnswer((_) async => data);
  }

  void mockHttpError(HttpError error) {
    mockRequest().thenThrow(error);
  }

  setUp(() {
    httpClient = HttpClientSpy();
    // url = Uri.http(faker.internet.httpUrl().replaceAll('http://', ''));
    url = faker.internet.httpUrl();
    sub = RemoteAuthentication(httpClient: httpClient, url: url);
    params = AuthenticationParams(
      email: faker.internet.email(),
      password: faker.internet.password(),
    );

    mockHttpData(mockValidData());
  });

  test(
    'Should call HttpClient with correct values',
    () async {
      await sub.auth(params: params);

      verify(
        () => httpClient.request(
          url: url,
          method: 'post',
          body: {'email': params.email, 'password': params.password},
        ),
      );
    },
  );

  test(
    'Should throw UnexpectedError if HttpCLient return 400',
    () async {
      mockHttpError(HttpError.badRequest);

      final future = sub.auth(params: params);

      expect(future, throwsA(DomainError.unexpected));
    },
  );

  test(
    'Should throw UnexpectedError if HttpCLient return 404',
    () async {
      mockHttpError(HttpError.notFound);

      final future = sub.auth(params: params);

      expect(future, throwsA(DomainError.unexpected));
    },
  );

  test(
    'Should throw UnexpectedError if HttpCLient return 500',
    () async {
      mockHttpError(HttpError.serverError);

      final future = sub.auth(params: params);

      expect(future, throwsA(DomainError.unexpected));
    },
  );

  test(
    'Should throw InvalidCredentialsError if HttpCLient return 401',
    () async {
      mockHttpError(HttpError.unauthorized);

      final future = sub.auth(params: params);

      expect(future, throwsA(DomainError.invalidCredential));
    },
  );

  test(
    'Should return an Account if HttpCLient return 200',
    () async {
      final validData = mockValidData();
      mockHttpData(validData);

      final account = await sub.auth(params: params);

      expect(account!.token, validData['accessToken']);
    },
  );

  test(
    'Should throw UnexpectedError if HttpCLient return 200 with invalid data',
    () async {
      mockHttpData({'invalid_key': 'invalid_value'});

      final future = sub.auth(params: params);

      expect(future, throwsA(DomainError.unexpected));
    },
  );
}
