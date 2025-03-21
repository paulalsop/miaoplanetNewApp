# 新旧界面切换说明

本项目提供了两个版本的界面：原始界面和新设计的界面。您可以使用以下方法在两者之间切换。

## 切换方法

### 方法1：使用启动脚本

我们提供了两个启动脚本，分别用于启动不同版本的界面：

- `launch_original_ui.sh`：启动原始界面
- `launch_new_ui.sh`：启动新设计的界面

在终端中运行以下命令来启动相应的界面：

```bash
# 启动原始界面
./launch_original_ui.sh

# 启动新界面
./launch_new_ui.sh
```

### 方法2：直接指定入口文件

您也可以在Flutter命令中直接指定要使用的入口文件：

```bash
# 启动原始界面
flutter run -t lib/main.dart

# 启动新界面
flutter run -t lib/main_new_ui.dart
```

### 方法3：修改IDE配置

如果您使用VS Code或Android Studio等IDE，可以创建多个运行配置：

#### VS Code

在`.vscode/launch.json`文件中添加：

```json
{
  "configurations": [
    {
      "name": "原始界面",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart"
    },
    {
      "name": "新界面",
      "type": "dart",
      "request": "launch",
      "program": "lib/main_new_ui.dart"
    }
  ]
}
```

#### Android Studio / IntelliJ IDEA

1. 点击"编辑配置"
2. 添加两个Flutter配置，分别指向`lib/main.dart`和`lib/main_new_ui.dart`
3. 给配置命名为"原始界面"和"新界面"

## 创建发布版本

要创建发布版本，请指定要使用的入口文件：

```bash
# 创建使用原始界面的发布版本
flutter build apk -t lib/main.dart

# 创建使用新界面的发布版本
flutter build apk -t lib/main_new_ui.dart
```

## 注意事项

- 两个界面版本共享相同的数据和设置
- 当在同一设备上安装两个不同界面的版本时，可能会出现冲突，请注意区分包名 