import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class MergeService {
  static Future<String> mergeVideos(List<String> videoPaths) async {
    if (videoPaths.isEmpty) throw Exception('没有可合并的视频');
    if (videoPaths.length == 1) return videoPaths.first;

    final dir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${dir.path}/temp_merge');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    final listFile = File('${tempDir.path}/concat_list.txt');
    final content = videoPaths.map((p) => "file '$p'").join('\n');
    await listFile.writeAsString(content);

    final outputPath = '${dir.path}/videos/${const Uuid().v4()}_merged.mp4';
    final outputDir = Directory('${dir.path}/videos');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final command =
        '-f concat -safe 0 -i ${listFile.path} -c copy -y $outputPath';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    await listFile.delete();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      final logs = await session.getLogs();
      final errorMsg = logs.map((l) => l.getMessage()).join('\n');
      throw Exception('视频合并失败: $errorMsg');
    }
  }

  static Future<String> mergeVideosWithReencode(
    List<String> videoPaths, {
    String ratio = '9:16',
  }) async {
    if (videoPaths.isEmpty) throw Exception('没有可合并的视频');
    if (videoPaths.length == 1) return videoPaths.first;

    final dir = await getApplicationDocumentsDirectory();
    final outputPath = '${dir.path}/videos/${const Uuid().v4()}_merged.mp4';

    final inputs = videoPaths.map((p) => '-i $p').join(' ');
    final filterParts = <String>[];
    for (int i = 0; i < videoPaths.length; i++) {
      filterParts.add('[$i:v]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1[v$i]');
    }
    final concatInputs = List.generate(videoPaths.length, (i) => '[v$i][${i}:a]').join('');
    final filter = '${filterParts.join(';')};${concatInputs}concat=n=${videoPaths.length}:v=1:a=1[outv][outa]';

    final command =
        '$inputs -filter_complex "$filter" -map "[outv]" -map "[outa]" -c:v libx264 -preset fast -crf 23 -c:a aac -y $outputPath';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      final logs = await session.getLogs();
      final errorMsg = logs.map((l) => l.getMessage()).join('\n');
      throw Exception('视频合并失败: $errorMsg');
    }
  }
}
