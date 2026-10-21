import 'package:flutter_test/flutter_test.dart';
import 'package:mascotas_app/main.dart';

void main() {
  testWidgets(
    'muestra instrucciones cuando falta la configuración de Firebase',
    (tester) async {
      await tester.pumpWidget(const MascotasApp());

      expect(find.text('¡Bienvenido a Patitas!'), findsOneWidget);
      expect(
        find.textContaining('configura las opciones de Firebase'),
        findsOneWidget,
      );
    },
  );
}
