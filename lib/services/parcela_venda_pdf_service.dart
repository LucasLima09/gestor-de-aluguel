import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/parcela_venda_model.dart';
import '../util/moeda_br.dart';

class ParcelaVendaPdfService {
  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  static String _formatarReferencia(int mes, int ano) {
    return '${mes.toString().padLeft(2, '0')}/$ano';
  }

  Future<pw.MemoryImage?> _carregarLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo_alugala.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<void> compartilhar({
    required String nomeInquilino,
    required String imovel,
    required double valorParcela,
    required double valorTotal,
    required int mesReferencia,
    required int anoReferencia,
    required List<ParcelaVendaModel> parcelasPagas,
  }) async {
    final jaPago = parcelasPagas.fold<double>(
      0,
      (soma, parcela) => soma + parcela.valor,
    );
    final restante = valorTotal - jaPago;
    final referencia = _formatarReferencia(mesReferencia, anoReferencia);
    final nomeArquivo =
        'parcela_venda_${mesReferencia.toString().padLeft(2, '0')}-$anoReferencia.pdf';

    final bytes = await gerarBytes(
      nomeInquilino: nomeInquilino,
      imovel: imovel,
      valorParcela: valorParcela,
      valorTotal: valorTotal,
      jaPago: jaPago,
      restante: restante,
      referencia: referencia,
      parcelasPagas: parcelasPagas,
    );

    await Printing.sharePdf(bytes: bytes, filename: nomeArquivo);
  }

  Future<Uint8List> gerarBytes({
    required String nomeInquilino,
    required String imovel,
    required double valorParcela,
    required double valorTotal,
    required double jaPago,
    required double restante,
    required String referencia,
    required List<ParcelaVendaModel> parcelasPagas,
  }) async {
    final pdf = pw.Document();
    final logo = await _carregarLogo();
    final dataEmissao = DateTime.now();

    final primaryColor = PdfColor.fromHex('#1E293B');
    final backgroundColor = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#E2E8F0');

    final historico = [...parcelasPagas]..sort((a, b) {
      final porAno = a.anoReferencia.compareTo(b.anoReferencia);
      if (porAno != 0) return porAno;
      return a.mesReferencia.compareTo(b.mesReferencia);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null)
                pw.Image(logo, height: 60)
              else
                pw.Text(
                  'ALUGALA',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'PARCELA DE VENDA',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Referência: $referencia',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: borderColor, thickness: 1),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: backgroundColor,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderColor),
            ),
            child: pw.Column(
              children: [
                _linhaInformacao('Inquilino:', nomeInquilino, isBold: true),
                pw.SizedBox(height: 8),
                _linhaInformacao('Imóvel:', imovel),
                pw.SizedBox(height: 8),
                _linhaInformacao(
                  'Data de emissão:',
                  _formatarData(dataEmissao),
                ),
                pw.SizedBox(height: 8),
                _linhaInformacao('Valor total do imóvel:', MoedaBr.reais(valorTotal)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'VALOR A PAGAR',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  MoedaBr.reais(valorParcela),
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _resumoBox(
                  'Já pago',
                  MoedaBr.reais(jaPago),
                  PdfColors.green700,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _resumoBox(
                  'Falta quitar',
                  MoedaBr.reais(restante < 0 ? 0 : restante),
                  PdfColors.orange800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Histórico de parcelas pagas',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          if (historico.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Nenhuma parcela paga até o momento.',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Referência', 'Valor', 'Pago em'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 11,
              ),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
              data: [
                for (final parcela in historico)
                  [
                    _formatarReferencia(
                      parcela.mesReferencia,
                      parcela.anoReferencia,
                    ),
                    MoedaBr.reais(parcela.valor),
                    parcela.dataPagamento != null
                        ? _formatarData(parcela.dataPagamento!)
                        : '—',
                  ],
              ],
            ),
        ],
        footer: (context) => pw.Center(
          child: pw.Text(
            'Documento gerado automaticamente pelo sistema Alugala.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _resumoBox(String rotulo, String valor, PdfColor cor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            rotulo,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _linhaInformacao(
    String rotulo,
    String valor, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          rotulo,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
