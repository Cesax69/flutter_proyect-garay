import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Replace these with your actual Gmail credentials
  static const String _senderEmail = 'your.email@gmail.com';
  static const String _appPassword = 'your-app-specific-password';

  static SmtpServer get _smtpServer => gmail(_senderEmail, _appPassword);

  static Future<void> sendLoginNotification(String userEmail) async {
    final message = Message()
      ..from = Address(_senderEmail, 'Tu Tienda Online')
      ..recipients.add(userEmail)
      ..subject = 'Inicio de sesión exitoso'
      ..html = '''
        <h1>¡Bienvenido a Tu Tienda Online!</h1>
        <p>Se ha detectado un inicio de sesión exitoso en tu cuenta.</p>
        <p>Si no fuiste tú quien inició sesión, por favor contacta con soporte.</p>
      ''';

    try {
      await send(message, _smtpServer);
      print('Correo de inicio de sesión enviado exitosamente a: $userEmail');
    } catch (e) {
      print('Error al enviar el correo de inicio de sesión a $userEmail: $e');
      rethrow;
    }
  }

  static Future<void> sendPurchaseConfirmation(
    String userEmail,
    List<Map<String, dynamic>> items,
    double total,
  ) async {
    String productsTable = '''
      <table style="width:100%; border-collapse: collapse; margin: 20px 0;">
        <thead>
          <tr style="background-color: #f8f9fa;">
            <th style="padding: 12px; border: 1px solid #dee2e6;">Producto</th>
            <th style="padding: 12px; border: 1px solid #dee2e6;">Cantidad</th>
            <th style="padding: 12px; border: 1px solid #dee2e6;">Precio Unitario</th>
            <th style="padding: 12px; border: 1px solid #dee2e6;">Subtotal</th>
          </tr>
        </thead>
        <tbody>
    ''';

    for (var item in items) {
      double subtotal = (item['price'] as double) * (item['quantity'] as int);
      productsTable += '''
        <tr>
          <td style="padding: 12px; border: 1px solid #dee2e6;">${item['name']}</td>
          <td style="padding: 12px; border: 1px solid #dee2e6; text-align: center;">${item['quantity']}</td>
          <td style="padding: 12px; border: 1px solid #dee2e6; text-align: right;">\$${item['price'].toStringAsFixed(2)}</td>
          <td style="padding: 12px; border: 1px solid #dee2e6; text-align: right;">\$${subtotal.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }

    productsTable += '''
        </tbody>
        <tfoot>
          <tr style="background-color: #f8f9fa; font-weight: bold;">
            <td colspan="3" style="padding: 12px; border: 1px solid #dee2e6; text-align: right;">Total:</td>
            <td style="padding: 12px; border: 1px solid #dee2e6; text-align: right;">\$${total.toStringAsFixed(2)}</td>
          </tr>
        </tfoot>
      </table>
    ''';

    final message = Message()
      ..from = Address(_senderEmail, 'Tu Tienda Online')
      ..recipients.add(userEmail)
      ..subject = 'Confirmación de tu Compra'
      ..html = '''
        <!DOCTYPE html>
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h1 style="color: #2196F3; text-align: center;">¡Gracias por tu Compra!</h1>
            
            <p>Estimado cliente,</p>
            
            <p>Hemos recibido tu pedido correctamente. A continuación encontrarás el detalle de tu compra:</p>
            
            $productsTable
            
            <div style="margin-top: 30px; padding: 20px; background-color: #f8f9fa; border-radius: 5px;">
              <p style="margin: 0;"><strong>Información Importante:</strong></p>
              <ul style="margin-top: 10px;">
                <li>Recibirás una notificación cuando tu pedido sea enviado.</li>
                <li>Conserva este correo como comprobante de tu compra.</li>
                <li>Para cualquier consulta, responde a este correo.</li>
              </ul>
            </div>
            
            <p style="text-align: center; margin-top: 30px; color: #666;">
              Gracias por confiar en Tu Tienda Online
            </p>
          </div>
        </body>
        </html>
      ''';

    try {
      await send(message, _smtpServer);
      print('Correo de confirmación de compra enviado exitosamente a: $userEmail');
    } catch (e) {
      print('Error al enviar el correo de confirmación de compra a $userEmail: $e');
      rethrow;
    }
  }
}