abstract class OrtFlags {
  int get value;
}

/// A flag for [OrtProvider.cpu].
enum CPUFlags implements OrtFlags {
  useNone(0x000),
  useArena(0x001);

  final int _value;

  const CPUFlags(this._value);

  @override
  int get value => _value;
}

/// A flag for [OrtProvider.nnapi]; pass several as a set to combine them
/// (`cpuDisabled` and `cpuOnly` together are rejected by ONNX Runtime).
enum NnapiFlags implements OrtFlags {
  useFp16(0x001),
  useNCHW(0x002),
  cpuDisabled(0x004),
  cpuOnly(0x008);

  final int _value;

  const NnapiFlags(this._value);

  @override
  int get value => _value;
}
