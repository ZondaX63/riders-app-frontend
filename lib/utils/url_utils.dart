class UrlUtils {
  static const String staticBase = 'https://riders-app-backend.onrender.com';

  static String buildStaticUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';

    // If already a full URL, check if it's localhost and replace, otherwise return as-is
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      if (rawPath.contains('localhost:5000')) {
        return rawPath.replaceAll('http://localhost:5000', staticBase);
      }
      return rawPath;
    }

    String p = rawPath.replaceAll('\\', '/');
    final lower = p.toLowerCase();

    // If absolute path contains uploads, cut from 'uploads/'
    final idx = lower.lastIndexOf('/uploads/');
    if (idx != -1) {
      p = p.substring(idx + 1); // remove leading '/'
    } else if (lower.contains('uploads/')) {
      final first = lower.indexOf('uploads/');
      p = p.substring(first);
    } else {
      // Ensure starts with uploads/
      if (!p.startsWith('uploads/')) {
        p = 'uploads/${p.replaceFirst(RegExp(r'^/+'), '')}';
      }
    }
    return '$staticBase/$p';
  }
}
