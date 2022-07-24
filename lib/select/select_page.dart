import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../lesson/lesson_page.dart';

class SelectPage extends StatefulWidget {
  const SelectPage({Key? key}) : super(key: key);

  @override
  _SelectPage createState() => _SelectPage();
}

class _SelectPage extends State<SelectPage> {
  File? lyricFile;
  File? audioFile;
  File? keikoFile;

  @override
  void initState() {
    super.initState();
    FilePicker.platform.clearTemporaryFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kcode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            ElevatedButton(
              child: const Text('Lyric'),
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    lyricFile = File(result.files.single.path!);
                  });
                }
              },
            ),
            const Spacer(flex: 1),
            ElevatedButton(
              child: const Text('Audio'),
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    audioFile = File(result.files.single.path!);
                  });
                }
              },
            ),
            const Spacer(flex: 1),
            ElevatedButton(
              child: const Text('Keiko'),
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    keikoFile = File(result.files.single.path!);
                  });
                }
              },
            ),
            const Spacer(flex: 2),
            ElevatedButton(
              child: const Text('Start'),
              onPressed: () async {
                if (lyricFile == null ||
                    audioFile == null ||
                    keikoFile == null) {
                  var snackBar = const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Please set the file.'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LessonPage(
                        lyricFile: lyricFile!,
                        audioFile: audioFile!,
                        keikoFile: keikoFile!,
                      ),
                    ),
                  );
                }
              },
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
