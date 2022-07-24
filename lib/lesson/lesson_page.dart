import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../converter/lrc_conv.dart';
import '../converter/meta_conv.dart';

class LessonPage extends StatefulWidget {
  final File lyricFile;
  final File audioFile;
  final File keikoFile;

  const LessonPage({
    Key? key,
    required this.lyricFile,
    required this.audioFile,
    required this.keikoFile,
  }) : super(key: key);

  @override
  _LessonPageState createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  final _player = AudioPlayer();

  List<String> _lyrics = [];
  List<String> _code = [];

  List<int> _ttLyrics = [];
  List<int> _ttCode = [];

  List<int> _savePoint = [];
  List<int> _savePosition = [];

  var _maxDifficulty = 0;
  List<int> _difficulty = [];

  final _startPart = 0;
  final _redoMax = 3;

  var _quiz = 0;
  var _part = 0;
  var _currentPosition = 0;

  var _isPlaying = false;
  var _isAgain = false;
  var _missCount = 0;
  var _noMiss = true;

  var _idxLyric = 0;

  var _timer;

  late List<String> _dispChoices;

  var _bidText = 'title';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      final k = MetaConv();
      final convKcode = await k.lrcConvert(widget.keikoFile);
      final convKcodeMeta = await k.loadKcode(widget.keikoFile);

      final convLrcMeta = await k.loadLrc(widget.lyricFile);
      final convLyric = await LrcConv().lrcConvert(widget.lyricFile);

      await _player.setFilePath(widget.audioFile.path);

      setState(() {
        _ttLyrics = convLyric.time;
        _lyrics = convLyric.subject;

        _ttCode = convKcode.time;
        _code = convKcode.subject;

        _savePoint = convKcodeMeta.savePoint;
        _savePosition = convKcodeMeta.savePosition;

        _maxDifficulty = _code.toSet().length;
        _difficulty = List.filled(_savePoint.length, convKcodeMeta.difficulty);

        _bidText = convLrcMeta.title;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlaying) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('lesson page'),
        ),
        body: Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _dispChoices = _makeDispChoices();
                _part = _startPart;
                _quiz = _savePoint[_part];
              });
              _start();
            },
            child: (() {
              if (!_isAgain) {
                return const Text("Let's keiko.");
              } else {
                return const Text("Once more.");
              }
            })(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('lesson page'),
      ),
      body: Center(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 50),
              child: buildDispButton(),
            ),
            Align(
              alignment: const Alignment(0, 0.95),
              child: Text(
                _lyrics[_idxLyric],
                style: const TextStyle(
                  fontSize: 23,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Flex buildDispButton() {
    if (_difficulty.reduce(min) < 12) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _dispChoices
            .map(
              (String data) => SizedBox(
                width: 200,
                child: ElevatedButton(
                  child: Text(data),
                  onPressed: () {
                    if (data != _code[_quiz]) {
                      _isPlaying = false;
                      _alertDialogShow('not');
                    } else {
                      _correctAns();
                    }
                  },
                ),
              ),
            )
            .toList(),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _dispChoices
                .sublist(0, _difficulty[_part] ~/ 2)
                .map(
                  (String data) => SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      child: Text(data),
                      onPressed: () {
                        if (data != _code[_quiz]) {
                          _isPlaying = false;
                          _alertDialogShow('not');
                        } else {
                          _correctAns();
                        }
                      },
                    ),
                  ),
                )
                .toList(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _dispChoices
                .sublist(_difficulty[_part] ~/ 2)
                .map(
                  (String data) => SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      child: Text(data),
                      onPressed: () {
                        if (data != _code[_quiz]) {
                          _isPlaying = false;
                          _alertDialogShow('not');
                        } else {
                          _correctAns();
                        }
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }
  }

  List<String> _makeDispChoices() {
    List<String> dispChoices = [];

    if (_code.isEmpty) return dispChoices;
    var setOfCode = _code.toSet().toList();
    setOfCode.shuffle();
    setOfCode.remove(_code[_quiz]);
    dispChoices.add(_code[_quiz]);
    dispChoices += setOfCode.sublist(0, _difficulty[_part] - 1);
    dispChoices.shuffle();

    return dispChoices;
  }

  void _correctAns() {
    _quiz++;
    if (_savePoint.contains(_quiz)) {
      if (_difficulty[_part] < _maxDifficulty) {
        _difficulty[_part]++;
      }
      _part++;
      _missCount = 0;
    }
    _bidText = "next";
    _displayReload();
  }

  void _onTimer() {
    if (_isPlaying) {
      _currentPosition = _player.position.inMilliseconds;
      setState(() {
        _idxLyric = _bisectLeft(
          _ttLyrics,
          _currentPosition,
        );
      });

      if (_quiz < _code.length && _ttCode[_quiz] < _currentPosition) {
        _debug();
        _isPlaying = false;
        _alertDialogShow('late');
      } else if (_currentPosition < pow(10, 8)) {
        setState(() {
          _timer = Timer(
            const Duration(milliseconds: 10),
            _onTimer,
          );
        });
      }
    }
  }

  Future<void> _alertDialogShow(String title) async {
    _isPlaying = false;
    _player.pause();
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(title),
            content: Text(
              "that's a ${_code[_quiz]}",
            ),
            actions: [
              TextButton(
                child: const Text('YES'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _redo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int _bisectLeft(List<int> arr, int target) {
    int left = 0;
    int right = arr.length - 1;
    int mid = 0;
    while (left < right) {
      mid = (left + right) ~/ 2;
      if (arr[mid] >= target) {
        right = mid;
      } else {
        left = mid + 1;
      }
    }
    return left - 1;
  }

  void _redo() {
    _missCount++;
    _noMiss = false;

    if (_missCount >= _redoMax) {
      _missCount = 0;
      if (_part != 0) _part--;
    }
    _quiz = _savePoint[_part];

    setState(() {
      _bidText = 'redo';
    });
    _start();
  }

  void _displayReload() {
    setState(() {
      if (_quiz != _code.length) {
        _dispChoices = _makeDispChoices();
      } else {
        _quiz = _code.length + 1;
        _bidText = 'well, ok.';
        _isPlaying = false;
        _isAgain = true;
        _difficulty[_part]++;
        _difficulty = List.filled(_savePoint.length, _difficulty.reduce(min));
        _part = _startPart;
        _quiz = _savePoint[_part];
      }
    });
  }

  void _debug() {
    if (kDebugMode) {
      print("_part:$_part");
      print("_savePoint:$_savePoint");
      print("_savePosition:$_savePosition");
      print("_quiz:$_quiz");
      print("_code.length:${_code.length}");
      print("_ttCode[_quiz]:${_ttCode[_quiz]}");
      print("_currentPosition:$_currentPosition");
    }
  }

  void _start() {
    setState(() {
      _isPlaying = true;
      _quiz = _savePoint[_part];
      _player.seek(
        Duration(
          milliseconds: _savePosition[_part],
        ),
      );
      _player.play();
      _timer = Timer(
        const Duration(milliseconds: 10),
        _onTimer,
      );
      _displayReload();
    });
    _debug();
  }
}
