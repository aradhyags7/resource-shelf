String extractDriveFileId(String url) {
  final regExp = RegExp(r'[-\w]{25,}');
  return regExp.firstMatch(url)?.group(0) ?? '';
}

String driveViewUrl(String fileId) {
  return "https://drive.google.com/file/d/$fileId/view";
}

String driveThumbnail(String fileId) {
  return "https://drive.google.com/thumbnail?id=$fileId";
}
