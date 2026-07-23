import 'dart:typed_data';

import 'package:flutter/services.dart';
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

  Future<pw.MemoryImage> _carregarLogo() async {
    final data = await rootBundle.load('assets/images/logo_alugala.png');
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  Future<Uint8List> gerarBytes({
    required String nomeInquilino,
    required double valor,
    required DateTime vencimento,
    required String referencia,
    String? imovel,
  }) async {
    final pdf = pw.Document();
    final logo = await _carregarLogo();
    final dataEmissao = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logo, height: 80),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Cobrança de Aluguel',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Referência: $referencia',
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Center(
              child: _tabelaExcel([
                ['Inquilino', nomeInquilino],
                if (imovel != null) ['Imóvel', imovel],
                ['Data de Emissão', _formatarData(dataEmissao)],
                ['Vencimento', _formatarData(vencimento)],
              ]),
            ),
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text(
                'Valor Total: R\$ ${valor.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _tabelaExcel(List<List<String>> linhas) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 12),
      cellAlignment: pw.Alignment.center,
      headerAlignment: pw.Alignment.center,
      cellHeight: 30,
      headerHeight: 35,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(5),
      },
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey400),
        verticalInside: pw.BorderSide(color: PdfColors.grey400),
        left: pw.BorderSide(color: PdfColors.grey400),
        right: pw.BorderSide(color: PdfColors.grey400),
        top: pw.BorderSide(color: PdfColors.grey400),
        bottom: pw.BorderSide(color: PdfColors.grey400),
      ),
      headers: ['Campo', 'Valor'],
      data: linhas,
    );
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
