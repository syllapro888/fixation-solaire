import 'package:flutter_test/flutter_test.dart';
import 'package:fixation_solaire/ticket_pdf.dart';

void main() {
  test('format des montants', () {
    expect(money(163300), '163 300');
    expect(money(500), '500');
    expect(money(1000000), '1 000 000');
    expect(qtyText(2), '2');
    expect(qtyText(1.5), '1,5');
  });

  test('caractères non pris en charge retirés', () {
    expect(clean('8 panneaux – 1 rangée → corner 🔥'), '8 panneaux - 1 rangée -> corner ');
  });

  test('construction du PDF du ticket', () async {
    final bytes = await buildTicketPdf({
      'no': 'T-2026-0001',
      'date': '2026-11-17T14:55:56.879Z',
      'company': {'name': 'SOLAIRE PRO', 'phone': '06 123 45 67', 'address': ''},
      'client': {'name': 'Jean Mabiala', 'phone': '', 'lieu': 'Brazzaville'},
      'desc': '8 panneaux – 1 rangée de 8 – Corner',
      'lines': [
        {'name': 'Corner 6 m', 'qty': 8, 'unit': 'barre', 'price': 12000, 'total': 96000},
        {'name': 'Baguettes (2 paquets + 1 demi-paquet)', 'qty': 26, 'price': null, 'total': 7800},
      ],
      'fourn': 103800,
      'mo': 40000,
      'moTxt': '8 panneaux × 5 000',
      'transport': 10000,
      'divers': 0,
      'remise': 1000,
      'total': 152800,
      'cur': 'FCFA',
    });
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
