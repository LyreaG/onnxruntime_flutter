# OpenVINO

Runs models through Intel's OpenVINO toolkit, on Intel CPUs, integrated and
discrete GPUs, and NPUs (Core Ultra).

| | |
|---|---|
| Platforms | Windows, Linux |
| In the bundled binaries | **no** |
| Requirements | Intel hardware and an ONNX Runtime 1.22 build with OpenVINO, plus the OpenVINO runtime it was built against |
| Method | `appendOpenVINOProvider([Map<String, String>? options])` |
| How options reach ONNX Runtime | by name: `SessionOptionsAppendExecutionProvider("OpenVINO", keys, values)`; ONNX Runtime parses the keys |
| 1.22 source | [`openvino_provider_factory.cc`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/onnxruntime/core/providers/openvino/openvino_provider_factory.cc) |

## Usage

```dart
options
  ..appendOpenVINOProvider({'device_type': 'GPU', 'cache_dir': cacheDir})
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

| Key | What it does |
|---|---|
| `device_type` | Device to run on: `CPU`, `GPU`, `NPU`, or a mode such as `AUTO`, `HETERO:…`, `MULTI:…`. Older suffixes like `CPU_FP32` are still accepted. |
| `precision` | Inference precision for the chosen device. |
| `cache_dir` | Directory for compiled model blobs, so later launches load faster. |
| `num_of_threads` | CPU threads (positive number). |
| `num_streams` | Parallel inference streams. |
| `model_priority` | Priority when several models share a device. |
| `load_config` | Path to a JSON file with raw OpenVINO properties per device. |
| `enable_opencl_throttling` | `true`/`false`: OpenCL queue throttling for GPU. |
| `enable_qdq_optimizer` | `true`/`false`: optimize quantized (QDQ) models. |
| `disable_dynamic_shapes` | `true`/`false`: treat inputs as fixed shapes. |
| `device_luid` | Pick a GPU by its LUID. |

`device_id` still works but is deprecated in 1.22; use `device_type`. The
exact values for `precision` and `model_priority` aren't listed here; check
the source file above.

## Notes

- With the bundled binaries the call throws an ONNX Runtime error saying the
  provider isn't available.
