import Cocoa

enum TemplateStore {
    static var folder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QingRightClick/Templates", isDirectory: true)
    }

    static func prepare() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    static func data(for ext: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: "blank", withExtension: ext, subdirectory: "Templates") else {
            throw NSError(domain: "QingRightClick", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "安装包缺少 \(ext) 模板，请重新下载完整 DMG。"
            ])
        }
        return try Data(contentsOf: url)
    }

    static func importTemplate(_ source: URL) throws -> URL {
        try prepare()
        let ext = source.pathExtension.lowercased()
        guard DocumentKind.all.contains(where: { $0.ext == ext }) else {
            throw NSError(domain: "QingRightClick", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "请选择 TXT、DOC、DOCX、XLSX、PPTX 或 Markdown 文件。"
            ])
        }
        let data = try Data(contentsOf: source)
        guard data.count <= 50 * 1024 * 1024 else {
            throw NSError(domain: "QingRightClick", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "模板不能超过 50 MB。"
            ])
        }
        return try FileCreator.create(data: data, directory: folder,
                                      name: source.deletingPathExtension().lastPathComponent, ext: ext)
    }
}
