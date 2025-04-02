import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../../../panel/xboard/services/http_service/user_service.dart';
import '../../../panel/xboard/utils/storage/token_storage.dart';

/// BSC地址页面
///
/// 用户可以在此页面查看或绑定BSC钱包地址
class BscAddressPage extends StatefulWidget {
  const BscAddressPage({Key? key}) : super(key: key);

  @override
  State<BscAddressPage> createState() => _BscAddressPageState();
}

class _BscAddressPageState extends State<BscAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _bscAddressController = TextEditingController();
  final _userService = UserService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _updateSuccess = false;

  // BSC地址状态
  bool _hasBscAddress = false;
  String? _bscAddress;

  @override
  void initState() {
    super.initState();
    _loadBscAddress();
  }

  @override
  void dispose() {
    _bscAddressController.dispose();
    super.dispose();
  }

  // 加载BSC地址
  Future<void> _loadBscAddress() async {
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

      final result = await _userService.getBscAddress(token);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            _bscAddress = result['bscAddress']?.toString();
            _hasBscAddress = _bscAddress != null && _bscAddress!.isNotEmpty;
          } else {
            _errorMessage = result['message']?.toString() ?? '获取BSC地址失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '获取BSC地址失败: $e';
        });
      }
    }
  }

  // 处理更新BSC地址操作
  Future<void> _handleUpdateBscAddress() async {
    // 关闭键盘
    FocusScope.of(context).unfocus();

    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bscAddress = _bscAddressController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _updateSuccess = false;
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

      final result = await _userService.updateBscAddress(bscAddress, token);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            _updateSuccess = true;
            // 更新成功后重新加载BSC地址
            _loadBscAddress();
          } else {
            _errorMessage = result['message']?.toString() ?? '更新BSC地址失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '更新BSC地址失败: $e';
        });
      }
    }
  }

  // 处理粘贴BSC地址
  Future<void> _handlePasteBscAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    if (text != null && text.isNotEmpty) {
      setState(() {
        _bscAddressController.text = text;
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
            const Color(0xFF9C27B0),
            const Color(0xFF6A1B9A),
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
                    const Color(0xFFAB47BC),
                    const Color(0xFF8E24AA),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hasBscAddress ? 'BSC钱包地址' : '绑定BSC地址',
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
                  : _hasBscAddress
                      ? _buildBscAddressInfoView()
                      : _updateSuccess
                          ? _buildSuccessContent()
                          : _buildUpdateForm(),
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
          onPressed: _loadBscAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF9C27B0),
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('重新加载'),
        ),
      ],
    );
  }

  // 显示BSC地址信息
  Widget _buildBscAddressInfoView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 56,
        ),
        const SizedBox(height: 16),
        const Text(
          '您的BSC钱包地址',
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
                  const Icon(Icons.token, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bscAddress ?? '未知',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 复制按钮
              OutlinedButton.icon(
                onPressed: () {
                  if (_bscAddress != null) {
                    Clipboard.setData(ClipboardData(text: _bscAddress!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('BSC地址已复制到剪贴板'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制地址'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
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
                  '您已成功绑定BSC地址，该地址用于接收平台奖励',
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
        // 修改按钮
        TextButton(
          onPressed: () {
            setState(() {
              _hasBscAddress = false;
              if (_bscAddress != null) {
                _bscAddressController.text = _bscAddress!;
              }
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: const Text('修改地址'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF9C27B0),
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

  // 更新成功后显示的内容
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
          '您已成功绑定BSC钱包地址',
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
            foregroundColor: const Color(0xFF9C27B0),
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

  // 更新表单
  Widget _buildUpdateForm() {
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
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          // 说明文字
          const Text(
            '输入您的BSC钱包地址，用于接收平台奖励。',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // BSC地址输入框
          TextFormField(
            controller: _bscAddressController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'BSC钱包地址',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: '请输入BSC钱包地址',
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
                onPressed: _handlePasteBscAddress,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入BSC钱包地址';
              }
              // 简单验证是否为有效的BSC地址（以0x开头的42位十六进制字符串）
              if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(value)) {
                return '请输入有效的BSC钱包地址';
              }
              return null;
            },
            maxLines: 2,
            minLines: 1,
          ),

          const SizedBox(height: 24),

          // 确认按钮
          ElevatedButton(
            onPressed: _isLoading ? null : _handleUpdateBscAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF9C27B0),
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
                          AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                    ),
                  )
                : const Text('确认绑定'),
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
                    '请确保输入正确的BSC钱包地址，错误的地址可能导致无法收到奖励',
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
