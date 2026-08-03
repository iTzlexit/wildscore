// Serves build/web for local testing on a phone or in a browser.
//
// The Flutter web build is a static site, and there is no Python on this
// machine — the Windows `python` is a Store alias that prints an advert.
//
//   dart run tool/serve_web.dart [port]
//
// Not part of the app. Development only.
import 'dart:io';

const Map<String, String> _types = <String, String>{
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.wasm': 'application/wasm',
  '.symbols': 'text/plain',
};

Future<void> main(List<String> args) async {
  final int port = args.isEmpty ? 8080 : int.parse(args.first);
  final Directory root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('build/web not found — run `flutter build web` first.');
    exitCode = 66;
    return;
  }

  final HttpServer server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln('serving ${root.absolute.path} on http://localhost:$port');

  await for (final HttpRequest request in server) {
    String path = request.uri.path;
    if (path.endsWith('/')) {
      path = '${path}index.html';
    }
    File file = File('${root.path}$path');
    // Single-page app: anything that is not a real file falls back to the
    // shell, so deep links do not 404.
    if (!file.existsSync()) {
      file = File('${root.path}/index.html');
    }

    final String ext = file.path.contains('.')
        ? file.path.substring(file.path.lastIndexOf('.'))
        : '';
    request.response.headers.set(
      'content-type',
      _types[ext] ?? 'application/octet-stream',
    );
    // No caching: the whole point is to see the build that was just made.
    request.response.headers.set('cache-control', 'no-store');
    try {
      await request.response.addStream(file.openRead());
    } on Object {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  }
}
