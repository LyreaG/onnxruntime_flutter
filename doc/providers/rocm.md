# ROCm

Runs models on AMD GPUs through ROCm, AMD's counterpart to CUDA.

| | |
|---|---|
| Platforms | Linux |
| In the bundled binaries | **no** *(Linux not verified)* |
| Requirements | a supported AMD GPU, the ROCm runtime, and an ONNX Runtime 1.22 build with ROCm |
| Method | `appendRocmProvider([Map<String, String>? options])` |
| How options reach ONNX Runtime | ONNX Runtime's ROCm options struct, created with ORT's defaults by `CreateROCMProviderOptions`, then your map is applied by `UpdateROCMProviderOptions`, which rejects unknown keys |
| 1.22 source | keys: [`rocm_execution_provider_info.cc`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/onnxruntime/core/providers/rocm/rocm_execution_provider_info.cc) · defaults: `OrtROCMProviderOptions` in [`onnxruntime_c_api.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/session/onnxruntime_c_api.h) |

## Usage

```dart
options
  ..appendRocmProvider({'device_id': '0'})
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

| Key | Values | Default | What it does |
|---|---|---|---|
| `device_id` | GPU index | `0` | Which GPU to use. |
| `gpu_mem_limit` | bytes | no limit | Maximum size of the memory arena. |
| `arena_extend_strategy` | `kNextPowerOfTwo`, `kSameAsRequested` | `kNextPowerOfTwo` | How the arena grows. |
| `do_copy_in_default_stream` | `1`/`0` | `1` | Copy on the compute stream. `0` can cause data races in some models. |
| `miopen_conv_exhaustive_search` | `1`/`0` | `0` | Try every MIOpen convolution algorithm (slow first run, fastest after). |
| `miopen_conv_use_max_workspace` | `1`/`0` | — | Let MIOpen's search use the maximum workspace. |
| `enable_hip_graph` | `1`/`0` | `0` | Capture the model as a HIP graph (ROCm's CUDA graphs). |
| `tunable_op_enable` | `1`/`0` | `0` | Use TunableOp kernels. |
| `tunable_op_tuning_enable` | `1`/`0` | `0` | Let TunableOp tune at run time. |
| `tunable_op_max_tuning_duration_ms` | milliseconds | `0` (no limit) | Time limit for each tuning. |

Keys that take a memory address (`user_compute_stream`,
`has_user_compute_stream`, `gpu_external_alloc`, `gpu_external_free`,
`gpu_external_empty_cache`) can't be used from Dart.

## Notes

- With the bundled binaries the call throws an ONNX Runtime error saying the
  provider isn't available.
