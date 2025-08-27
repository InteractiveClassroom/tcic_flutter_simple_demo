import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tcic_client_ui/utils/model/enum/role_enum.dart';
import 'package:tcic_flutter_simple_demo/class_room.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isWebViewLoading = true; // 添加WebView loading状态
  InAppWebViewController? webViewController;

  /// userId, classId, role, token 等需要您根据自己的业务场景进行替换
  gotoRoomPage(dynamic args) {
    final datas = args as List<dynamic>;
    if (datas.isNotEmpty) {
      final data = datas.first as Map<String, dynamic>;
      final userId = data['userid'].toString();
      final token = data['token'].toString();
      final classid = data['classid'].toString();
      final role = data['role'].toString();
      debugPrint(
        "userId: $userId, token: $token, classid: $classid, role: $role",
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassRoom(
            userId: userId,
            token: token,
            classId: classid,
            role: role.isNotEmpty
                ? (role == 'teacher'
                      ? RoleEnum.teacher
                      : role == 'student'
                      ? RoleEnum.student
                      : role == 'assistant'
                      ? RoleEnum.assistant
                      : RoleEnum.supervisor)
                : RoleEnum.teacher,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(
                "https://dev-class.qcloudclass.com/flutter/login.html?lng=zh",
              ),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: "gotoRoomPage",
                callback: gotoRoomPage,
              );
            },
            onLoadStart: (controller, url) {
              setState(() {
                isWebViewLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                isWebViewLoading = false;
              });
            },
            onReceivedError: (controller, request, errorResponse) {
              setState(() {
                isWebViewLoading = false;
              });
            },
          ),
          if (isWebViewLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3.0,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '加载中...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
