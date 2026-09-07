import Foundation

enum CreationError: LocalizedError {
    case invalidName, invalidDirectory, tooManyDuplicates
    var errorDescription: String? {
        switch self {
        case .invalidName: return "文件名不能为空，不能包含 /、: 或控制字符，也不能是 . 或 ..。"
        case .invalidDirectory: return "目标文件夹不存在，或当前视图不是普通文件夹。"
        case .tooManyDuplicates: return "同名文件过多，请更换名称后重试。"
        }
    }
}

enum FileCreator {
    static func destination(for target: URL) throws -> URL {
        var isDirectory: ObjCBool = false
        guard target.isFileURL,
              FileManager.default.fileExists(atPath: target.path, isDirectory: &isDirectory) else {
            throw CreationError.invalidDirectory
        }
        return isDirectory.boolValue ? target : target.deletingLastPathComponent()
    }

    static func create(data: Data, directory: URL, name: String, ext: String) throws -> URL {
        let raw = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, raw != ".", raw != "..",
              !raw.contains("/"), !raw.contains(":"),
              raw.rangeOfCharacter(from: .controlCharacters) == nil,
              !ext.isEmpty, ext.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            throw CreationError.invalidName
        }
        var isDirectory: ObjCBool = false
        guard directory.isFileURL,
              FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else { throw CreationError.invalidDirectory }
        let suffix = "." + ext
        let stem = raw.lowercased().hasSuffix(suffix.lowercased()) ? String(raw.dropLast(suffix.count)) : raw
        guard !stem.isEmpty, stem != ".", stem != ".." else { throw CreationError.invalidName }
        for index in 0..<10000 {
            let filename = stem + (index == 0 ? "" : " \(index + 1)") + suffix
            let target = directory.appendingPathComponent(filename)
            do {
                // Exclusive creation prevents races from overwriting another process's file.
                try data.write(to: target, options: .withoutOverwriting)
                return target
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                continue
            }
        }
        throw CreationError.tooManyDuplicates
    }
}
