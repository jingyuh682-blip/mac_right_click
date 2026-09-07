# 轻右键 · QingRightClick

原生 macOS Finder 右键新建文件工具。支持 TXT、DOC、DOCX、XLSX、PPTX、Markdown；DOCX/XLSX/PPTX 是 WPS 与 Microsoft Office 通用格式。

## 开发与交付

代码直接通过 GitHub API 编辑、提交；编译、测试、DMG 打包全部在 GitHub Actions 的 macOS 环境进行。

目标：macOS 13+，Apple Silicon 与 Intel 通用应用。首版提供未公证测试 DMG；正式 Developer ID 签名和 Apple 公证需要仓库所有者配置证书。

## 已确认设计与实施计划

1. Swift/AppKit 主应用负责命名、创建、模板管理、错误提示和 Finder 定位；Finder Sync 扩展提供原生右键入口。
2. 右键“新建文件”选择格式后打开命名确认窗口；重复文件名自动加编号，绝不覆盖已有文件。
3. Office 模板在 CI 使用标准文档库生成并重新解析验证。支持用户导入自己的模板。
4. 编写文件创建和 URL 输入验证测试，在 GitHub macOS runner 运行；构建双架构应用及嵌入扩展，检查代码签名、架构和 DMG 完整性。
5. 提供 GitHub Actions 构建产物及安装说明。自动化检查不能代替真实 Mac 上的 Finder 右键、权限、WPS 打开验收。

## 使用范围

Finder Sync 菜单用于 Finder 内的普通目录；系统虚拟视图和第三方云盘可能不显示菜单。首次使用需要在系统设置中启用 Finder 扩展，并按 macOS 提示授予目标目录访问权限。
