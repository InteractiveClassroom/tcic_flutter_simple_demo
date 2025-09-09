import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:tcic_client_ui/utils/model/enum/role_enum.dart';
import 'package:tcic_flutter_simple_demo/api.dart';
import 'package:tcic_flutter_simple_demo/class_room.dart';
import 'package:url_launcher/url_launcher.dart';

/// 互动课堂配置向导页面
class ClassroomSetupWizardPage extends StatefulWidget {
  const ClassroomSetupWizardPage({Key? key}) : super(key: key);

  @override
  State<ClassroomSetupWizardPage> createState() => _ClassroomSetupWizardPageState();
}

class _ClassroomSetupWizardPageState extends State<ClassroomSetupWizardPage> {
  // 常量定义
  static const int _totalSteps = 3;
  static const String _documentationUrl = 
      'https://cloud.tencent.com/document/product/1639/79895#9b6257f6-95c7-4f5d-9eee-76edd86f80f7';

  // 当前步骤状态
  int _currentStepIndex = 0;

  // 表单控制器
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _secretIdController = TextEditingController();
  final TextEditingController _appIdController = TextEditingController();

  // 步骤完成状态
  final WizardStepStatus _stepStatus = WizardStepStatus();

  // 加载状态
  bool _isProcessing = false;

  // 用户和课堂信息
  ClassroomInfo? _classroomInfo;

