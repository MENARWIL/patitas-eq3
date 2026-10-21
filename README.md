# Patitas

Aplicación Flutter para administrar un catálogo personal de mascotas. Integra
Firebase Authentication, Cloud Firestore y carga de imágenes a Cloudinary.
El proyecto puede ejecutarse en Android o Web.

## Funciones

- Registro, inicio y cierre de sesión por correo y contraseña.
- Consulta en tiempo real de las mascotas que pertenecen al usuario autenticado.
- Alta, edición y eliminación de registros con nombre, especie, edad y foto.
- Subida de fotos a Cloudinary; Firestore guarda la URL segura y el UID propietario.
- Validaciones de formulario y mensajes de error.

## Configurar Firebase

1. Crea un proyecto en Firebase Console.
2. En **Authentication → Sign-in method**, habilita **Email/Password**.
3. Crea una base de datos de **Cloud Firestore**.
4. Copia las reglas de [`firestore.rules`](./firestore.rules) en la pestaña **Rules**
   de Firestore y publícalas.
5. Registra una aplicación Web y/o Android en el proyecto Firebase. Copia el
   `apiKey`, `projectId`, `messagingSenderId` y el `appId` de cada plataforma.
   Para Web, autoriza `localhost` en los dominios de Firebase Authentication.

La configuración se pasa en tiempo de ejecución para no guardar los valores del
proyecto en el código fuente. Los Firebase API keys identifican la aplicación;
la protección de los datos depende de las reglas de Firestore. No pongas aquí
contraseñas, tokens privados ni el API Secret de Cloudinary.

## Configurar Cloudinary

1. Crea o usa una cuenta y anota el **Cloud name**.
2. En **Settings → Upload → Upload presets**, crea un preset **Unsigned**.
3. Restringe el preset a imágenes y define límites razonables de tamaño/formato.
   El nombre del preset unsigned se usa desde el cliente; **no** incluyas el API
   Secret en esta aplicación.

## Ejecutar

Desde PowerShell, sustituye los valores de ejemplo por los datos de tus proyectos.
Los valores `FIREBASE_APP_ID_WEB` y `FIREBASE_APP_ID_ANDROID` son los `appId`
registrados para cada plataforma. Para ejecutar Android, el dispositivo o
emulador debe estar conectado y habilitado en `flutter devices`.

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=tu_api_key `
  --dart-define=FIREBASE_PROJECT_ID=tu_project_id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=tu_sender_id `
  --dart-define=FIREBASE_APP_ID_WEB=tu_app_id_web `
  --dart-define=CLOUDINARY_CLOUD_NAME=tu_cloud_name `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=tu_unsigned_preset
```

Para Android, cambia `-d chrome` por el identificador del dispositivo y agrega:

```powershell
--dart-define=FIREBASE_APP_ID_ANDROID=tu_app_id_android
```

Si tu proyecto Web usa un dominio de autenticación diferente, agrega
`--dart-define=FIREBASE_AUTH_DOMAIN=tu-dominio.firebaseapp.com`. El bucket de
Storage es opcional y no se usa para guardar las fotos.

## Prueba de la práctica

1. Registra una cuenta y demuestra el estado autenticado.
2. Crea una mascota con una foto; comprueba el asset en Cloudinary y el documento
   con `ownerUid` y `imageUrl` en Firestore.
3. Consulta, edita y elimina registros desde la aplicación.
4. Cierra sesión y comprueba que la gestión requiere autenticación.
5. Prueba el formulario vacío y captura el mensaje de validación.

La entrega de la práctica también requiere un documento Word con capturas
explicadas, un video de 6–10 minutos e `Integrantes.txt`. Esos materiales deben
completarse con las capturas reales del equipo y los nombres de sus integrantes.
