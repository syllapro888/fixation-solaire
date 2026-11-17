import 'package:flutter_test/flutter_test.dart';
import 'package:fixation_solaire/updater.dart';

void main() {
  test('numéro de build depuis le nom de version', () {
    expect(buildFromTag('v1.0.12'), 12);
    expect(buildFromTag('1.0.3'), 3);
    expect(buildFromTag('abc'), isNull);
  });

  test('lecture de la Release GitHub', () {
    final info = parseRelease({
      'tag_name': 'v1.0.7',
      'html_url': 'https://github.com/x/y/releases/tag/v1.0.7',
      'body': 'notes',
      'assets': [
        {'browser_download_url': 'https://x/notes.txt'},
        {'browser_download_url': 'https://x/Fixation-Solaire-v1.0.7.apk'},
      ],
    });
    expect(info, isNotNull);
    expect(info!.build, 7);
    expect(info.version, '1.0.7');
    expect(info.apkUrl, endsWith('.apk'));
  });

  test('page de la Release si pas de fichier .apk', () {
    final info = parseRelease({
      'tag_name': 'v1.0.2',
      'html_url': 'https://github.com/x/y/releases/tag/v1.0.2',
      'assets': [],
    });
    expect(info!.apkUrl, contains('releases'));
  });
}
