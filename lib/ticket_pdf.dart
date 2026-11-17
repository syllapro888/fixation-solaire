import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _green = PdfColor.fromInt(0xFF2F6B45);
const _grey = PdfColor.fromInt(0xFF666666);
const _light = PdfColor.fromInt(0xFFF1F5F2);

/// "12500" -> "12 500"
String money(num? v) {
  if (v == null) return '';
  final neg = v < 0;
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return (neg ? '-' : '') + b.toString();
}

String qtyText(num? v) {
  if (v == null) return '';
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toStringAsFixed(1).replaceAll('.', ',');
}

/// La police PDF de base ne connaît que les caractères latins simples.
String clean(Object? s) => (s ?? '')
    .toString()
    .replaceAll(' ', ' ')
    .replaceAll(' ', ' ')
    .replaceAll('→', '->')
    .replaceAll('–', '-')
    .replaceAll('—', '-')
    .replaceAll('’', "'")
    .replaceAll('œ', 'oe')
    .replaceAll('Œ', 'OE')
    .replaceAll('−', '-')
    .replaceAll(RegExp(r'[^\x00-\xFF]'), '');

num? _n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

String _date(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal() ?? DateTime.now();
  String two(int x) => x.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

/// Construit le PDF du ticket d'installation à partir des données de la page.
Future<Uint8List> buildTicketPdf(Map<String, dynamic> t) async {
  final company = Map<String, dynamic>.from(t['company'] as Map? ?? {});
  final client = Map<String, dynamic>.from(t['client'] as Map? ?? {});
  final lines = (t['lines'] as List? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  final cur = clean(t['cur']);

  pw.Widget cell(String s,
          {bool right = false, bool bold = false, PdfColor? color, double size = 10}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: pw.Text(s,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
                fontSize: size,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color)),
      );

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: _light),
      children: [
        cell('Article', bold: true),
        cell('Qte', right: true, bold: true),
        cell('P.U.', right: true, bold: true),
        cell('Total', right: true, bold: true),
      ],
    ),
    for (final l in lines)
      pw.TableRow(children: [
        cell(clean(l['name'])),
        cell(qtyText(_n(l['qty'])), right: true),
        cell(l['price'] == null ? '' : money(_n(l['price'])), right: true),
        cell(money(_n(l['total'])), right: true),
      ]),
  ];

  pw.Widget line(String label, num? v, {bool bold = false, double size = 11, PdfColor? color, bool minus = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.Expanded(
              child: pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: size,
                      fontWeight: bold ? pw.FontWeight.bold : null,
                      color: color))),
          pw.Text('${minus ? '- ' : ''}${money(v)} $cur',
              style: pw.TextStyle(
                  fontSize: size,
                  fontWeight: bold ? pw.FontWeight.bold : null,
                  color: color)),
        ]),
      );

  final mo = _n(t['mo']) ?? 0;
  final transport = _n(t['transport']) ?? 0;
  final divers = _n(t['divers']) ?? 0;
  final remise = _n(t['remise']) ?? 0;

  final doc = pw.Document(title: 'Ticket ${clean(t['no'])}');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    build: (ctx) => [
      pw.Center(
        child: pw.Column(children: [
          pw.Text(
              clean(company['name']).isEmpty ? 'Ticket d\'installation' : clean(company['name']),
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _green)),
          if (clean(company['phone']).isNotEmpty)
            pw.Text('Tel : ${clean(company['phone'])}', style: const pw.TextStyle(color: _grey)),
          if (clean(company['address']).isNotEmpty)
            pw.Text(clean(company['address']), style: const pw.TextStyle(color: _grey)),
        ]),
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: _green, thickness: 2),
      pw.SizedBox(height: 6),
      pw.Center(
          child: pw.Text("TICKET D'INSTALLATION",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
      pw.Center(
          child: pw.Text('N° ${clean(t['no'])}',
              style: const pw.TextStyle(fontSize: 11, color: _grey))),
      pw.SizedBox(height: 12),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Client : ${clean(client['name']).isEmpty ? '...' : clean(client['name'])}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Date : ${_date(t['date'] as String?)}'),
      ]),
      if (clean(client['phone']).isNotEmpty) pw.Text('Tel : ${clean(client['phone'])}'),
      if (clean(client['lieu']).isNotEmpty) pw.Text('Lieu : ${clean(client['lieu'])}'),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(6),
        decoration: const pw.BoxDecoration(color: _light),
        child: pw.Text(clean(t['desc'])),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(5),
          1: pw.FlexColumnWidth(1.2),
          2: pw.FlexColumnWidth(1.8),
          3: pw.FlexColumnWidth(2),
        },
        border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: .5),
            bottom: pw.BorderSide(color: PdfColors.grey600)),
        children: rows,
      ),
      pw.SizedBox(height: 10),
      line('Sous-total fournitures', _n(t['fourn']), bold: true),
      if (mo != 0) line("Main-d'oeuvre (${clean(t['moTxt'])})", mo),
      if (transport != 0) line('Transport', transport),
      if (divers != 0) line('Divers', divers),
      if (remise != 0) line('Remise', remise, minus: true),
      pw.Divider(color: _green, thickness: 1.5),
      line('TOTAL', _n(t['total']), bold: true, size: 16, color: _green),
      pw.SizedBox(height: 24),
      pw.Center(
          child: pw.Text('Merci pour votre confiance',
              style: const pw.TextStyle(color: _grey, fontSize: 10))),
    ],
  ));
  return doc.save();
}

/// Ouvre le partage Android (WhatsApp, Bluetooth, impression...).
Future<void> shareTicketPdf(Map<String, dynamic> t) async {
  final bytes = await buildTicketPdf(t);
  final no = clean(t['no']).replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
  await Printing.sharePdf(bytes: bytes, filename: 'Ticket-$no.pdf');
}
