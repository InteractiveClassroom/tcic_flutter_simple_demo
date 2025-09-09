import 'package:tcic_flutter_simple_demo/request.dart';

class TCICCloudApi {
  static setConfig({
    required String secretId,
    required String secretKey,
    required int appId,
  }) {
    Request.setConfig(secretId: secretId, secretKey: secretKey, appId: appId);
  }

  /// 通过调用云 API 接口 RegisterUser 注册用户，可以获取到对应的用户 ID(userid)信息。
  static registerUser() async {
    final res = await Request.sendRequest(
      action: "RegisterUser",
      payload: {"SdkAppId": Request.appId},
    );
    return res.data;
  }

  /// 通过云 API 接口 LoginUser 登录，可以获取到用户鉴权 token 信息。
  static loginUser() {}

  /// 通过云 API 接口 CreateRoom 创建课堂，可以获取到课堂号(classid)信息。 创建接口参数详情请参考https://cloud.tencent.com/document/product/1639/80942#1.-.E6.8E.A5.E5.8F.A3.E6.8F.8F.E8.BF.B0
  static createRoom({required String teacherId}) async {
    final res = await Request.sendRequest(
      action: "CreateRoom",
      payload: {
        "Name": "互动课堂Demo测试房间",
        "StartTime": (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 10,
        "EndTime": (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 60 * 30,
        "SdkAppId": Request.appId,
        "Resolution": 1,
        "MaxMicNumber": 6,
        "SubType": "videodoc",
        "TeacherId": teacherId,
      },
    );
    return res.data;
  }
}
