# 轻右键安装与使用

系统要求：macOS 13 或以上，Apple Silicon（M 系列）或 Intel。

1. 下载 Release 中的 QingRightClick-0.1.0-universal.dmg，双击挂载。
2. 将 QingRightClick.app 拖到 Applications（应用程序）。
3. 从应用程序打开轻右键。本测试版使用临时签名，未获 Apple 公证；macOS 可能阻止首次打开。核对下载来自本仓库后，在系统设置 → 隐私与安全性中使用系统提供的“仍要打开”。不需要关闭 Gatekeeper 或 SIP。
4. 在轻右键窗口点击“打开系统设置，启用 Finder 扩展”，启用“轻右键 Finder 扩展”。不同 macOS 版本的设置位置不同；较新系统可在通用 → 登录项与扩展中查找 Finder 扩展。
5. 在 Finder 普通文件夹内的空白处右键，选择“新建文件”及格式，输入名称并点击创建。
6. 如 macOS 询问桌面、文稿等访问权限，请允许。创建成功后 Finder 会选中新文件。

DOCX、XLSX、PPTX 均为真实 Office Open XML 文件，适用于 WPS 与 Microsoft Office；DOC 为旧版 Word 格式。无需安装 Office 即可创建，打开编辑则需要关联应用。

“创建后使用默认应用打开”使用系统默认关联程序。如希望通过 WPS 打开，请在 Finder 的“显示简介 → 打开方式”中设置 WPS。

导入文档模板会复制文件到 ~/Library/Application Support/QingRightClick/Templates。右键菜单选择“从我的模板新建…”后选取模板。主窗口“管理我的模板”可通过 Finder 重命名或移除模板。

## 故障排查
- 没有右键菜单：确认应用已经放入 Applications，扩展已启用，重新打开 Finder 窗口，必要时注销并重新登录。
- 只在某些目录没有菜单：搜索结果、最近使用、第三方云盘以及系统虚拟目录不保证支持。可用轻右键主窗口“选择文件夹并新建…”。
- 无法写入：确认目标是可写目录，并检查系统设置的文件与文件夹权限；不会自动申请全磁盘访问权限。
- WPS 或 Word 提示修复文档：请提交具体格式、软件版本与错误信息；不要将提示修复的文件视为通过验收。
- 本项目的自动化测试验证文件创建、格式结构、编译、架构、签名完整性及 DMG；真实 Mac 的 Finder 启用和 WPS 交互仍需要人工验收。

## 卸载
先在系统设置中关闭 Finder 扩展，再退出轻右键，将应用移到废纸篓。个人模板会保留，可通过“管理我的模板”手动处理。

## 正式签名
当前 DMG 是未公证测试版。正式公开分发需要 Developer ID Application 证书、hardened runtime 签名、Apple notarization 及 stapling；请不要把证书或密码提交到代码仓库。
