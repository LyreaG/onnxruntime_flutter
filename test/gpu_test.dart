// GPU checks for CUDA and TensorRT against the real ONNX Runtime 1.22 library.
// Needs an NVIDIA GPU, cuDNN 9 and TensorRT 10 on PATH, so it only runs when
// asked:
//   ORT_GPU_TESTS=1 flutter test test/gpu_test.dart
@TestOn('windows || linux')
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onnxruntime_flutter/onnxruntime_flutter.dart';
import 'package:onnxruntime_flutter/src/bindings/onnxruntime_bindings_generated.dart'
    as bg;

final _enabled = Platform.environment['ORT_GPU_TESTS'] == '1';

// Every key documented in doc/providers/cuda.md, with a valid non-default value.
const _cudaKeys = {
  'device_id': '0',
  'gpu_mem_limit': '2147483648',
  'arena_extend_strategy': 'kSameAsRequested',
  'cudnn_conv_algo_search': 'HEURISTIC',
  'cudnn_conv_use_max_workspace': '0',
  'cudnn_conv1d_pad_to_nc1d': '1',
  'do_copy_in_default_stream': '1',
  'enable_cuda_graph': '1',
  'use_tf32': '0',
  'prefer_nhwc': '1',
  'enable_skip_layer_norm_strict_mode': '1',
  'use_ep_level_unified_stream': '1',
  'fuse_conv_bias': '1',
  'sdpa_kernel': '1',
  'tunable_op_enable': '1',
  'tunable_op_tuning_enable': '1',
  'tunable_op_max_tuning_duration_ms': '10',
};

// Every key documented in doc/providers/tensorrt.md, with a valid value.
const _trtKeys = {
  'device_id': '0',
  'trt_fp16_enable': '1',
  'trt_int8_enable': '1',
  'trt_engine_cache_enable': '1',
  'trt_engine_cache_path': 'trt_cache',
  'trt_engine_cache_prefix': 'vad',
  'trt_timing_cache_enable': '1',
  'trt_timing_cache_path': 'trt_timing',
  'trt_force_timing_cache': '1',
  'trt_max_workspace_size': '1073741824',
  'trt_builder_optimization_level': '2',
  'trt_cuda_graph_enable': '1',
  'trt_int8_calibration_table_name': 'calib.flatbuffers',
  'trt_int8_use_native_calibration_table': '1',
  'trt_layer_norm_fp32_fallback': '1',
  'trt_sparsity_enable': '1',
  'trt_max_partition_iterations': '500',
  'trt_min_subgraph_size': '2',
  'trt_op_types_to_exclude': 'NonMaxSuppression',
  'trt_profile_min_shapes': 'input:1x512',
  'trt_profile_max_shapes': 'input:1x1536',
  'trt_profile_opt_shapes': 'input:1x1024',
  'trt_force_sequential_engine_build': '1',
  'trt_build_heuristics_enable': '1',
  'trt_detailed_build_log': '1',
  'trt_auxiliary_streams': '0',
  'trt_tactic_sources': '-CUDNN',
  'trt_extra_plugin_lib_paths': 'plugin.dll',
  'trt_preview_features': 'ALIASED_PLUGIN_IO_10_03',
  'trt_context_memory_sharing_enable': '1',
  'trt_engine_hw_compatible': '1',
  'trt_weight_stripped_engine_enable': '1',
  'trt_onnx_model_folder_path': 'models',
  'trt_engine_decryption_enable': '1',
  'trt_engine_decryption_lib_path': 'decrypt.dll',
  'trt_dump_subgraphs': '1',
  'trt_dump_ep_context_model': '1',
  'trt_ep_context_file_path': 'ctx.onnx',
  'trt_ep_context_embed_mode': '1',
  'trt_dla_enable': '1',
  'trt_dla_core': '1',
};

