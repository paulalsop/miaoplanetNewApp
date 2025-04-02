import 'package:flutter/material.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户协议'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '''
用户协议内容将在这里显示。

1. 服务条款
...

2. 隐私政策
...

3. 用户责任
...
          ''',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
