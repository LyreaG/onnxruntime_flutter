// Runs the provider option paths against the real ONNX Runtime library.
//
// Windows: build the example first (it bundles onnxruntime.dll), then
//   flutter test
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onnxruntime_flutter/onnxruntime_flutter.dart';

void main() {
  setUpAll(() {
    // Windows ships its own older onnxruntime.dll in System32, which wins the
    // DLL search for flutter_tester; preload the bundled 1.22 one by path.
    if (Platform.isWindows) {
      DynamicLibrary.open(File(
              'example/build/windows/x64/runner/Debug/onnxruntime.dll')
          .absolute
          .path);
    }
    OrtEnv.instance.init();
  });

  late OrtSessionOptions options;
  setUp(() => options = OrtSessionOptions());
  tearDown(() => options.release());

  test('runs against ONNX Runtime 1.22', () {
    expect(OrtEnv.version, startsWith('1.22'));
  });

  // Each call must reach ORT and either succeed or fail with an ORT error
  // (provider not built in, or its runtime libraries missing), never crash.
  final calls = <String, bool Function(OrtSessionOptions)>{
    'CUDA (V2)': (o) => o.appendCudaProvider({'device_id': '0'}),
    'TensorRT (V2)': (o) => o.appendTensorRTProvider({'trt_fp16_enable': '1'}),
    'DNNL (V2)': (o) => o.appendDNNLProvider({'use_arena': '1'}),
    'CANN (V2)': (o) => o.appendCANNProvider({'device_id': '0'}),
    'ROCm (create/update)': (o) => o.appendRocmProvider(
        {'device_id': '0', 'arena_extend_strategy': 'kSameAsRequested'}),
    'CoreML (by name)': (o) => o.appendCoreMLProvider(
        {'ModelFormat': 'MLProgram', 'MLComputeUnits': 'ALL'}),
    'DirectML (by name)': (o) =>
        o.appendDirectMLProvider({'performance_preference': 'high_performance'}),
    'OpenVINO (by name)': (o) => o.appendOpenVINOProvider({'device_type': 'CPU'}),
    'QNN (by name)': (o) => o.appendQnnProvider(),
    'XNNPACK (by name)': (o) => o.appendXnnpackProvider(),
    'CPU (flags)': (o) => o.appendCPUProvider(CPUFlags.useArena),
    'MIGraphX (V1)': (o) => o.appendMIGraphXProvider(
        {'migraphx_fp16_enable': '1', 'migraphx_save_model_path': 'model.mxr'}),
  };
  for (final MapEntry(key: name, value: append) in calls.entries) {
    test('$name reaches ONNX Runtime', () {
      try {
        expect(append(options), isTrue);
      } on ArgumentError {
        rethrow;
      } catch (e) {
        expect(e.toString(), contains('code='));
      }
    });
  }

  test('unknown MIGraphX option keys are rejected', () {
    expect(() => options.appendMIGraphXProvider({'not_an_option': '1'}),
        throwsArgumentError);
  });

  test('invalid MIGraphX option values are rejected', () {
    for (final value in ['yes', '4294967296', '']) {
      expect(() => options.appendMIGraphXProvider({'device_id': value}),
          throwsArgumentError,
          reason: value);
    }
  });

}
