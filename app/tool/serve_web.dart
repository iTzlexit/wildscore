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
  // `--root` so the same server can put the content tools on localhost. The
  // picker and the ranker are plain files, but a browser opened on file:// is
  // a second-class citizen — no fetch, no reliable relative paths — and both
  // pages want looking at before they go in front of anybody.
  final int rootFlag = args.indexOf('--root');
  final String rootPath = rootFlag == -1 ? 'build/web' : args[rootFlag + 1];
  final List<String> rest = <String>[
    for (int i = 0; i < args.length; i++)
      if (i != rootFlag && i != rootFlag + 1) args[i],
  ];

  final int port = rest.isEmpty ? 8080 : int.parse(rest.first);
  final Directory root = Directory(rootPath);
  if (!root.existsSync()) {
    stderr.writeln('$rootPath not found.');
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

    // Resolved *before* anything is written, because the recovery used to be
    // to set a 404 inside a catch around `addStream` — by which point the
    // headers are already on the wire, so the assignment threw
    // "Header already sent", unhandled, and took the whole server down. Serving
    // a directory with no index.html did it every time.
    if (!file.existsSync()) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.set('content-type', 'text/plain; charset=utf-8')
        ..write('not found: $path');
      await request.response.close();
      continue;
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
    } on Object catch (err) {
      // Nothing useful left to say to the client at this point — the status is
      // already sent. Log it and keep serving rather than exiting.
      stderr.writeln('  ! $path — $err');
    }
    await request.response.close();
  }
}
