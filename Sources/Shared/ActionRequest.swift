import Foundation

struct DocumentKind {
    let ext: String
    let label: String
    static let all: [DocumentKind] = [
        .init(ext: "txt", label: "文本文件 (.txt)"),
        .init(ext: "docx", label: "Word / WPS 文字 (.docx)"),
        .init(ext: "xlsx", label: "Excel / WPS 表格 (.xlsx)"),
        .init(ext: "pptx", label: "PowerPoint / WPS 演示 (.pptx)"),
        .init(ext: "doc", label: "Word 97–2003 (.doc)"),
        .init(ext: "md", label: "Markdown (.md)")
    ]
}

struct ActionRequest {
    let kind: String
    let directory: URL

    init(kind: String, directory: URL) {
        self.kind = kind
        self.directory = directory
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = "qingrightclick"
        components.host = "create"
        components.queryItems = [
            URLQueryItem(name: "kind", value: kind),
            URLQueryItem(name: "directory", value: directory.path)
        ]
        return components.url!
    }

    init?(url: URL) {
        guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false),
              c.scheme == "qingrightclick", c.host == "create",
              c.path.isEmpty, c.user == nil, c.password == nil, c.port == nil,
              c.fragment == nil, let items = c.queryItems, items.count == 2,
              items.filter({ $0.name == "kind" }).count == 1,
              items.filter({ $0.name == "directory" }).count == 1,
              let kind = items.first(where: { $0.name == "kind" })?.value,
              DocumentKind.all.contains(where: { $0.ext == kind }) || kind == "template",
              let path = items.first(where: { $0.name == "directory" })?.value,
              path.hasPrefix("/"), !path.contains("\0") else { return nil }
        self.kind = kind
        self.directory = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
    }
}
