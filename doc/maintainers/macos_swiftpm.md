# macOS: Swift Package Manager

How the plugin supports Swift Package Manager on macOS, how the pieces were made, and what to redo when ONNX Runtime is upgraded. Issue #8, PR #10.

## Why

Flutter 3.44+ builds iOS and macOS apps with Swift Package Manager and warns about plugins that only ship a CocoaPods podspec. That warning is going to become an error, and the CocoaPods registry goes read-only on December 2, 2026.

## How it fits together

| Piece | Used by | What it does |
|---|---|---|
| `macos/onnxruntime_flutter.podspec` + `download_onnxruntime.rb` | CocoaPods | Downloads `onnxruntime-osx-universal2-<v>.tgz` from the release and vendors `libonnxruntime.<v>.dylib` |
| `macos/onnxruntime_flutter/Package.swift` | Swift Package Manager | Binary target `onnxruntime` → `onnxruntime-macos-<v>.xcframework.zip` from the release, checksum pinned |
| `lib/src/bindings/bindings.dart` | Both | Opens `libonnxruntime.<v>.dylib` (CocoaPods), falls back to `onnxruntime.framework/onnxruntime` (Swift Package Manager) |

Swift Package Manager can't run download scripts, so it needs a prebuilt binary at a URL. That's why there's a separate xcframework asset.

`Package.swift` has an empty Swift file because Swift Package Manager needs at least one source file. The plugin is FFI-only. It also depends on `FlutterFramework`, which Flutter asks for and which only exists from Flutter 3.41. That's why the plugin's minimum Flutter is `>=3.41.0`.

## Step by step

### 1. Build the xcframework

Run **Actions → Build macOS xcframework → Run workflow** with the ONNX Runtime version ([workflow](../../.github/workflows/build-macos-xcframework.yml)). On a macOS runner, it:

1. Downloads `onnxruntime-osx-universal2-<v>.tgz` from the `onnxruntime-<v>` release and checks it against the release's `SHA256SUMS`.
2. Builds a versioned `onnxruntime.framework` (`Versions/A`, `Current` symlink, `Info.plist`, `LICENSE` and `ThirdPartyNotices.txt` in `Resources`).
3. Sets the dylib's install name to `@rpath/onnxruntime.framework/Versions/A/onnxruntime`. Without this, the app looks for the old dylib name at launch and crashes.
4. Ad-hoc signs it. `install_name_tool` invalidates the signature, and arm64 refuses unsigned code. Then it checks with `codesign --verify --strict`.
5. Wraps it with `xcodebuild -create-xcframework` and zips it with `ditto` (which keeps the symlinks).
6. Prints the architectures, linked libraries and `OrtGetApiBase` export, and the Swift Package Manager checksum (`swift package compute-checksum`).

The output is an artifact holding `onnxruntime-macos-<v>.xcframework.zip` and `checksum.txt`. Artifacts and logs are deleted after the retention period, so publish it right away.

### 2. Check and publish it

```sh
gh run download <run-id> -n onnxruntime-macos-<v>-xcframework -D xcframework
sha256sum xcframework/onnxruntime-macos-<v>.xcframework.zip   # must equal checksum.txt
gh release upload onnxruntime-<v> xcframework/onnxruntime-macos-<v>.xcframework.zip
```

Then add its line to the release's `SHA256SUMS` (re-upload with `--clobber`) and add a row to the release notes saying how it was built.

### 3. Point `Package.swift` at it

Update the binary target's `url` and `checksum` in `macos/onnxruntime_flutter/Package.swift`. If the dylib file name changes, also update the dylib name in `bindings.dart` (the framework path stays the same).

### 4. Migrate the example app (one-off, already done)

Flutter only adds its Swift Package Manager integration to an app's Xcode project; it doesn't remove CocoaPods. This was done once, on a macOS runner, with a temporary workflow that ran this in `example/` and uploaded the diff as a patch:

```sh
flutter pub get
flutter build macos --debug          # adds the Swift Package Manager integration
cd macos
pod deintegrate
rm -f Podfile Podfile.lock
sed -i '' '/Pods-Runner/d' Flutter/Flutter-Debug.xcconfig Flutter/Flutter-Release.xcconfig
cd ..
flutter build macos --debug          # no CocoaPods / FlutterFramework warnings now
flutter drive -d macos -t test_driver/app.dart
```

Flutter also raised the example's deployment target to 12.0 during this.

### 5. Verify

- CI's macOS driver test builds the example with Swift Package Manager (the default on Flutter 3.50), so it covers the framework path.
- CI no longer covers the CocoaPods path. To check it locally on a Mac in an app that still uses CocoaPods: `flutter config --no-enable-swift-package-manager`.

## Known gaps

- **macOS deployment target:** the ORT binary is built for macOS 13.3, but the example targets 12.0. Linking prints a warning, and the app probably fails to load ONNX Runtime on macOS 12.
- **iOS:** no Swift Package Manager support yet. The iOS binary's download host is dead (#9).
- The macOS dylib isn't signed by Microsoft (see the release notes). If an official signed build becomes available, rebuild the xcframework from it.
