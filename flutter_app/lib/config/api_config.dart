class ApiConfig {
  // Change to your server IP when testing on a physical device
  // For Android emulator use: 10.0.2.2
  // For iOS simulator use: localhost
  static const String _host = '10.0.2.2';
  static const int _port = 8000;

  static String get baseUrl => 'http://$_host:$_port';
  static String get imagesUrl => '$baseUrl/images';

  static String imageUrl(String filename) => '$imagesUrl/$filename';
}
