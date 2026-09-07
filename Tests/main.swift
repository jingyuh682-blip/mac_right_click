import Foundation

var checks = 0
func check(_ value: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    guard value() else { fatalError("FAIL: " + message) }
}
func rejects(_ name: String, _ body: () throws -> Void) {
    do { try body(); fatalError("FAIL: expected rejection: " + name) }
    catch { checks += 1 }
}
let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: directory) }
let original = Data("original".utf8)
let first = try FileCreator.create(data: original, directory: directory, name: "测试", ext: "txt")
let second = try FileCreator.create(data: Data("second".utf8), directory: directory, name: "测试.txt", ext: "txt")
check(first.lastPathComponent == "测试.txt", "unicode filename")
check(second.lastPathComponent == "测试 2.txt", "duplicate numbering")
let preserved = try Data(contentsOf: first)
check(preserved == original, "no overwrite")
for name in ["", " ", ".", "..", "../outside", "a/b", "a:b", "bad\0name"] {
    rejects(name) { _ = try FileCreator.create(data: original, directory: directory, name: name, ext: "txt") }
}
rejects("missing folder") {
    _ = try FileCreator.create(data: original, directory: directory.appendingPathComponent("missing"), name: "x", ext: "txt")
}
rejects("file is not directory") {
    _ = try FileCreator.create(data: original, directory: first, name: "x", ext: "txt")
}
let folderDestination = try FileCreator.destination(for: directory)
check(folderDestination.path == directory.path, "folder right click stays in folder")
let fileDestination = try FileCreator.destination(for: first)
check(fileDestination.path == directory.path, "file right click targets parent")
rejects("missing Finder target") { _ = try FileCreator.destination(for: directory.appendingPathComponent("missing")) }
let upper = try FileCreator.create(data: original, directory: directory, name: "UPPER.TXT", ext: "txt")
check(upper.lastPathComponent == "UPPER.txt", "case-insensitive extension")
let link = directory.appendingPathComponent("link.txt")
try FileManager.default.createSymbolicLink(at: link, withDestinationURL: first)
let linkResult = try FileCreator.create(data: Data("unsafe".utf8), directory: directory, name: "link", ext: "txt")
check(linkResult.lastPathComponent == "link 2.txt", "existing symlink is not followed")
let stillPreserved = try Data(contentsOf: first)
check(stillPreserved == original, "symlink target preserved")
let complex = URL(fileURLWithPath: "/Users/example/文档 & 100% # +")
let request = ActionRequest(kind: "docx", directory: complex)
check(ActionRequest(url: request.url)?.directory.path == complex.path, "URL round trip")
for raw in [
    "https://create?kind=txt&directory=/tmp",
    "qingrightclick://create?kind=sh&directory=/tmp",
    "qingrightclick://create?kind=txt&directory=relative",
    "qingrightclick://create?kind=txt&kind=docx&directory=/tmp",
    "qingrightclick://create?kind=txt&directory=/tmp&extra=x",
    "qingrightclick://create?kind=txt&directory=/tmp%00x",
    "qingrightclick://other?kind=txt&directory=/tmp"
] {
    check(ActionRequest(url: URL(string: raw)!) == nil, "reject malformed route")
}
for kind in DocumentKind.all {
    let request = ActionRequest(kind: kind.ext, directory: directory)
    check(ActionRequest(url: request.url)?.kind == kind.ext, "supported format " + kind.ext)
}
print("PASS: \(checks) file creation and URL validation checks")
