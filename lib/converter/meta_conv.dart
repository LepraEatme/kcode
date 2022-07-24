import 'dart:io';

import './lrc_conv.dart';
import '../domain/kcode_meta.dart';
import '../domain/lrc_meta.dart';

class MetaConv extends LrcConv {
  final _savePointRegex = RegExp(r'\[save-point:(.+)]');
  final _savePositionRegex = RegExp(r'\[save-position:(.+)]');
  final _difficultyRegex = RegExp(r'\[difficulty:(.+)]');

  Future<KcodeMeta> loadKcode(File file) async {
    final savePoint = <int>[];
    final savePosition = <int>[];
    var difficulty = 4;

    lines = await readFile(file);

    for (var line in lines) {
      final matchPoint = _savePointRegex.firstMatch(line);
      final matchPosition = _savePositionRegex.firstMatch(line);
      final matchDiff = _difficultyRegex.firstMatch(line);

      if (matchPoint != null) {
        savePoint.addAll(matchPoint[1]!.split(',').map((e) => int.parse(e)));
      } else if (matchPosition != null) {
        savePosition.addAll(matchPosition[1]!
            .split(',')
            .map((e) => double.parse(e))
            .map((e) => e * 1000)
            .map((e) => e.toInt()));
      } else if (matchDiff != null) {
        difficulty = int.parse(matchDiff[1]!);
      }
    }

    return KcodeMeta(savePoint, savePosition, difficulty);
  }

  final _titleRegex = RegExp(r'\[title:(.+)]');

  Future<LrcMeta> loadLrc(File file) async {
    var title = 'Title';

    lines = await readFile(file);

    for (var line in lines) {
      final matchTitle = _titleRegex.firstMatch(line);
      if (matchTitle != null) {
        title = matchTitle[1]!;
      }
    }

    return LrcMeta(title);
  }
}
