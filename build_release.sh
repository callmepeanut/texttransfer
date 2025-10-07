#!/bin/bash

# 获取版本号 (从 pubspec.yaml 中提取)
VERSION=$(grep '^version: ' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

echo "构建版本: $VERSION"

# 清理之前的构建
flutter clean

# 获取依赖
flutter pub get

# 构建 release APK
flutter build apk --release

# 检查构建是否成功
if [ $? -eq 0 ]; then
    # 找到生成的 APK 文件
    SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"

    if [ -f "$SOURCE_APK" ]; then
        # 创建新的文件名
        TARGET_APK="texttransfer_release_${VERSION}.apk"

        # 移动并重命名 APK
        mv "$SOURCE_APK" "$TARGET_APK"

        echo "构建成功！"
        echo "APK 文件: $TARGET_APK"
        echo "文件大小: $(du -h "$TARGET_APK" | cut -f1)"
    else
        echo "错误: 未找到生成的 APK 文件"
        exit 1
    fi
else
    echo "错误: Flutter 构建失败"
    exit 1
fi