/// Creates an options object, applies [options] with ORT's Update…, and
/// returns what ORT reports back (key=value;… from Get…ProviderOptionsAsString).
Map<String, String> _readBack<T extends NativeType>(
  Map<String, String> options,
  bg.OrtStatusPtr Function(Pointer<Pointer<T>>) create,
  bg.OrtStatusPtr Function(
          Pointer<T>, Pointer<Pointer<Char>>, Pointer<Pointer<Char>>, int)
      update,
  bg.OrtStatusPtr Function(
          Pointer<T>, Pointer<bg.OrtAllocator>, Pointer<Pointer<Char>>)
      asString,
  void Function(Pointer<T>) release,
) {
  final api = OrtEnv.instance.ortApiPtr.ref;
  return using((arena) {
    final out = arena<Pointer<Void>>();
    OrtStatus.checkOrtStatus(create(out.cast()));
    final opts = out.value.cast<T>();
    try {
      final entries = options.entries.toList();
      final keys = arena<Pointer<Char>>(entries.length);
      final values = arena<Pointer<Char>>(entries.length);
      for (var i = 0; i < entries.length; i++) {
        keys[i] = entries[i].key.toNativeUtf8(allocator: arena).cast();
        values[i] = entries[i].value.toNativeUtf8(allocator: arena).cast();
      }
      OrtStatus.checkOrtStatus(update(opts, keys, values, entries.length));

      final alloc = arena<Pointer<bg.OrtAllocator>>();
      OrtStatus.checkOrtStatus(api.GetAllocatorWithDefaultOptions.asFunction<
          bg.OrtStatusPtr Function(
              Pointer<Pointer<bg.OrtAllocator>>)>()(alloc));
      final str = arena<Pointer<Char>>();
      OrtStatus.checkOrtStatus(asString(opts, alloc.value, str));
      final text = str.value.cast<Utf8>().toDartString();
      api.AllocatorFree.asFunction<
          bg.OrtStatusPtr Function(
              Pointer<bg.OrtAllocator>, Pointer<Void>)>()(
          alloc.value, str.value.cast());
      return {
        for (final pair in text.split(';').where((p) => p.contains('=')))
          pair.substring(0, pair.indexOf('=')):
              pair.substring(pair.indexOf('=') + 1),
      };
    } finally {
      release(opts);
    }
  });
}

Map<String, String> _cudaReadBack(Map<String, String> options) {
  final api = OrtEnv.instance.ortApiPtr.ref;
  return _readBack<bg.OrtCUDAProviderOptionsV2>(
      options,
      api.CreateCUDAProviderOptions.asFunction(),
      api.UpdateCUDAProviderOptions.asFunction(),
      api.GetCUDAProviderOptionsAsString.asFunction(),
      api.ReleaseCUDAProviderOptions.asFunction());
}

Map<String, String> _trtReadBack(Map<String, String> options) {
  final api = OrtEnv.instance.ortApiPtr.ref;
  return _readBack<bg.OrtTensorRTProviderOptionsV2>(
      options,
      api.CreateTensorRTProviderOptions.asFunction(),
      api.UpdateTensorRTProviderOptions.asFunction(),
      api.GetTensorRTProviderOptionsAsString.asFunction(),
      api.ReleaseTensorRTProviderOptions.asFunction());
}

/// Speech probability for one 64 ms window (1024 samples at 16 kHz) of the
/// example recording, taken where it contains speech.
double _vadProbability(OrtSessionOptions options) {
  final bytes =
      File('example/assets/audio/vad_example.pcm').readAsBytesSync();
  const start = 3100 * 16 * 2; // 3.1 s, 16 samples/ms, 2 bytes/sample
  final samples = Int16List.sublistView(bytes, start, start + 1024 * 2);
  final audio = Float32List.fromList([for (final s in samples) s / 32768]);

  final session = OrtSession.fromBuffer(
      File('example/assets/models/silero_vad.onnx').readAsBytesSync(),
      options);
  final state = List.filled(2, [Float32List(64)]);
  final inputs = {
    'input': OrtValueTensor.createTensorWithDataList(audio, [1, 1024]),
    'sr': OrtValueTensor.createTensorWithData(16000),
    'h': OrtValueTensor.createTensorWithDataList(state),
    'c': OrtValueTensor.createTensorWithDataList(state),
  };
  final runOptions = OrtRunOptions();
  final outputs = session.run(runOptions, inputs);
  final probability = (outputs[0]!.value as List<List<double>>)[0][0];
  for (final v in [...inputs.values, ...outputs]) {
    v?.release();
  }
  runOptions.release();
  session.release();
  return probability;
}

/// The 10 MNIST logits for a fixed synthetic 28x28 image.
List<double> _mnistLogits(OrtSessionOptions options) {
  final session = OrtSession.fromBuffer(
      File('test/fixtures/mnist-12.onnx').readAsBytesSync(), options);
  final image = Float32List.fromList(
      [for (var i = 0; i < 28 * 28; i++) (i * 37 % 255) / 255]);
  final input =
      OrtValueTensor.createTensorWithDataList(image, [1, 1, 28, 28]);
  final runOptions = OrtRunOptions();
  final outputs =
      session.run(runOptions, {session.inputNames.single: input});
  final logits = (outputs[0]!.value as List<List<double>>)[0];
  for (final v in [input, ...outputs]) {
    v?.release();
  }
  runOptions.release();
  session.release();
  return logits;
}

Matcher _closeToAll(List<double> expected, double delta) => pairwiseCompare(
    expected, (double e, double a) => (a - e).abs() <= delta,
    'within $delta of');

