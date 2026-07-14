import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CobrancaPdfService {
  static DateTime calcularVencimento(
    int mesReferencia,
    int anoReferencia,
    int diaVencimento,
  ) {
    final mesVencimento = mesReferencia + 1;
    final ultimoDia = DateTime(anoReferencia, mesVencimento + 1, 0).day;
    final dia = diaVencimento.clamp(1, ultimoDia);
    return DateTime(anoReferencia, mesVencimento, dia);
  }

  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  static String _formatarReferencia(int mes, int ano) {
    return '${mes.toString().padLeft(2, '0')}/$ano';
  }

  Future<Uint8List> gerarBytes({
    required String nomeInquilino,
    required double valor,
    required DateTime vencimento,
    required String referencia,
    String? imovel,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Cobrança de Aluguel',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Text('Inquilino: $nomeInquilino'),
              if (imovel != null) ...[
                pw.SizedBox(height: 8),
                pw.Text('Imóvel: $imovel'),
              ],
              pw.SizedBox(height: 8),
              pw.Text('Referência: $referencia'),
              pw.SizedBox(height: 8),
              pw.Text('Vencimento: ${_formatarData(vencimento)}'),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Text(
                'Valor: R\$ ${valor.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> compartilhar({
    required String nomeInquilino,
    required double valor,
    required int mesReferencia,
    required int anoReferencia,
    required int diaVencimento,
    String? imovel,
  }) async {
    final vencimento = calcularVencimento(
      mesReferencia,
      anoReferencia,
      diaVencimento,
    );
    final referencia = _formatarReferencia(mesReferencia, anoReferencia);
    final nomeArquivo =
        'cobranca_${mesReferencia.toString().padLeft(2, '0')}-$anoReferencia.pdf';

    final bytes = await gerarBytes(
      nomeInquilino: nomeInquilino,
      valor: valor,
      vencimento: vencimento,
      referencia: referencia,
      imovel: imovel,
    );

    await Printing.sharePdf(bytes: bytes, filename: nomeArquivo);
  }
}
