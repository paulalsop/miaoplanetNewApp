import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../../panel/xboard/services/http_service/user_service.dart';
import '../../../panel/xboard/services/http_service/invite_code_service.dart';
import '../../../panel/xboard/utils/storage/token_storage.dart';

/// 推荐人信息页面
///
/// 用户可以在此页面查看推荐人信息或绑定推荐人
class ReferrerInfoPage extends StatefulWidget {
  const ReferrerInfoPage({Key? key}) : super(key: key);

  @override
  State<ReferrerInfoPage> createState() => _ReferrerInfoPageState();
}

class _ReferrerInfoPageState extends State<ReferrerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _userService = UserService();
  final _inviteCodeService = InviteCodeService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _bindSuccess = false;

  // 推荐人状态
  bool _hasInviter = false;
  Map<String, dynamic>? _inviterInfo;

  @override
  void initState() {
    super.initState();
    _loadInviterStatus();
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  // 加载推荐人状态
  Future<void> _loadInviterStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await getToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '请先登录';
        });
        return;
      }

      final result = await _inviteCodeService.getInviteStatus(token);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            _hasInviter = result['hasInviter'] == true;
            _inviterInfo = result['inviterInfo'] as Map<String, dynamic>?;
          } else {
            _errorMessage = result['message']?.toString() ?? '获取推荐人状态失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '获取推荐人状态失败: $e';
        });
      }
    }
  }

  // 处理绑定推荐人操作
  Future<void> _handleBindInviteCode() async {
    // 关闭键盘
    FocusScope.of(context).unfocus();

    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final inviteCode = _inviteCodeController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _bindSuccess = false;
    });

    try {
      final token = await getToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '请先登录';
        });
        return;
      }

      final result = await _userService.bindInviteCode(inviteCode, token);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            _bindSuccess = true;
            // 绑定成功后重新加载推荐人状态
            _loadInviterStatus();
          } else {
            _errorMessage = result['message']?.toString() ?? '绑定失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '绑定失败: $e';
        });
      }
    }
  }

  // 处理粘贴邀请码
  Future<void> _handlePasteInviteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    if (text != null && text.isNotEmpty) {
      setState(() {
        _inviteCodeController.text = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxDialogHeight = screenSize.height * 0.85;
    final maxDialogWidth = screenSize.width * 0.9;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxDialogHeight,
            maxWidth: maxDialogWidth,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : SingleChildScrollView(
                  child: _buildCard(),
                ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 400 ? screenWidth * 0.85 : 320.0;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00796B),
            const Color(0xFF004D40),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF00897B),
                    const Color(0xFF00695C),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hasInviter ? '推荐人信息' : '绑定推荐人',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 内容区域
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _hasInviter
                      ? _buildInviterInfoView()
                      : _bindSuccess
                          ? _buildSuccessContent()
                          : _buildBindForm(),
            ),
          ],
        ),
      ),
    );
  }

  // 显示错误信息
  Widget _buildErrorView() {
    return Column(
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.amber,
          size: 56,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? '发生错误',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loadInviterStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF00796B),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('重新加载'),
        ),
      ],
    );
  }

  // 显示推荐人信息
  Widget _buildInviterInfoView() {
    final inviterEmail = _inviterInfo?['email']?.toString() ?? '未知';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person_pin_circle,
          color: Colors.white,
          size: 56,
        ),
        const SizedBox(height: 16),
        const Text(
          '您的推荐人',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inviterEmail,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '您已成功绑定推荐人，推荐关系不可更改',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF00796B),
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  // 绑定成功后显示的内容
  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 56,
        ),
        const SizedBox(height: 12),
        const Text(
          '绑定成功',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '您已成功绑定推荐人',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF00796B),
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('完成'),
        ),
      ],
    );
  }

  // 绑定表单
  Widget _buildBindForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标
          Center(
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          // 说明文字
          const Text(
            '输入您的推荐人邀请码，将与该推荐人建立关联。',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // 邀请码输入框
          TextFormField(
            controller: _inviteCodeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '推荐人邀请码',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: '请输入推荐人邀请码',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste, color: Colors.white70),
                tooltip: '粘贴',
                onPressed: _handlePasteInviteCode,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入推荐人邀请码';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // 绑定按钮
          ElevatedButton(
            onPressed: _isLoading ? null : _handleBindInviteCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00796B),
              disabledBackgroundColor: Colors.white.withOpacity(0.5),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
                    ),
                  )
                : const Text('绑定推荐人'),
          ),

          // 提示文本
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '绑定后无法更改，请确保输入正确的邀请码',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
