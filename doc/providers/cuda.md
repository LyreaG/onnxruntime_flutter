# CUDA

Runs models on NVIDIA GPUs through CUDA and cuDNN. The usual choice for NVIDIA
hardware on Windows and Linux; [TensorRT](tensorrt.md) can be faster but takes
longer to start.

| | |
|---|---|
| Platforms | Windows x64, Linux |
| In the bundled binaries | Windows: yes. Linux: yes *(not verified)* |
| Requirements | NVIDIA GPU and driver, [cuDNN 9](https://developer.nvidia.com/cudnn) for CUDA 12 with its `bin` folder on `PATH` (or its DLLs next to the app). Step by step: [GPU setup](../gpu_setup.md) |
| Method | `appendCudaProvider([Map<String, String>? options])` |
| How options reach ONNX Runtime | ONNX Runtime's CUDA V2 options object: created with ORT's defaults, then your map is applied by `UpdateCUDAProviderOptions`, which rejects unknown keys |
| 1.22 source | keys: [`cuda_execution_provider_info.cc`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/onnxruntime/core/providers/cuda/cuda_execution_provider_info.cc) · defaults: [`cuda_provider_options.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/providers/cuda/cuda_provider_options.h) |

## Usage

```dart
options
  ..appendCudaProvider({'device_id': '0'})
  ..appendCPUProvider(CPUFlags.useArena);
```

With no map, every option keeps ONNX Runtime's default (first GPU, no memory
limit).

## Options

All values are strings.

| Key | Values | Default | What it does |
|---|---|---|---|
| `device_id` | GPU index | `0` | Which GPU to use. |
| `gpu_mem_limit` | bytes | no limit | Maximum size of CUDA's memory arena. |
| `arena_extend_strategy` | `kNextPowerOfTwo`, `kSameAsRequested` | `kNextPowerOfTwo` | How the arena grows: in powers of two (fewer allocations) or by exactly what's requested (less waste). |
| `cudnn_conv_algo_search` | `EXHAUSTIVE`, `HEURISTIC`, `DEFAULT` | `EXHAUSTIVE` | How cuDNN picks convolution algorithms: try them all (slow first run, fastest after), use heuristics, or use the default one. |
| `cudnn_conv_use_max_workspace` | `1`/`0` | `1` | Let cuDNN's algorithm search use the maximum workspace memory. |
| `cudnn_conv1d_pad_to_nc1d` | `1`/`0` | `0` | Pad 1D convolution input `[N,C,D]` to `[N,C,1,D]` instead of `[N,C,D,1]`. |
| `do_copy_in_default_stream` | `1`/`0` | `1` | Copy data on the same stream as compute. `0` can cause data races in some models. |
| `enable_cuda_graph` | `1`/`0` | `0` | Capture the model as a CUDA graph to cut kernel launch overhead. Needs fixed input shapes and addresses. |
| `use_tf32` | `1`/`0` | `1` | Allow TF32 math on Ampere and newer GPUs: faster, slightly less precise than float32. |
| `prefer_nhwc` | `1`/`0` | `0` | Prefer NHWC layout for operators that support it. |
| `enable_skip_layer_norm_strict_mode` | `1`/`0` | `0` | Run SkipLayerNorm with the more precise LayerNormalization kernel. |
| `use_ep_level_unified_stream` | `1`/`0` | `0` | Use one stream for the whole provider. |
| `fuse_conv_bias` | `1`/`0` | `0` | Fuse convolution and bias with cuDNN Frontend (compiles kernels at run time). |
| `sdpa_kernel` | kernel selector | `0` | Which Scaled Dot Product Attention kernel to use. |
| `tunable_op_enable` | `1`/`0` | `0` | Use TunableOp kernels. **No effect with the bundled build** (see notes). |
| `tunable_op_tuning_enable` | `1`/`0` | `0` | Let TunableOp tune at run time (needs `tunable_op_enable`). **No effect with the bundled build.** |
| `tunable_op_max_tuning_duration_ms` | milliseconds | `0` (no limit) | Time limit for each tuning. **No effect with the bundled build.** |

Keys that take a memory address (`user_compute_stream`,
`has_user_compute_stream`, `gpu_external_alloc`, `gpu_external_free`,
`gpu_external_empty_cache`) can't be used from Dart.

## Notes

- **Tested** on Windows with an RTX 4070 Laptop GPU, CUDA 12.8 and cuDNN
  9.10.2 (`test/gpu_test.dart`): every key above is accepted, the defaults
  match, and results match the CPU provider.
- **TunableOp keys are accepted but ignored** by the bundled Windows build,
  which isn't compiled with TunableOp: ONNX Runtime reads them back as `0`.
- **"…depends on cudnn64_9.dll which is missing"**: cuDNN isn't installed or
  isn't on `PATH`. The call throws; catch it to fall back to CPU.
- `OrtEnv.instance.availableProviders()` lists CUDA whenever the binary has it,
  even without cuDNN. Only appending it shows whether it can load.
