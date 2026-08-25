import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../util/moeda_br.dart';

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

  Future<pw.MemoryImage?> _carregarLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo_alugala.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null; // Trata suavemente se a imagem não for encontrada
    }
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

    // Definição de Cores Profissionais
    final primaryColor = PdfColor.fromHex('#1E293B'); // Azul escuro / Grafite
    final backgroundColor = PdfColor.fromHex('#F8FAFC'); // Cinza bem claro
    final borderColor = PdfColor.fromHex('#E2E8F0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // CABEÇALHO (Logo + Título)
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
                      'COBRANÇA DE ALUGUEL',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Referência: $referencia',
                      style: pw.TextStyle(
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

            // CARD DE INFORMAÇÕES PRINCIPAIS
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
                  if (imovel != null) ...[
                    pw.SizedBox(height: 8),
                    _linhaInformacao('Imóvel:', imovel),
                  ],
                  pw.SizedBox(height: 8),
                  _linhaInformacao('Data de Emissão:', _formatarData(dataEmissao)),
                  pw.SizedBox(height: 8),
                  _linhaInformacao('Vencimento:', _formatarData(vencimento), isHighlight: true),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // DESTAQUE DO VALOR TOTAL
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
                    'VALOR TOTAL',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    MoedaBr.reais(valor),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // RODAPÉ PROFISSIONAL
            pw.Center(
              child: pw.Text(
                'Documento gerado automaticamente pelo sistema Alugala.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // Widget auxiliar para as linhas de informação do Card
  pw.Widget _linhaInformacao(
    String rotulo,
    String valor, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          rotulo,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: (isBold || isHighlight) ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isHighlight ? PdfColors.red700 : PdfColors.black,
          ),
        ),
      ],
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