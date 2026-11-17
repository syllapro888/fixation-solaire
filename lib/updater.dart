import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dépôt GitHub où sont publiées les nouvelles versions (onglet Releases).
const String kGithubRepo = 'syllapro888/fixation-solaire';

/// Numéro de build injecté par GitHub Actions (--dart-define=APP_BUILD=...).
const int kAppBuild = int.fromEnvironment('APP_BUILD', defaultValue: 0);

String get appVersion => kAppBuild == 0 ? '1.0.0 (dev)' : '1.0.$kAppBuild';

const Color kGreen = Color(0xFF2F6B45);

class UpdateInfo {
  final int build;
  final String version;
  final String apkUrl;
  final String notes;
  const UpdateInfo(this.build, this.version, this.apkUrl, this.notes);
}

/// "v1.0.12" -> 12. Renvoie null si le nom de version n'a pas de numéro.
int? buildFromTag(String tag) {
  final m = RegExp(r'(\d+)\s*$').firstMatch(tag.trim());
  return m == null ? null : int.parse(m.group(1)!);
}

/// Lit la réponse JSON de GitHub (dernière Release).
UpdateInfo? parseRelease(Map<String, dynamic> json) {
  final tag = json['tag_name'] as String? ?? '';
  final build = buildFromTag(tag);
  if (build == null) return null;
  String? apk;
  for (final a in (json['assets'] as List? ?? const [])) {
    final url = (a as Map)['browser_download_url'] as String?;
    if (url != null && url.toLowerCase().endsWith('.apk')) {
      apk = url;
      break;
    }
  }
  apk ??= json['html_url'] as String?;
  if (apk == null) return null;
  return UpdateInfo(
    build,
    tag.startsWith('v') ? tag.substring(1) : tag,
    apk,
    (json['body'] as String?) ?? '',
  );
}

/// Lit la dernière Release GitHub. Renvoie null si pas de connexion.
Future<UpdateInfo?> fetchLatestRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$kGithubRepo/releases/latest'));
    req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    req.headers.set(HttpHeaders.userAgentHeader, 'fixation-solaire-app');
    final res = await req.close().timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    return parseRelease(jsonDecode(body) as Map<String, dynamic>);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Vérifie s'il existe une version plus récente et propose de l'installer.
/// [silent] = true au démarrage : n'affiche rien s'il n'y a pas de mise à jour.
Future<void> checkForUpdate(BuildContext context, {bool silent = true}) async {
  if (silent && kAppBuild == 0) return; // version de développement
  if (!silent) toast(context, 'Recherche de mise à jour…');
  final info = await fetchLatestRelease();
  if (!context.mounted) return;

  if (info == null) {
    if (!silent) {
      toast(context, 'Impossible de vérifier : pas de connexion internet ?');
    }
    return;
  }
  if (info.build <= kAppBuild) {
    if (!silent) toast(context, '✅ Vous avez la dernière version ($appVersion)');
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.system_update, color: kGreen, size: 40),
      title: const Text('Nouvelle version disponible'),
      content: Text(
        'La version ${info.version} est disponible '
        '(vous avez la $appVersion).\n\n'
        'Téléchargez-la puis ouvrez le fichier pour l’installer. '
        'Elle s’installe par-dessus : vos réglages sont conservés.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Plus tard'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kGreen),
          icon: const Icon(Icons.download),
          label: const Text('Mettre à jour'),
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await launchUrl(Uri.parse(info.apkUrl),
                mode: LaunchMode.externalApplication);
            if (!ok && context.mounted) {
              toast(context, 'Impossible d’ouvrir le téléchargement');
            }
          },
        ),
      ],
    ),
  );
}
