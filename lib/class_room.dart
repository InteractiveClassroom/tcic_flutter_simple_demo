import 'package:flutter/material.dart';
import 'package:tcic_client_ui/controller/tcic_contoller.dart';
import 'package:tcic_client_ui/tcic_client_ui.dart';
import 'package:tcic_client_ui/user_defined/callback/tcic_callback.dart';
import 'package:tcic_client_ui/utils/model/enum/role_enum.dart';
import 'package:tcic_client_ui/utils/model/enum/translate_lang_enum.dart';
import 'package:tcic_client_ui/utils/model/tcic_cofig_model.dart';
import 'package:tcic_client_ui/utils/model/tcic_component_config/header_component_config.dart';
import 'package:tcic_client_ui/utils/model/tcic_component_config/memebers_component_config.dart';
import 'package:tcic_client_ui/utils/model/tcic_component_config/message_component_config.dart';
import 'package:tcic_client_ui/utils/model/tcic_component_config/settting_component_config.dart';
import 'package:tcic_client_ui/utils/model/tcic_component_config/video_component_config.dart';
import 'package:tcic_client_ui/utils/model/tcic_component_config/whiteboard_component_config.dart';
import 'package:tcic_client_ui/utils/model/tcic_lang_config_model.dart';
import 'package:tcic_client_ui/utils/model/tcic_userinfo_model.dart';
import 'package:tcic_client_ui/utils/model/tcic_liveplayer_config_model.dart';

class ClassRoom extends StatefulWidget {
  final String userId;
  final String token;
  final String classId;
  final RoleEnum role;
  const ClassRoom({
    super.key,
    required this.userId,
    required this.token,
    required this.classId,
    required this.role,
  });

  @override
  State<ClassRoom> createState() => _ClassRoomState();
}

class _ClassRoomState extends State<ClassRoom> {
  final TCICController controller = TCICController();
  onUserInfoChange(TCICUserinfo data) {
    debugPrint(data.age.toString());
    debugPrint(data.name);
  }

  addListener() {
    controller.getEventBus().on<TCICUserinfo>(onUserInfoChange);
  }

  @override
  void initState() {
    super.initState();
    addListener();
  }

  @override
  Widget build(BuildContext context) {
    return TCICView(
      controller: controller,
      callback: TCICCallback(
        onJoinedClassSuccess: () {
          print("加入课堂成功");
        },
        onMemberJoinedClass: (member) {
          if (member.role == RoleEnum.student.index) {}
        },
      ),
      config: TCICConfig(
        token: widget.token,
        classId: widget.classId,
        userId: widget.userId,
        role: widget.role,
        langConfig: TCICLangConfig(lang: TranslateLangEnum.zh),
        /// 如果是大班课，需要申请license，请联系客服
        // liveplayerConfig: TCICLivePlayerConfig(
        //   licenseUrl:
        //       '',
        //   licenseKey: '',
        // ),
        // fontConfig: TCICFontConfig(fontFamily: 'FredokaOne', enableCustomFont: true, fontPath: 'assets/fonts/FredokaOne-Regular.ttf'),
        componentConfig: [
          HeaderComponentConfig(
            // enableCoureseware: false,
            // enableMemberList: false,
            // enableMessage: false,
            // enableScreenShare: true,
            // enableSetting: false,
            // showClassInfo: true,
            // showClassName: true,
            // showClassTime: false,
            // showNetworkStatus: false
            // headerActionsBuilder: () {
            //   return Container();
            // },
            // headerLeftBuilder: () {
            //   return Container();
            // },
            // headerRightBuilder: () {
            //   return Container();
            // },
          ),
          WhiteboardComponentConfig(),
          MessageComponentConfig(
            // messageItemBuilder: () {},
            // messageHeaderBuilder: (message) {
            //   return Container(child: Text(message.nickName ?? ''),);
            // },
            // messageBubbleBuilder: (child) {},
            // messageRowBuilder: () {},
          ),
          VideoComponentConfig(
            videoFloatBuilder: () {},
            videoActionBuilder: () {},
          ),
          SetttingComponentConfig(),
          MemebersComponentConfig(),
        ],
      ),
    );
  }
}
