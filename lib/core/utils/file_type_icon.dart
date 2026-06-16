import 'package:flutter/material.dart';

class FileTypeIcon {
  const FileTypeIcon._();

  static IconData iconFor(String fileName) {
    final extension = _extension(fileName);
    if (_imageExtensions.contains(extension)) {
      return Icons.image;
    }
    if (_videoExtensions.contains(extension)) {
      return Icons.movie;
    }
    if (_audioExtensions.contains(extension)) {
      return Icons.audio_file;
    }
    if (extension == 'pdf') {
      return Icons.picture_as_pdf;
    }
    if (_archiveExtensions.contains(extension)) {
      return Icons.folder_zip;
    }
    if (_documentExtensions.contains(extension)) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }

  static Color colorFor(String fileName) {
    final extension = _extension(fileName);
    if (_imageExtensions.contains(extension)) {
      return const Color(0xFF0EA5E9);
    }
    if (_videoExtensions.contains(extension)) {
      return const Color(0xFF7C3AED);
    }
    if (_audioExtensions.contains(extension)) {
      return const Color(0xFFDB2777);
    }
    if (extension == 'pdf') {
      return const Color(0xFFDC2626);
    }
    if (_archiveExtensions.contains(extension)) {
      return const Color(0xFFD97706);
    }
    if (_documentExtensions.contains(extension)) {
      return const Color(0xFF2563EB);
    }
    return const Color(0xFF475569);
  }

  static String labelFor(String fileName) {
    final extension = _extension(fileName);
    if (extension.isEmpty) {
      return 'FILE';
    }
    return extension.length > 5
        ? extension.substring(0, 5).toUpperCase()
        : extension.toUpperCase();
  }

  static String _extension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) {
      return '';
    }
    return fileName.substring(index + 1).toLowerCase();
  }

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'};
  static const _videoExtensions = {'mp4', 'mov', 'm4v', 'avi', 'mkv'};
  static const _audioExtensions = {'mp3', 'm4a', 'wav', 'aac', 'flac'};
  static const _archiveExtensions = {'zip', 'rar', '7z', 'tar', 'gz'};
  static const _documentExtensions = {
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'md',
  };
}
