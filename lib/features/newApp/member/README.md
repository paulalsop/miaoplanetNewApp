# 会员订购页面

本模块提供了VPN应用的会员订购功能，包括普通会员和股东会员两种类型的订购界面。

## 组件结构

```
member/
├── models/
│   └── membership_model.dart     # 会员类型和套餐模型
├── screens/
│   └── membership_page.dart      # 会员订购页面
├── widgets/
│   ├── membership_header.dart    # 会员信息头部组件
│   ├── membership_plan_item.dart # 会员套餐选择项组件
│   ├── membership_type_tabs.dart # 会员类型切换标签组件
│   └── subscription_button.dart  # 订阅提交按钮组件
└── member_routes.dart            # 会员页面路由和导航方法
```

## 功能特点

1. 完整的会员订购界面，包括普通会员和股东会员两种类型
2. 普通会员支持选择不同时长套餐（1个月、3个月、6个月、1年）
3. 股东会员提供终身会员方案
4. 支持在普通会员和股东会员之间切换
5. 按钮状态根据选中情况动态变化
6. 与主页集成，点击主页上的会员图标可打开会员订购页面

## 使用方法

### 打开会员页面（普通会员）

```dart
MemberRoutes.openMembershipPage(context);
```

### 打开会员页面（股东会员）

```dart
MemberRoutes.openMembershipPage(
  context, 
  initialType: MembershipType.shareholder,
);
```

## 资源文件

此模块使用以下图片资源：

### 普通会员资源
- `bg_vip_bg.png` - 背景图片
- `btn_vip_btn(green).png` - 选中套餐的背景
- `btn_vip_btn(white).png` - 未选中套餐背景
- `ic_btn green_Select.png` - 选中套餐的右边的圆
- `ic_btn white_normal.png` - 未选中套餐的圆
- `btn_vip_Start.png` - 提交按钮背景
- `pic_vip_badge.png` - 普通会员的身份图标
- `ic_vip_quit.png` - 关闭按钮图标

### 股东会员资源
- `bg_stockholder_bg.png` - 背景图片
- `btn_stockholder_btn(green).png` - 套餐背景
- `btn_stockholder_start.png` - 提交按钮背景
- `ic_btn green_Select.png` - 选中的右边图标
- `pic_stockholder_badge.png` - 股东身份图标
- `ic_stockholder_quit.png` - 关闭按钮图标 