  @override
  void dispose() {
    _secretKeyController.dispose();
    _secretIdController.dispose();
    _appIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('课堂配置向导'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        if (_currentStepIndex > 0 && !_isProcessing)
          IconButton(
            onPressed: _showResetConfirmDialog,
            icon: const Icon(Icons.refresh),
            tooltip: '重置到第一步',
          ),
      ],
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStepCircle(0, '配置参数', _stepStatus.isConfigurationCompleted),
          _buildStepConnector(_currentStepIndex > 0),
          _buildStepCircle(1, '创建课堂', _stepStatus.isClassroomCreated),
          _buildStepConnector(_currentStepIndex > 1),
          _buildStepCircle(2, '进入课堂', _stepStatus.isSetupCompleted),
        ],
      ),
    );
  }

  /// 构建步骤圆圈指示器
  Widget _buildStepCircle(int stepIndex, String title, bool isCompleted) {
    final bool isCurrentStep = _currentStepIndex == stepIndex;
    final bool isPassed = _currentStepIndex > stepIndex || isCompleted;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPassed
                ? Colors.green
                : isCurrentStep
                    ? Colors.blue
                    : Colors.grey[300],
          ),
          child: Icon(
            isPassed ? Icons.check : Icons.circle,
            color: isPassed || isCurrentStep ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isPassed || isCurrentStep ? Colors.black : Colors.grey[600],
            fontWeight: isPassed || isCurrentStep
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// 构建步骤连接线
  Widget _buildStepConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? Colors.green : Colors.grey[300],
      ),
    );
  }

  /// 构建当前步骤内容
  Widget _buildCurrentStepContent() {
    switch (_currentStepIndex) {
      case 0:
        return _buildConfigurationStep();
      case 1:
        return _buildClassroomCreationStep();
      case 2:
        return _buildEnterClassroomStep();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 第一步：参数配置
  Widget _buildConfigurationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle('步骤 1: 配置参数'),
        const SizedBox(height: 20),
        const Text('请从腾讯云控制台获取必要的信息并填写：', 
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),
        
        _buildConfigurationForm(),
        const SizedBox(height: 30),
        
        _buildActionButton(
          text: '创建用户',
          onPressed: _isProcessing ? null : _handleConfiguration,
          isLoading: _isProcessing,
        ),
        
        const SizedBox(height: 30),
        _buildDocumentationTip(),
      ],
    );
  }

  /// 构建配置表单
  Widget _buildConfigurationForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _secretKeyController,
          label: '腾讯云API Secret Key',
          icon: Icons.key,
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _secretIdController,
          label: '腾讯云API Secret ID',
          icon: Icons.perm_identity,
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _appIdController,
          label: '互动课堂 App ID',
          icon: Icons.apps,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  /// 构建文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  /// 第二步：创建课堂
  Widget _buildClassroomCreationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle('步骤 2: 创建课堂'),
        const SizedBox(height: 20),
        const Text('配置已完成，现在可以创建课堂。', 
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),

        _buildSuccessIndicator('用户已创建成功'),
        const SizedBox(height: 30),

        _buildActionRow(
          primaryAction: ActionButton(
            text: '创建课堂',
            onPressed: _isProcessing ? null : _handleClassroomCreation,
            isLoading: _isProcessing,
          ),
          secondaryAction: ActionButton(
            text: '重置',
            onPressed: _isProcessing ? null : _showResetConfirmDialog,
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  /// 第三步：进入课堂
  Widget _buildEnterClassroomStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle('步骤 3: 进入课堂'),
        const SizedBox(height: 20),
        const Text('课堂已创建成功，现在可以进入课堂。', 
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 30),

        _buildClassroomInfoCard(),
        const SizedBox(height: 30),

        _buildActionRow(
          primaryAction: ActionButton(
            text: '进入课堂',
            onPressed: _handleEnterClassroom,
          ),
          secondaryAction: ActionButton(
            text: '重置',
            onPressed: _showResetConfirmDialog,
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  /// 构建课堂信息卡片
  Widget _buildClassroomInfoCard() {
    final info = _classroomInfo;
    if (info == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoRow('配置信息已保存'),
          const SizedBox(height: 8),
          _buildInfoRow('用户创建成功 ${info.userId}'),
          const SizedBox(height: 8),
          _buildInfoRow('课堂创建成功 ${info.roomId}'),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  /// 构建成功指示器
  Widget _buildSuccessIndicator(String message) {
    return Container(
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
          Text(message),
        ],
      ),
    );
  }

  /// 构建文档提示
  Widget _buildDocumentationTip() {
    return Container(
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
                style: const TextStyle(color: Colors.black),
                children: [
                  const TextSpan(
                    text: '请注意腾讯云API的密钥等信息需根据业务放到您的服务端，避免泄漏。',
                  ),
                  TextSpan(
                    text: '点击查看文档',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = _openDocumentation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text),
      ),
    );
  }

  /// 构建操作按钮行
  Widget _buildActionRow({
    required ActionButton primaryAction,
    required ActionButton secondaryAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: primaryAction.isOutlined
                ? OutlinedButton(
                    onPressed: primaryAction.onPressed,
                    child: primaryAction.isLoading
                        ? const CircularProgressIndicator()
                        : Text(primaryAction.text),
                  )
                : ElevatedButton(
                    onPressed: primaryAction.onPressed,
                    child: primaryAction.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(primaryAction.text),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 50,
          child: secondaryAction.isOutlined
              ? OutlinedButton(
                  onPressed: secondaryAction.onPressed,
                  child: Text(secondaryAction.text),
                )
              : ElevatedButton(
                  onPressed: secondaryAction.onPressed,
                  child: Text(secondaryAction.text),
                ),
        ),
      ],
    );
  }

  // ==================== 业务逻辑方法 ====================

  /// 处理配置步骤
  Future<void> _handleConfiguration() async {
    if (!_validateConfigurationInputs()) return;

    await _executeWithLoading(() async {
      _configureApiClient();
      final response = await TCICCloudApi.registerUser();
      
      if (_hasApiError(response)) {
        _showErrorMessage('注册失败，${_getErrorMessage(response)}');
        return;
      }

      _handleConfigurationSuccess(response);
    });
  }

  /// 处理课堂创建
  Future<void> _handleClassroomCreation() async {
    final info = _classroomInfo;
    if (info == null) return;

    await _executeWithLoading(() async {
      final response = await TCICCloudApi.createRoom(teacherId: info.userId);
      
      if (_hasApiError(response)) {
        _showErrorMessage('创建课堂失败，${_getErrorMessage(response)}');
        return;
      }

      _handleClassroomCreationSuccess(response);
    });
  }

  /// 处理进入课堂
  void _handleEnterClassroom() {
    final info = _classroomInfo;
    if (info == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassRoom(
          userId: info.userId,
          token: info.token,
          classId: info.roomId.toString(),
          role: RoleEnum.teacher,
        ),
      ),
    );
  }

  /// 显示重置确认对话框
  void _showResetConfirmDialog() {
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
                _resetWizard();
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// 重置向导
  void _resetWizard() {
    setState(() {
      _currentStepIndex = 0;
      _stepStatus.reset();
      _isProcessing = false;
      _classroomInfo = null;

      // 清空表单
      _secretKeyController.clear();
      _secretIdController.clear();
      _appIdController.clear();
    });

    _showSuccessMessage('已重置到第一步');
  }

  // ==================== 辅助方法 ====================

  /// 验证配置输入
  bool _validateConfigurationInputs() {
    if (_secretKeyController.text.isEmpty ||
        _secretIdController.text.isEmpty ||
        _appIdController.text.isEmpty) {
      _showErrorMessage('请填写完整的配置信息');
      return false;
    }
    return true;
  }

  /// 配置API客户端
  void _configureApiClient() {
    TCICCloudApi.setConfig(
      secretId: _secretIdController.text,
      secretKey: _secretKeyController.text,
      appId: int.parse(_appIdController.text),
    );
  }

  /// 处理配置成功
  void _handleConfigurationSuccess(Map<String, dynamic> response) {
    final responseInfo = response["Response"];
    
    setState(() {
      _stepStatus.isConfigurationCompleted = true;
      _currentStepIndex = 1;
      _classroomInfo = ClassroomInfo(
        userId: responseInfo['UserId'],
        token: responseInfo['Token'],
        roomId: 0,
      );
    });

    _showSuccessMessage('用户注册成功!');
  }

  /// 处理课堂创建成功
  void _handleClassroomCreationSuccess(Map<String, dynamic> response) {
    final responseInfo = response["Response"];
    
    setState(() {
      _stepStatus.isClassroomCreated = true;
      _currentStepIndex = 2;
      _classroomInfo = _classroomInfo?.copyWith(
        roomId: responseInfo['RoomId'],
      );
    });

    _showSuccessMessage('课堂创建成功！');
  }

  /// 执行带加载状态的操作
  Future<void> _executeWithLoading(Future<void> Function() operation) async {
    setState(() => _isProcessing = true);
    try {
      await operation();
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// 检查API错误
  bool _hasApiError(Map<String, dynamic> response) {
    return response["Response"]["Error"] != null;
  }

  /// 获取错误消息
  String _getErrorMessage(Map<String, dynamic> response) {
    return response["Response"]["Error"]["Message"] ?? '未知错误';
  }

  /// 显示错误消息
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 显示成功消息
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 打开文档
  Future<void> _openDocumentation() async {
    final url = Uri.parse(_documentationUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

// ==================== 数据模型 ====================

/// 向导步骤状态
class WizardStepStatus {
  bool isConfigurationCompleted = false;
  bool isClassroomCreated = false;
  bool isSetupCompleted = false;

  void reset() {
    isConfigurationCompleted = false;
    isClassroomCreated = false;
    isSetupCompleted = false;
  }
}

/// 课堂信息
class ClassroomInfo {
  final String userId;
  final String token;
  final int roomId;

  const ClassroomInfo({
    required this.userId,
    required this.token,
    required this.roomId,
  });

  ClassroomInfo copyWith({
    String? userId,
    String? token,
    int? roomId,
  }) {
    return ClassroomInfo(
      userId: userId ?? this.userId,
      token: token ?? this.token,
      roomId: roomId ?? this.roomId,
    );
  }
}

/// 操作按钮配置
class ActionButton {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const ActionButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });
}

// ==================== UI 组件 ====================

/// 步骤标题组件
class StepTitle extends StatelessWidget {
  final String title;

  const StepTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}