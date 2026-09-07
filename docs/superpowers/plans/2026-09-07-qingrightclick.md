# 轻右键实施计划

Goal: 在 GitHub 端完成支持 WPS 通用文档格式的 Finder 右键工具与 DMG。
Architecture: Finder Sync 扩展通过严格解析的 URL 请求主应用；主应用确认名称，使用独占写入创建模板副本。CI 生成文档模板、测试、构建与打包。
Tech Stack: Swift 5 / AppKit / FinderSync / XcodeGen / Python Office libraries / GitHub Actions。

约束：macOS 13+；arm64 与 x86_64；所有代码编辑通过 GitHub API，所有执行与构建在 GitHub Actions；不把本地其他项目上传。

1. Sources/Shared/ActionRequest.swift：格式清单与 URL 编解码；拒绝未知格式、重复字段、非绝对目录、NUL 和非预期 URL。
2. Sources/Shared/FileCreator.swift：create(data:directory:name:ext:) 返回新建 URL；校验名称和目录；独占创建、冲突编号。Tests/main.swift 验证重名、不覆盖、符号链接、中文及恶意 URL。
3. Sources/Extension/FinderSync.swift：普通目录空白处及项目菜单，传递新建目标；Sources/App/main.swift：启用引导、命名确认、默认应用打开、目录选择和错误信息。
4. Sources/App/TemplateStore.swift：读取内置模板，导入并管理个人模板副本。
5. scripts/generate_templates.py：用 python-docx/openpyxl/python-pptx 和 macOS textutil 生成真实格式，重新解析与验证容器。
6. project.yml 与 scripts/build.sh：macOS universal app 和 sandboxed Finder 扩展，逐层临时签名；验证双架构、嵌入资源和 DMG 完整性。
7. .github/workflows/build.yml：在 macos-14 runner 运行 bash scripts/build.sh；失败保留日志，成功上传 DMG 并发布带测试标识的 prerelease。
8. INSTALL.md：安装、扩展启用、权限、模板、卸载与尚需实机验证的边界。