void main() {
  setUpAll(() {
    if (!_enabled) return;
    if (Platform.isWindows) {
      DynamicLibrary.open(
          File('example/build/windows/x64/runner/Debug/onnxruntime.dll')
              .absolute
              .path);
    }
    OrtEnv.instance.init();
  });

  group('GPU', skip: _enabled ? false : 'set ORT_GPU_TESTS=1 to run', () {
    test('ONNX Runtime accepts every documented CUDA key', () {
      final back = _cudaReadBack(_cudaKeys); // throws if any key is rejected
      // Accepted, but GetCUDAProviderOptionsAsString doesn't print them.
      expect(_cudaKeys.keys.where((k) => !back.containsKey(k)),
          unorderedEquals(['enable_cuda_graph', 'enable_skip_layer_norm_strict_mode']));
      // TunableOp isn't compiled into the bundled build: accepted, stays 0.
      const ignored = {'tunable_op_enable', 'tunable_op_tuning_enable',
          'tunable_op_max_tuning_duration_ms'};
      for (final MapEntry(:key, :value) in _cudaKeys.entries) {
        if (!back.containsKey(key)) continue;
        expect(back[key], ignored.contains(key) ? '0' : value, reason: key);
      }
    });

    test('ONNX Runtime accepts every documented TensorRT key', () {
      final back = _trtReadBack(_trtKeys); // throws if any key is rejected
      expect(_trtKeys.keys.where((k) => !back.containsKey(k)),
          ['trt_preview_features']);
      for (final MapEntry(:key, :value) in _trtKeys.entries) {
        if (back.containsKey(key)) expect(back[key], value, reason: key);
      }
    });

    test('documented defaults match ONNX Runtime', () {
      final cuda = _cudaReadBack({});
      expect(cuda['device_id'], '0');
      expect(cuda['gpu_mem_limit'], '18446744073709551615');
      expect(cuda['arena_extend_strategy'], 'kNextPowerOfTwo');
      expect(cuda['cudnn_conv_algo_search'], 'EXHAUSTIVE');
      expect(cuda['use_tf32'], '1');
      final trt = _trtReadBack({});
      expect(trt['trt_fp16_enable'], '0');
      expect(trt['trt_builder_optimization_level'], '3');
      expect(trt['trt_auxiliary_streams'], '-1');
      expect(trt['trt_max_partition_iterations'], '1000');
    });

    test('unknown keys are rejected by ONNX Runtime', () {
      expect(() => _cudaReadBack({'not_a_key': '1'}), throwsA(anything));
      expect(() => _trtReadBack({'not_a_key': '1'}), throwsA(anything));
    });

    test('CUDA gives the same results as CPU', () {
      OrtSessionOptions cpu() =>
          OrtSessionOptions()..appendCPUProvider(CPUFlags.useArena);
      OrtSessionOptions cuda() => OrtSessionOptions()
        ..appendCudaProvider({'device_id': '0'})
        ..appendCPUProvider(CPUFlags.useArena);

      expect(_mnistLogits(cuda()), _closeToAll(_mnistLogits(cpu()), 1e-3));
      final vadCpu = _vadProbability(cpu());
      expect(vadCpu, greaterThan(0.1), reason: 'window should contain speech');
      expect(_vadProbability(cuda()), closeTo(vadCpu, 1e-3));
    });

    test('TensorRT gives the same results as CPU (FP32 and FP16)', () {
      final cpu = _mnistLogits(
          OrtSessionOptions()..appendCPUProvider(CPUFlags.useArena));
      OrtSessionOptions trt(Map<String, String> o) => OrtSessionOptions()
        ..appendTensorRTProvider(o)
        ..appendCudaProvider()
        ..appendCPUProvider(CPUFlags.useArena);

      expect(_mnistLogits(trt({})), _closeToAll(cpu, 1e-2));
      // FP16 is less precise, but must still be close.
      expect(_mnistLogits(trt({'trt_fp16_enable': '1'})), _closeToAll(cpu, 0.1));
    });

    test('TensorRT needs static shapes: VAD fails at session creation', () {
      // Appending succeeds; the model is rejected only when the session is
      // created, so a try/catch around appendTensorRTProvider doesn't help.
      final options = OrtSessionOptions()
        ..appendTensorRTProvider({'device_id': '0'})
        ..appendCudaProvider()
        ..appendCPUProvider(CPUFlags.useArena);
      expect(() => _vadProbability(options),
          throwsA(predicate((e) => '$e'.contains('no shape specified'))));
    });

    test('TensorRT writes its engine cache where told', () {
      final dir = Directory.systemTemp.createTempSync('ort_trt_cache_');
      addTearDown(() => dir.deleteSync(recursive: true));
      _mnistLogits(OrtSessionOptions()
        ..appendTensorRTProvider({
          'trt_engine_cache_enable': '1',
          'trt_engine_cache_path': dir.path,
        })
        ..appendCudaProvider()
        ..appendCPUProvider(CPUFlags.useArena));
      expect(dir.listSync().map((f) => f.path), contains(endsWith('.engine')));
    });
  });
}
