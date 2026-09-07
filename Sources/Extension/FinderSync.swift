import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Do not use homeDirectoryForCurrentUser here: the extension is sandboxed.
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: "/Users", isDirectory: true),
            URL(fileURLWithPath: "/Volumes", isDirectory: true)
        ]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let controller = FIFinderSyncController.default()
        guard let target = controller.targetedURL() else { return nil }
        let directory: URL
        if menuKind == .contextualMenuForContainer {
            directory = target
        } else {
            // URL.hasDirectoryPath is not guaranteed for Finder-provided URLs.
            let isDirectory = (try? target.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            directory = isDirectory ? target : target.deletingLastPathComponent()
        }
        let menu = NSMenu(title: "轻右键")
        let root = NSMenuItem(title: "新建文件", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "新建文件")
        for kind in DocumentKind.all {
            let item = NSMenuItem(title: kind.label, action: #selector(createFile(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ActionRequest(kind: kind.ext, directory: directory).url
            submenu.addItem(item)
        }
        submenu.addItem(.separator())
        let custom = NSMenuItem(title: "从我的模板新建…", action: #selector(createFile(_:)), keyEquivalent: "")
        custom.target = self
        custom.representedObject = ActionRequest(kind: "template", directory: directory).url
        submenu.addItem(custom)
        root.submenu = submenu
        menu.addItem(root)
        return menu
    }

    @objc private func createFile(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }
}
