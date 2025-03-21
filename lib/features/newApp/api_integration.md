# Hiddify 应用API接口对接文档

## 1. 概述

本文档详细描述了Hiddify应用中所有现有API接口，包括接口路径、参数、返回值格式和调用方式。这些接口将作为新版UI界面与后端系统对接的依据。

## 2. 基础架构

### 2.1 基础URL获取机制

应用通过`DomainService`类动态获取有效的服务器域名:
**源文件:** `lib/features/panel/xboard/services/http_service/domain_service.dart`

```dart
// 负责动态获取可用域名
class DomainService {
  static const String ossDomain = 'https://s3.ap-southeast-1.amazonaws.com/808676.tigerskombat.com/config.json';

  static Future<String> fetchValidDomain() async {
    // 从远程服务获取有效域名列表
    // 尝试连接各个域名并返回第一个可成功连接的域名
  }
}
```

### 2.2 HTTP客户端实现

所有API请求通过`HttpService`类进行封装:
**源文件:** `lib/features/panel/xboard/services/http_service/http_service.dart`

```dart
class HttpService {
  static String baseUrl = ''; // 从DomainService获取
  
  // 初始化服务
  static Future<void> initialize() async {
    baseUrl = await DomainService.fetchValidDomain();
  }
  
  // GET请求方法
  Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, String>? headers});
  
  // POST请求方法
  Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool requiresHeaders = true,
  });
}
```

### 2.3 认证机制

大多数API需要在请求头中包含`Authorization`令牌:

```
headers: {'Authorization': accessToken}
```

## 3. API分类

### 3.1 认证相关API (Auth)
**实现文件:** `lib/features/panel/xboard/services/http_service/auth_service.dart`

#### 3.1.1 登录

- **路径**: `/api/v1/passport/auth/login`
- **方法**: POST
- **描述**: 用户登录并获取访问令牌
- **实现方法**: `AuthService.login(String email, String password)`
- **请求体**:
```json
{
  "email": "用户邮箱",
  "password": "用户密码"
}
```
- **请求头**: `{'Content-Type': 'application/json'}`
- **响应**:
```json
{
  "status": "success",
  "data": {
    "token": "访问令牌",
    "user_info": { ... } // 用户信息
  }
}
```

#### 3.1.2 注册

- **路径**: `/api/v1/passport/auth/register`
- **方法**: POST
- **描述**: 用户注册新账号
- **实现方法**: `AuthService.register(String email, String password, String inviteCode, String emailCode)`
- **请求体**:
```json
{
  "email": "用户邮箱",
  "password": "用户密码",
  "invite_code": "邀请码",
  "email_code": "邮箱验证码"
}
```
- **响应**: 类似登录接口

#### 3.1.3 发送验证码

- **路径**: `/api/v1/passport/comm/sendEmailVerify`
- **方法**: POST
- **描述**: 向邮箱发送验证码
- **实现方法**: `AuthService.sendVerificationCode(String email)`
- **请求体**:
```json
{
  "email": "用户邮箱"
}
```
- **响应**:
```json
{
  "status": "success",
  "message": "验证码已发送"
}
```

#### 3.1.4 重置密码

- **路径**: `/api/v1/passport/auth/forget`
- **方法**: POST
- **描述**: 重置账号密码
- **实现方法**: `AuthService.resetPassword(String email, String password, String emailCode)`
- **请求体**:
```json
{
  "email": "用户邮箱",
  "password": "新密码",
  "email_code": "邮箱验证码"
}
```

### 3.2 用户信息相关API (User)
**实现文件:** `lib/features/panel/xboard/services/http_service/user_service.dart`

#### 3.2.1 获取用户信息

- **路径**: `/api/v1/user/info`
- **方法**: GET
- **描述**: 获取当前用户的详细信息
- **实现方法**: `UserService.getUserInfo()`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": {
    "email": "用户邮箱",
    "transfer_enable": 数值型流量限制,
    "last_login_at": 上次登录时间戳,
    "created_at": 创建时间戳,
    "banned": 是否被封禁(0/1),
    "remind_expire": 是否提醒过期(0/1),
    "remind_traffic": 是否提醒流量(0/1),
    "expired_at": 过期时间戳,
    "balance": 余额,
    "commission_balance": 佣金余额,
    "plan_id": 套餐ID,
    "discount": 折扣,
    "commission_rate": 佣金比例,
    "telegram_id": "Telegram ID",
    "uuid": "用户UUID",
    "avatar_url": "头像URL"
  }
}
```

#### 3.2.2 获取订阅链接

- **路径**: `/api/v1/user/getSubscribe`
- **方法**: GET
- **描述**: 获取用户的服务订阅链接
- **实现方法**: `SubscriptionService.getSubscription()`
- **实现文件**: `lib/features/panel/xboard/services/http_service/subscription_service.dart`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": {
    "subscribe_url": "订阅URL"
  }
}
```

#### 3.2.3 重置安全信息

- **路径**: `/api/v1/user/resetSecurity`
- **方法**: GET
- **描述**: 重置用户安全信息，获取新的订阅链接
- **实现方法**: `UserService.resetSecurity()`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": "新的订阅链接"
}
```

### 3.3 邀请码相关API (Invitation)
**实现文件:** `lib/features/panel/xboard/services/http_service/invite_code_service.dart`

#### 3.3.1 生成邀请码

- **路径**: `/api/v1/user/invite/save`
- **方法**: GET
- **描述**: 生成新的邀请码
- **实现方法**: `InviteCodeService.generateInviteCode()`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success"
}
```

#### 3.3.2 获取邀请码列表

