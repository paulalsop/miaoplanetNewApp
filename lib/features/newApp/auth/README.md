# 认证模块文档

本模块提供了应用的用户认证功能，包括登录和注册页面的实现。

## 组件结构

```
auth/
├── models/
│   └── auth_model.dart        # 认证相关模型和验证工具
├── screens/
│   ├── login_page.dart        # 登录页面
│   └── register_page.dart     # 注册页面
├── widgets/
│   └── auth_input_field.dart  # 通用的认证输入框组件
└── auth_routes.dart           # 认证路由方法
```

## 功能特点

1. **美观的UI设计**
   - 遵循设计图实现的全屏背景和UI元素
   - 优雅的输入框设计，带有图标和验证提示
   - 响应式布局适应不同尺寸的屏幕

2. **登录页面功能**
   - 账号输入（字符限制：8-20位）
   - 密码输入（字符限制：8-20位）
   - 密码显示/隐藏切换
   - 忘记密码链接
   - 注册页面跳转
   - 表单验证和错误提示

3. **注册页面功能**
   - 账号输入
   - 密码输入和确认
   - 邀请码输入（可选，根据后端要求）
   - 支持扩展邮箱验证码功能
   - 完整的表单验证
   - 注册提交按钮状态随表单有效性变化

4. **集成功能**
   - 与侧边栏菜单的退出登录功能集成
   - 简洁的路由管理，便于页面间导航

## 使用方法

### 打开登录页面

```dart
// 在需要打开登录页面的地方调用
AuthRoutes.openLoginPage(context);
```

### 打开注册页面

```dart
// 在需要打开注册页面的地方调用
AuthRoutes.openRegisterPage(context);

// 或者在登录页面直接导航到注册页面
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const RegisterPage(),
  ),
);
```

### 从侧边栏退出登录

侧边栏的退出登录按钮已经集成了打开登录页面的功能。点击退出登录按钮会触发以下操作：
1. 调用外部提供的退出登录回调（如有）
2. 关闭侧边栏
3. 打开登录页面

## 资源文件

此模块使用以下图片资源：

### 登录页面资源
- `bg_log in_bg.png` - 背景图片
- `bg_log in_card(white).png` - 输入框背景
- `ic_card_ Account.png` - 账号图标
- `ic_card_ lock.png` - 密码图标
- `ic_card_open.png` - 眼睛图标（显示/隐藏密码）
- `ic_Log in_quit.png` - 关闭按钮
- `btn_log in_log in.png` - 登录按钮

### 注册页面资源
- `bg_sign in_bg.png` - 背景图片
- `bg_sign in_card(white).png` - 输入框背景
- `ic_card_ Account.png` - 账号图标
- `ic_card_ lock.png` - 密码图标
- `ic_card_shield.png` - 邀请码图标
- `ic_Sign in_quit.png` - 关闭按钮
- `btn_sign in_Sign in.png` - 注册按钮 