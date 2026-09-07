import Cocoa
import FinderSync
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var formatPopup: NSPopUpButton!
    private var autoOpen: NSButton!
    private var status: NSTextField!
    private var handlingRequest = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        buildWindow()
        showWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // URL handlers always require explicit naming confirmation before writing.
        guard !handlingRequest else { return }
        handlingRequest = true
        defer { handlingRequest = false }
        for url in urls.prefix(1) {
            guard let request = ActionRequest(url: url) else {
                showError(NSError(domain: "QingRightClick", code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "无法识别此新建文件请求。"]))
                return
            }
            NSApp.activate(ignoringOtherApps: true)
            do {
                let directory = try FileCreator.destination(for: request.directory)
                create(kind: request.kind, directory: directory)
            } catch { showError(error) }
        }
    }

    private func buildMenu() {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let menu = NSMenu(title: "轻右键")
        menu.addItem(withTitle: "关于轻右键", action: #selector(about), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出轻右键", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = menu
        bar.addItem(appItem)
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "编辑")
        edit.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        bar.addItem(editItem)
        NSApp.mainMenu = bar
    }

    private func label(_ string: String, size: CGFloat = 13, color: NSColor = .labelColor) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: string)
        field.font = .systemFont(ofSize: size)
        field.textColor = color
        return field
    }

    private func button(_ title: String, _ action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        return button
    }

    private func buildWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 570, height: 550),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "轻右键"
        window.isReleasedWhenClosed = false
        window.center()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -32),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 28)
        ])
        stack.addArrangedSubview(label("新建文件，右键就好。", size: 27))
        stack.addArrangedSubview(label("TXT · Word · Excel · PowerPoint · Markdown\nDOCX / XLSX / PPTX 同时适用于 WPS。", color: .secondaryLabelColor))
        stack.addArrangedSubview(button("① 打开系统设置，启用 Finder 扩展", #selector(enableExtension)))
        status = label("")
        stack.addArrangedSubview(status)
        stack.addArrangedSubview(label("② 在 Finder 普通文件夹的空白处右键 → 新建文件\n选择格式，输入名称后创建。同名文件自动编号。"))
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 12
        formatPopup = NSPopUpButton()
        formatPopup.addItems(withTitles: DocumentKind.all.map { $0.label })
        row.addArrangedSubview(formatPopup)
        row.addArrangedSubview(button("选择文件夹并新建…", #selector(manualCreate)))
        stack.addArrangedSubview(row)
        autoOpen = NSButton(checkboxWithTitle: "创建后使用默认应用打开", target: self, action: #selector(savePreferences))
        autoOpen.state = UserDefaults.standard.bool(forKey: "autoOpen") ? .on : .off
        stack.addArrangedSubview(autoOpen)
        let templateRow = NSStackView()
        templateRow.orientation = .horizontal
        templateRow.spacing = 12
        templateRow.addArrangedSubview(button("导入文档模板…", #selector(importTemplate)))
        templateRow.addArrangedSubview(button("管理我的模板", #selector(manageTemplates)))
        stack.addArrangedSubview(templateRow)
        stack.addArrangedSubview(label("首次访问桌面、文稿等目录时，请允许 macOS 的权限提示。\n云盘、搜索结果和系统虚拟目录可能不显示此扩展菜单。", size: 12, color: .secondaryLabelColor))
        refreshStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshStatus),
            name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func refreshStatus() {
        guard status != nil else { return }
        status.stringValue = FIFinderSyncController.isExtensionEnabled
            ? "● Finder 扩展已启用" : "○ Finder 扩展尚未启用，请完成上方第 ① 步"
        status.textColor = FIFinderSyncController.isExtensionEnabled ? .systemGreen : .secondaryLabelColor
    }

    private func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func enableExtension() { FIFinderSyncController.showExtensionManagementInterface() }
    @objc private func savePreferences() { UserDefaults.standard.set(autoOpen.state == .on, forKey: "autoOpen") }
    @objc private func about() { NSApp.orderFrontStandardAboutPanel(nil) }

    @objc private func manualCreate() {
        let panel = NSOpenPanel()
        panel.title = "选择新文件所在的文件夹"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let directory = panel.url else { return }
        create(kind: DocumentKind.all[formatPopup.indexOfSelectedItem].ext, directory: directory)
    }

    private func create(kind: String, directory: URL) {
        do {
            let data: Data
            let ext: String
            var defaultName = "未命名"
            if kind == "template" {
                try TemplateStore.prepare()
                let panel = NSOpenPanel()
                panel.title = "选择一个文档模板"
                panel.directoryURL = TemplateStore.folder
                panel.allowsMultipleSelection = false
                panel.allowedContentTypes = DocumentKind.all.compactMap { UTType(filenameExtension: $0.ext) }
                guard panel.runModal() == .OK, let template = panel.url else { return }
                data = try Data(contentsOf: template)
                ext = template.pathExtension.lowercased()
                defaultName = template.deletingPathExtension().lastPathComponent
            } else {
                data = try TemplateStore.data(for: kind)
                ext = kind
            }
            let alert = NSAlert()
            alert.messageText = "新建 ." + ext + " 文件"
            alert.informativeText = "保存到：\(directory.path)\n若名称已存在，将自动添加编号。"
            alert.addButton(withTitle: "创建")
            alert.addButton(withTitle: "取消")
            let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 26))
            input.stringValue = defaultName
            alert.accessoryView = input
            alert.window.initialFirstResponder = input
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            let created = try FileCreator.create(data: data, directory: directory, name: input.stringValue, ext: ext)
            NSWorkspace.shared.activateFileViewerSelecting([created])
            if UserDefaults.standard.bool(forKey: "autoOpen") { NSWorkspace.shared.open(created) }
        } catch { showError(error) }
    }

    @objc private func importTemplate() {
        let panel = NSOpenPanel()
        panel.title = "导入模板（副本将保存在轻右键中）"
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = DocumentKind.all.compactMap { UTType(filenameExtension: $0.ext) }
        guard panel.runModal() == .OK, let source = panel.url else { return }
        do {
            let imported = try TemplateStore.importTemplate(source)
            NSWorkspace.shared.activateFileViewerSelecting([imported])
        } catch { showError(error) }
    }

    @objc private func manageTemplates() {
        do {
            try TemplateStore.prepare()
            NSWorkspace.shared.open(TemplateStore.folder)
        } catch { showError(error) }
    }

    private func showError(_ error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert(error: error)
        alert.informativeText += "\n\n如为权限问题，请在系统设置 → 隐私与安全性 → 文件与文件夹中检查轻右键的权限，或在主窗口选择目标文件夹重试。"
        alert.runModal()
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
