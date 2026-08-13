import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoPath;
  final String? title;

  const VideoDetailScreen({super.key, required this.videoPath, this.title});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isFullscreen = false;
  bool _initialized = false;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final file = File(widget.videoPath);
    if (!await file.exists()) {
      setState(() => _initialized = true);
      return;
    }

    _videoController = VideoPlayerController.file(file);
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        handleColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey[400]!,
      ),
      placeholder: Container(color: Colors.black),
      errorBuilder: (context, error) => Center(
        child: Text('播放错误: $error', style: const TextStyle(color: Colors.white)),
      ),
    );

    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _saveToGallery() async {
    try {
      final bytes = await File(widget.videoPath).readAsBytes();
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'manju_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['isSuccess'] == true) {
        setState(() => _saveMessage = '已保存到相册');
      } else {
        setState(() => _saveMessage = '保存失败: ${result['errorMessage']}');
      }
    } catch (e) {
      setState(() => _saveMessage = '保存失败: $e');
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  Future<void> _saveToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/saved_videos');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);
      final fileName = 'manju_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final dest = File('${saveDir.path}/$fileName');
      await File(widget.videoPath).copy(dest.path);
      setState(() => _saveMessage = '已保存到: ${dest.path}');
    } catch (e) {
      setState(() => _saveMessage = '保存失败: $e');
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? '视频预览', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white),
            tooltip: '保存到文件',
            onPressed: _saveToFile,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            tooltip: '保存到相册',
            onPressed: _saveToGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _initialized
                ? (_chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const Text('视频文件不存在', style: TextStyle(color: Colors.white)))
                : const CircularProgressIndicator(color: Colors.white),
          ),
          if (_saveMessage != null)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _saveMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
