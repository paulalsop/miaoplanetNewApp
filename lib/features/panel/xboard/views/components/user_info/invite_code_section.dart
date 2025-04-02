// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/invite_code_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/newApp/user/screens/referrer_info_page.dart';
import 'package:hiddify/features/newApp/auth/services/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InviteCodeSection extends ConsumerWidget {
  const InviteCodeSection({super.key});

  // 显示绑定推荐人页面
  void _showReferrerBindingPage(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭推荐人绑定',
      barrierColor: Colors.black.withOpacity(0.75),
      pageBuilder: (context, animation1, animation2) =>
          const ReferrerInfoPage(),
      transitionBuilder: (context, animation1, animation2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation1,
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  // 显示未绑定推荐人提示
  Widget _buildNoReferrerView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_add_alt_1_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '您未绑定推荐人，无法查看推荐码',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showReferrerBindingPage(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('立即绑定推荐人'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateInviteCode(BuildContext context, WidgetRef ref) async {
    final t = ref.watch(translationsProvider);
    final accessToken = await getToken();
    if (accessToken == null) {
      _showSnackbar(context, t.userInfo.noAccessToken);
      return;
    }

    try {
      final result = await InviteCodeService().generateInviteCode(accessToken);

      if (result['success'] == true) {
        _showSnackbar(context, t.inviteCode.generateInviteCode);
        // ignore: unused_result
        ref.refresh(inviteCodesProvider);
      } else {
        // 如果需要绑定推荐人
        if (result['needBindInviter'] == true) {
          // 显示对话框
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('需要绑定推荐人'),
                content: const Text('生成邀请码前需要先绑定推荐人，是否现在去绑定？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // 关闭对话框
                      _showReferrerBindingPage(context);
                    },
                    child: const Text('去绑定'),
                  ),
                ],
              ),
            );
          }
        } else {
          _showSnackbar(
              context,
              result['message']?.toString() ??
                  t.inviteCode.inviteCodeGenerateError);
        }
      }
    } catch (e) {
      _showSnackbar(context, "${t.inviteCode.inviteCodeGenerateError}: $e");
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.inviteCode.inviteCodeListTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateInviteCode(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(t.inviteCode.generateInviteCode),
                ),
              ],
            ),
            const Divider(),
            Consumer(
              builder: (context, ref, child) {
                final inviteCodesAsync = ref.watch(inviteCodesProvider);

                return inviteCodesAsync.when(
                  data: (inviteCodes) {
                    // 先检查是否有推荐人
                    return FutureBuilder<Map<String, dynamic>>(
                      future: InviteCodeService()
                          .getInviteStatus(AuthService.instance.token ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasData &&
                            snapshot.data?['hasInviter'] == true) {
                          // 有推荐人，显示邀请码列表
                          if (inviteCodes.isEmpty) {
                            return Center(
                                child: Text(t.inviteCode.noInviteCodes));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: inviteCodes.length,
                            itemBuilder: (context, index) {
                              final inviteCode = inviteCodes[index];
                              final fullInviteLink = InviteCodeService()
                                  .getInviteLink(inviteCode.code);
                              return ListTile(
                                title: Text(inviteCode.code),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: fullInviteLink),
                                    );
                                    _showSnackbar(
                                      context,
                                      '${t.inviteCode.copiedInviteCode} $fullInviteLink',
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        } else {
                          // 没有推荐人，显示提示信息
                          return _buildNoReferrerView(context);
                        }
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('${t.inviteCode.fetchInviteCodesError} $error'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
