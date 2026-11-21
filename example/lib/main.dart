import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime_flutter/onnxruntime_flutter.dart';
import 'model_type_test.dart';
import 'vad_iterator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _version;
  String _result = '';
  VadIterator? _vadIterator;
  static const frameSize = 64;
  static const sampleRate = 16000;

  @override
  void initState() {
    super.initState();
    _version = OrtEnv.version;
    _vadIterator = VadIterator(frameSize, sampleRate);
    _vadIterator?.initModel().then((_) {
      if (mounted) setState(() => _result = 'Ready');
    });
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16);
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OnnxRuntime'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'OnnxRuntime Version = $_version',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 50,
                ),
                TextButton(
                    onPressed: () {
                      _typeTest();
                    },
                    child: const Text('Mode Type Test')),
                const SizedBox(
                  height: 50,
                ),
                TextButton(
                    onPressed: () {
                      _vad(false);
                    },
                    child: const Text('VAD')),
                const SizedBox(
                  height: 50,
                ),
                TextButton(
                    onPressed: () {
                      _vad(true);
                    },
                    child: const Text('VAD Concurrency')),
                const SizedBox(
                  height: 50,
                ),
                Text(
                  _result,
                  key: const ValueKey('result'),
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _typeTest() async {
    setState(() => _result = 'Running...');
    final stopwatch = Stopwatch()..start();
    final values = <String>[];
    for (final test in [
      ModelTypeTest.testBool,
      ModelTypeTest.testFloat,
      ModelTypeTest.testInt64,
      ModelTypeTest.testString,
    ]) {
      final outputs = await test();
      values.add('${outputs[0]?.value}');
      print('out=${values.last}');
      for (final element in outputs) {
        element?.release();
      }
    }
    print('infer cost time=${stopwatch.elapsedMilliseconds}ms');
    setState(() => _result =
        'Type test done in ${stopwatch.elapsedMilliseconds}ms\n${values.join('\n')}');
  }

  Future<void> _vad(bool concurrent) async {
    setState(() => _result = 'Running...');
    const windowByteCount = frameSize * 2 * sampleRate ~/ 1000;
    final rawAssetFile = await rootBundle.load('assets/audio/vad_example.pcm');
    final bytes = rawAssetFile.buffer.asUint8List();
    var start = 0;
    var end = start + windowByteCount;
    final stopwatch = Stopwatch()..start();
    while (end <= bytes.length) {
      final floatBuffer = _transformBuffer(bytes.sublist(start, end))
          .map((e) => e / 32768)
          .toList();
      await _vadIterator?.predict(
          Float32List.fromList(floatBuffer), concurrent);
      start += windowByteCount;
      end = start + windowByteCount;
    }
    final segments = _vadIterator?.segments.join(', ') ?? '';
    _vadIterator?.reset();
    print('vad cost time=${stopwatch.elapsedMilliseconds}ms');
    setState(() => _result =
        'VAD done in ${stopwatch.elapsedMilliseconds}ms\nSpeech: $segments');
  }

  Int16List _transformBuffer(List<int> buffer) {
    final bytes = Uint8List.fromList(buffer);
    return Int16List.view(bytes.buffer);
  }

  @override
  void dispose() {
    _vadIterator?.release();
    super.dispose();
  }
}
