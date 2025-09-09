import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:tcic_client_ui/utils/model/enum/role_enum.dart';
import 'package:tcic_flutter_simple_demo/api.dart';
import 'package:tcic_flutter_simple_demo/class_room.dart';
import 'package:tcic_flutter_simple_demo/request.dart';
import 'package:url_launcher/url_launcher.dart';

class StepConfigPage extends StatefulWidget {
  const StepConfigPage({Key? key}) : super(key: key);

  @override
  State<StepConfigPage> createState() => _StepConfigPageState();
}

class _StepConfigPageState extends State<StepConfigPage> {
  int currentStep = 0;

  // 第一步的表单控制器
  final TextEditingController secretKeyController = TextEditingController();
  final TextEditingController secretIdController = TextEditingController();
  final TextEditingController appIdController = TextEditingController();

  // 状态变量
  bool isConfigCompleted = false;
  bool isUserCreated = false;
  bool isClassroomCreated = false;
  bool isLoading = false;

  // 用户注册后的信息
  String userId = '';
  String token = '';
  int roomId = 0;

  @override
  void dispose() {
    secretKeyController.dispose();
    secretIdController.dispose();
    appIdController.dispose();
    super.dispose();
  }

  // 重置所有状态
  void resetAllSteps() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认重置'),
          content: const Text('这将清除所有配置信息并返回到第一步，确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performReset();
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _performReset() {
    setState(() {
      currentStep = 0;
      isConfigCompleted = false;
      isUserCreated = false;
      isClassroomCreated = false;
      isLoading = false;

      // 清空表单
      secretKeyController.clear();
      secretIdController.clear();
      appIdController.clear();

      // 清空用户注册后的信息
      userId = '';
      token = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已重置到第一步'), backgroundColor: Colors.orange),
    );
  }

  // 配置完成
  Future<void> completeConfiguration() async {
    if (secretKeyController.text.isEmpty ||
        secretIdController.text.isEmpty ||
        appIdController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写完整的配置信息')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    // 配置请求
    TCICCloudApi.setConfig(
      secretId: secretIdController.text,
      secretKey: secretKeyController.text,
      appId: int.parse(appIdController.text),
    );

    final response = await TCICCloudApi.registerUser();
    final responseInfo = response["Response"];
    final errorInfo = responseInfo["Error"];
    if (errorInfo != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('注册失败，${errorInfo["Message"]}')));
      setState(() {
        isLoading = false;
      });
      return;
    } else {
      setState(() {
        isConfigCompleted = true;
        currentStep = 1;
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('用户注册成功!')));
      userId = responseInfo['UserId'];
      token = responseInfo['Token'];
    }
  }

  // 创建用户
  Future<void> createUser() async {
    setState(() {
      isLoading = true;
    });

    final response = await TCICCloudApi.createRoom(teacherId: userId);
    final responseInfo = response["Response"];
    final errorInfo = responseInfo["Error"];
    if (errorInfo != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建课堂失败，${errorInfo["Message"]}')));
      setState(() {
        isLoading = false;
      });
      return;
    } else {
      print("【【【【responseInfo】】】】$responseInfo");
      setState(() {
        isUserCreated = true;
        currentStep = 2;
        roomId = responseInfo['RoomId'];
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('课堂创建成功！')));
    }
  }

  // 创建课堂
  Future<void> enterClassRoom() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassRoom(
          userId: userId,
          token: token,
          classId: roomId.toString(),
          role: RoleEnum.teacher,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置向导'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 重置按钮 - 只在不是第一步且不在加载时显示
          if (currentStep > 0 && !isLoading)
            IconButton(
              onPressed: resetAllSteps,
              icon: const Icon(Icons.refresh),
              tooltip: '重置到第一步',
            ),
        ],
      ),
      body: Column(
        children: [
          // 步骤指示器
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStepIndicator(0, '创建用户', isConfigCompleted),
                Expanded(child: _buildStepLine(currentStep > 0)),
                _buildStepIndicator(1, '创建课堂', isUserCreated),
                Expanded(child: _buildStepLine(currentStep > 1)),
                _buildStepIndicator(2, '进入课堂', isClassroomCreated),
              ],
            ),
          ),

          // 内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  // 步骤指示器
  Widget _buildStepIndicator(int step, String title, bool completed) {
    bool isActive = currentStep == step;
    bool isPassed = currentStep > step || completed;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPassed
                ? Colors.green
                : isActive
                ? Colors.blue
                : Colors.grey[300],
          ),
          child: Icon(
            isPassed ? Icons.check : Icons.circle,
            color: isPassed || isActive ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isPassed || isActive ? Colors.black : Colors.grey[600],
            fontWeight: isPassed || isActive
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // 步骤连接线
  Widget _buildStepLine(bool isCompleted) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: isCompleted ? Colors.green : Colors.grey[300],
    );
  }

  // 步骤内容
  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildConfigurationStep();
      case 1:
        return _buildUserCreationStep();
      case 2:
        return _buildClassroomCreationStep();
      default:
        return const SizedBox();
    }
  }

  // 第一步：配置
  Widget _buildConfigurationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '步骤 1: 创建用户',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text('请从控制台获取必要的信息并填写：', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),

        TextField(
          controller: secretKeyController,
          decoration: const InputDecoration(
            labelText: '腾讯云API Secret Key',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.key),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: secretIdController,
          decoration: const InputDecoration(
            labelText: '腾讯云API Secret ID',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.perm_identity),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: appIdController,
          decoration: const InputDecoration(
            labelText: '互动课堂 App ID',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.apps),
          ),
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : completeConfiguration,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('创建用户'),
          ),
        ),

        ...[
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(
                          text: '该步骤为配置腾讯云API调用所必须的参数，配置完成后才能创建用户，创建课堂等。',
                        ),
                        TextSpan(
                          text: '点击查看文档',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final url = Uri.parse(
                                'https://cloud.tencent.com/document/product/1639/79895#9b6257f6-95c7-4f5d-9eee-76edd86f80f7',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 第二步：创建用户
  Widget _buildUserCreationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '步骤 2: 创建课堂',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text('配置已完成，现在可以创建课堂。', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600]),
              const SizedBox(width: 12),
              const Text('用户已创建成功'),
            ],
          ),
        ),
        const SizedBox(height: 30),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createUser,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('创建课堂'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: isLoading ? null : resetAllSteps,
                child: const Text('重置'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 第三步：创建课堂
  Widget _buildClassroomCreationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '步骤 3: 进入课堂',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text('课堂已创建成功，现在可以进入课堂。', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  const Text('配置信息已保存'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  Expanded(child: Text('用户创建成功 $userId', overflow: TextOverflow.ellipsis,)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  Text('课堂创建成功 $roomId'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: enterClassRoom,
                  child: const Text('进入课堂'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: resetAllSteps,
                child: const Text('重置'),
              ),
            ),
          ],
        ),

        if (isClassroomCreated) ...[
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    const Text('所有步骤已完成！'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: resetAllSteps,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新开始配置'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
