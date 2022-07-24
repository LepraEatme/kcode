import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../domain/lrc.dart';

class LrcConv {
  late List<String> lines;

  final _timeStampRegex = RegExp(r'^\[\s*(\d+):(\d+)\.(\d+)\]\s*(.*)$');

  Future<Lrc> lrcConvert(File file) async {
    final time = <int>[];
    final subject = <String>[];

    lines = await readFile(file);

    for (var line in lines) {
      final matchGroup = _timeStampRegex.firstMatch(line);
      if (matchGroup == null) continue;
      var min = int.parse(matchGroup[1]!);
      var sec = int.parse(matchGroup[2]!);
      var mil = int.parse(matchGroup[3]!);
      if (matchGroup[3]!.length == 2) mil *= 10;
      var message = matchGroup[4]!;

      time.add(((min * 60) + sec) * 1000 + mil);
      subject.add(message);
    }

    return Lrc(time, subject);
  }
}

Future<List<String>> readFile(File file) async {
  final result = <String>[];

  Stream<String> lines =
      file.openRead().transform(utf8.decoder).transform(const LineSplitter());

  try {
    await for (var line in lines) {
      result.add(line);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
  }

  return result;
}
