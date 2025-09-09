import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class Request {
  // 密钥参数
  // 示例的 AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******
  static String secretId = '';
  //示例的 Gu5t9xGARNpq86cd98joQYCN3*******
  static String secretKey = '';
  static int appId = 0;

  static setConfig({
    required String secretId,
    required String secretKey,
    required int appId,
  }) {
    Request.secretId = secretId;
    Request.secretKey = secretKey;
    Request.appId = appId;
  }

  static Future<Response> sendRequest({
    required String action,
    required Map<String, dynamic> payload, // 改为Map类型
    String? region,
  }) async {
    final service = 'lcic';
    final host = 'lcic.tencentcloudapi.com';
    final endpoint = 'https://$host';
    final version = '2022-08-17';
    final algorithm = 'TC3-HMAC-SHA256';
    // final timestamp = 1551113065;
    // 获取当前时间戳
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
    final date = DateFormat('yyyy-MM-dd').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true),
    );

    // ************* 步骤 1：拼接规范请求串 *************
    final httpRequestMethod = 'POST';
    final canonicalUri = '/';
    final canonicalQuerystring = '';
    final ct = 'application/json; charset=utf-8';
    final payloadString = json.encode(payload);
    final canonicalHeaders =
        'content-type:$ct\nhost:$host\nx-tc-action:${action.toLowerCase()}\n';
    final signedHeaders = 'content-type;host;x-tc-action';
    final hashedRequestPayload = sha256.convert(utf8.encode(payloadString));
    final canonicalRequest =
        '''
$httpRequestMethod
$canonicalUri
$canonicalQuerystring
$canonicalHeaders
$signedHeaders
$hashedRequestPayload''';
    print(canonicalRequest);

    // ************* 步骤 2：拼接待签名字符串 *************
    final credentialScope = '$date/$service/tc3_request';
    final hashedCanonicalRequest = sha256.convert(
      utf8.encode(canonicalRequest),
    );
    final stringToSign =
        '''
$algorithm
$timestamp
$credentialScope
$hashedCanonicalRequest''';
    print(stringToSign);

    // ************* 步骤 3：计算签名 *************
    List<int> sign(List<int> key, String msg) {
      final hmacSha256 = Hmac(sha256, key);
      return hmacSha256.convert(utf8.encode(msg)).bytes;
    }

    final secretDate = sign(utf8.encode('TC3$secretKey'), date);
    final secretService = sign(secretDate, service);
    final secretSigning = sign(secretService, 'tc3_request');
    final signature = Hmac(
      sha256,
      secretSigning,
    ).convert(utf8.encode(stringToSign)).toString();
    print(signature);

    // ************* 步骤 4：拼接 Authorization *************
    final authorization =
        '$algorithm Credential=$secretId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';
    print(authorization);

    final dio = Dio();

    try {
      final response = await dio.post(
        endpoint,
        data: payload, // Dio会自动转换为JSON
        options: Options(
          headers: {
            'Authorization': authorization,
            'Content-Type': 'application/json; charset=utf-8',
            'Host': host,
            'X-TC-Action': action,
            'X-TC-Timestamp': timestamp,
            'X-TC-Version': version,
            'X-TC-Region': region,
          },
        ),
      );

      return response;
    } catch (e) {
      print('请求失败: $e');
      rethrow;
    }
  }
}
