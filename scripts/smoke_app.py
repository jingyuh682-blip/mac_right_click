"""Check the signed app's bundle metadata and that startup does not crash."""
from pathlib import Path
import plistlib
import subprocess
import sys

app = Path(sys.argv[1]).resolve()
with (app / "Contents/Info.plist").open("rb") as handle:
    info = plistlib.load(handle)
assert info["CFBundleIdentifier"] == "io.github.jingyuh682.qingrightclick"
assert info["CFBundleURLTypes"][0]["CFBundleURLSchemes"] == ["qingrightclick"]
extension = app / "Contents/PlugIns/FinderExtension.appex"
with (extension / "Contents/Info.plist").open("rb") as handle:
    ext_info = plistlib.load(handle)
assert ext_info["NSExtension"]["NSExtensionPointIdentifier"] == "com.apple.FinderSync"
assert ext_info["NSExtension"]["NSExtensionPrincipalClass"] == "FinderExtension.FinderSync"
with Path("Build/app-startup.log").open("w") as log:
    process = subprocess.Popen([str(app / "Contents/MacOS/QingRightClick")], stdout=log, stderr=log)
    try:
        try:
            code = process.wait(timeout=5)
            raise AssertionError(f"App exited unexpectedly during startup: {code}")
        except subprocess.TimeoutExpired:
            print("PASS: signed app stayed alive through startup (5 seconds)")
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
print("PASS: bundle identifiers, URL handler and embedded extension metadata")
