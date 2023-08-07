import '../../usecases/authentication.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/helpers/domain_error.dart';

import '../http/http_client.dart';
import '../http/http_error.dart';

import '../models/remote_account_model.dart';

class RemoteAuthentication implements Authentication {
  final HttpClient httpClient;
  final String url;
  final Map? body;

  RemoteAuthentication({
    required this.httpClient,
    required this.url,
    this.body,
  });

  @override
  Future<AccountEntity>? auth({required AuthenticationParams params}) async {
    final body = RemoteAuthenticationParams.fromDomain(params: params).toJson();

    try {
      final httpResponse =
          await httpClient.request(url: url, method: 'post', body: body);

      return RemoteAccountModel.fromJson(json: httpResponse!).toEntity();
    } on HttpError catch (error) {
      throw error == HttpError.unauthorized
          ? DomainError.invalidCredential
          : DomainError.unexpected;
    }
  }
}

class RemoteAuthenticationParams {
  final String email;
  final String password;

  RemoteAuthenticationParams({
    required this.email,
    required this.password,
  });

  Map toJson() => {'email': email, 'password': password};

  factory RemoteAuthenticationParams.fromDomain(
          {required AuthenticationParams params}) =>
      RemoteAuthenticationParams(
        email: params.email,
        password: params.password,
      );
}