- **路径**: `/api/v1/user/invite/fetch`
- **方法**: GET
- **描述**: 获取用户的邀请码列表
- **实现方法**: `InviteCodeService.getInviteCodes()`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": {
    "codes": [
      {"code": "邀请码1"},
      {"code": "邀请码2"}
    ]
  }
}
```

### 3.4 套餐相关API (Plan)
**实现文件:** `lib/features/panel/xboard/services/http_service/plan_service.dart`

#### 3.4.1 获取套餐列表

- **路径**: `/api/v1/user/plan/fetch`
- **方法**: GET
- **描述**: 获取所有可用套餐信息
- **实现方法**: `PlanService.getPlans()`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": [
    {
      "id": 套餐ID,
      "group_id": 分组ID,
      "transfer_enable": 流量限制,
      "name": "套餐名称",
      "speed_limit": 速度限制,
      "show": 是否显示(0/1),
      "content": "套餐说明内容",
      "onetime_price": 一次性价格,
      "month_price": 月度价格,
      "quarter_price": 季度价格,
      "half_year_price": 半年价格,
      "year_price": 年度价格,
      "two_year_price": 两年价格,
      "three_year_price": 三年价格,
      "created_at": 创建时间戳,
      "updated_at": 更新时间戳
    }
  ]
}
```

### 3.5 订单相关API (Order)
**实现文件:** `lib/features/panel/xboard/services/http_service/order_service.dart`

#### 3.5.1 获取订单列表

- **路径**: `/api/v1/user/order/fetch`
- **方法**: GET
- **描述**: 获取用户的订单列表
- **实现方法**: `OrderService.getOrders()`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": [
    {
      "plan_id": 套餐ID,
      "trade_no": "订单号",
      "total_amount": 订单金额,
      "period": "订购周期",
      "status": 订单状态码,
      "created_at": 创建时间戳,
      "plan": {
        "id": 套餐ID,
        "name": "套餐名称",
        "onetime_price": 一次性价格,
        "content": "套餐内容"
      }
    }
  ]
}
```

#### 3.5.2 获取订单详情

- **路径**: `/api/v1/user/order/detail?trade_no=订单号`
- **方法**: GET
- **描述**: 获取指定订单的详细信息
- **实现方法**: `OrderService.getOrderDetails(String tradeNo)`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": {
    // 订单详细信息
  }
}
```

#### 3.5.3 取消订单

- **路径**: `/api/v1/user/order/cancel`
- **方法**: POST
- **描述**: 取消指定订单
- **实现方法**: `OrderService.cancelOrder(String tradeNo)`
- **请求体**:
```json
{
  "trade_no": "订单号"
}
```
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success"
}
```

#### 3.5.4 创建订单

- **路径**: `/api/v1/user/order/save`
- **方法**: POST
- **描述**: 创建新订单
- **实现方法**: `OrderService.createOrder(int planId, String period)`
- **请求体**:
```json
{
  "plan_id": 套餐ID,
  "period": "订购周期"
}
```
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": {
    "trade_no": "订单号",
    // 其他订单信息
  }
}
```

### 3.6 支付相关API (Payment)
**实现文件:** `lib/features/panel/xboard/services/http_service/payment_service.dart`

#### 3.6.1 提交支付

- **路径**: `/api/v1/user/order/checkout`
- **方法**: POST
- **描述**: 提交订单进行支付
- **实现方法**: `PaymentService.checkout(String tradeNo, String method)`
- **请求体**:
```json
{
  "trade_no": "订单号",
  "method": "支付方式"
}
```
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": {
    // 支付相关信息
  }
}
```

#### 3.6.2 获取支付方式

- **路径**: `/api/v1/user/order/getPaymentMethod`
- **方法**: GET
- **描述**: 获取所有可用支付方式
- **实现方法**: `PaymentService.getPaymentMethods()`
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success",
  "data": [
    // 支付方式列表
  ]
}
```

### 3.7 余额相关API (Balance)
**实现文件:** `lib/features/panel/xboard/services/http_service/balance.service.dart`

#### 3.7.1 佣金转余额

- **路径**: `/api/v1/user/transfer`
- **方法**: POST
- **描述**: 将佣金转入余额
- **实现方法**: `BalanceService.transferCommission(double amount)`
- **请求体**:
```json
{
  "transfer_amount": 转移金额
}
```
- **请求头**: `{'Authorization': accessToken}`
- **响应**:
```json
{
  "status": "success"
}
```

## 4. 响应格式

大多数API响应遵循以下格式:

```json
{
  "status": "success" | "error",
  "message": "消息内容(可选)",
  "data": 响应数据(可选)
}
```

## 5. 错误处理

API返回非200状态码时，响应通常包含错误信息:

```json
{
  "status": "error",
  "message": "错误描述"
}
```

## 6. 新版UI对接建议

1. **认证流程**:
   - 使用`AuthService`管理登录状态和token
   - 通过`SharedPreferences`存储token
   - 添加Token自动刷新机制

2. **数据模型**:
   - 为每个响应创建对应的数据模型类
   - 实现`fromJson`和`toJson`方法
   - 处理可能的null值和类型转换

3. **服务层设计**:
   - 采用Repository模式分离数据源和业务逻辑
   - 使用单例模式实现服务类
   - 实现错误处理和重试机制

4. **UI层对接**:
   - 使用异步加载显示加载指示器
   - 实现下拉刷新和分页加载
   - 统一错误处理和提示

## 7. 对接步骤

1. 创建数据模型类
2. 实现HTTP客户端（可复用现有的DioHttpClient）
3. 创建Repository层处理API调用
4. 实现Service层连接UI和Repository
5. 在UI层使用Service获取数据并更新界面
6. 添加错误处理和加载状态管理 