import '../../domain/entities/account_entity.dart';

import '../http/http_error.dart';

class RemoteAccountModel {
  final String accessToken;

  RemoteAccountModel({required this.accessToken});

  factory RemoteAccountModel.fromJson({required Map json}) {
    if (!json.containsKey('accessToken')) {
      throw HttpError.invalidData;
    }

    return RemoteAccountModel(accessToken: json['accessToken']);
  }

  AccountEntity toEntity() => AccountEntity(token: accessToken);
}
