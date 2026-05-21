// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Agenda\'t';

  @override
  String get navHome => 'Inicio';

  @override
  String get navMap => 'Mapa';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navSocial => 'Social';

  @override
  String get navProfile => 'Perfil';

  @override
  String get retry => 'Reintentar';

  @override
  String get noEvents => 'No hay eventos.';

  @override
  String get viewRoute => 'Ver ruta';

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get detailsTitle => 'Detalles';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get category => 'Categoría';

  @override
  String get province => 'Provincia';

  @override
  String get county => 'Comarca';

  @override
  String get municipality => 'Municipio';

  @override
  String get selectProvince => 'Selecciona una provincia';

  @override
  String get selectCounty => 'Selecciona una comarca';

  @override
  String get calendarTab => 'Calendario';

  @override
  String get listTab => 'Lista';

  @override
  String get sessionsTitle => 'Sesiones';

  @override
  String get noUpcomingEvents =>
      'No tienes ningún evento programado próximamente.';

  @override
  String get loadAgendaFailed => 'No se ha podido cargar la agenda.';

  @override
  String get loadAgendaListFailed => 'No se ha podido cargar la lista.';

  @override
  String get loadEventsFailed => 'No se han podido cargar los eventos.';

  @override
  String get navigationOpenFailed => 'No se ha podido abrir la navegación.';

  @override
  String distanceFromLocation(Object distance) {
    return '$distance km desde tu ubicación';
  }

  @override
  String get inviteToSessionTitle => '¿A qué sesión invitas?';

  @override
  String get loadEventSessionsFailed =>
      'No se han podido cargar tus sesiones para este evento.';

  @override
  String get noEventSessions =>
      'Todavía no tienes ninguna sesión para este evento. Crea una nueva para invitar a tus amigos.';

  @override
  String get createNewSession => 'Crear una nueva sesión';

  @override
  String get deleteSessionTitle => 'Eliminar sesión';

  @override
  String get deleteSessionBody => '¿Quieres eliminar esta sesión de la agenda?';

  @override
  String get deleteSessionTooltip => 'Eliminar sesión';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get applyFilters => 'Aplicar filtros';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get allFeminine => 'Todas';

  @override
  String get allMasculine => 'Todos';

  @override
  String get cultureNearYou => 'La cultura cerca de ti';

  @override
  String get date => 'Fecha';

  @override
  String get time => 'Hora';

  @override
  String get change => 'Cambiar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get sendSummaryTitle => 'Resumen del envío';

  @override
  String get close => 'Cerrar';

  @override
  String get horari => 'Horario';

  @override
  String get privacy => 'Privacidad';

  @override
  String get price => 'Precio';

  @override
  String get modalitat => 'Modalidad';

  @override
  String get address => 'Dirección';

  @override
  String get location => 'Ubicación';

  @override
  String get activityWebsite => 'Web de la actividad';

  @override
  String get localityWebsite => 'Web de la localidad';

  @override
  String get tickets => 'Compra de entradas';

  @override
  String get socialTitle => 'Social';

  @override
  String get refresh => 'Actualizar';

  @override
  String get myFriends => 'Mis amigos';

  @override
  String get deleteTooltip => 'Borrar';

  @override
  String get searchRetry => 'Reintentar';

  @override
  String get noChatsYet => 'Aún no tienes ningún chat.';

  @override
  String get noChatsYetSubtitle =>
      'Puedes iniciar una conversación con cualquier amigo.';

  @override
  String get noChatsMatchSearch => 'Ningún chat coincide con la búsqueda.';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get removeImage => 'Quitar imagen';

  @override
  String get addImage => 'Añadir imagen';

  @override
  String get writeMessageHint => 'Escribe un mensaje...';

  @override
  String get invitationAcceptedRegistered =>
      'Invitación aceptada. Asistencia registrada.';

  @override
  String get invitationRejected => 'Invitación rechazada.';

  @override
  String get loginRequiredToManageInvitations =>
      'Debes iniciar sesión para gestionar invitaciones.';

  @override
  String get invitationNoLongerValid => 'Esta invitación ya no es válida.';

  @override
  String get actionFailedFallback => 'No se ha podido completar la acción.';

  @override
  String get invitationSentByYou => 'Has enviado una invitación';

  @override
  String get invitationReceived => 'Te han invitado a un evento';

  @override
  String get eventLabel => 'Evento';

  @override
  String get invitationStatusPending => 'Pendiente';

  @override
  String get invitationStatusAccepted => 'Aceptada';

  @override
  String get invitationStatusDenied => 'Denegada';

  @override
  String get deny => 'Denegar';

  @override
  String get accept => 'Aceptar';

  @override
  String get imageFormatsOnly =>
      'Solo se pueden enviar imágenes JPG, JPEG o PNG.';

  @override
  String get emptyImage => 'La imagen seleccionada está vacía.';

  @override
  String get imageSelectFailed => 'No se ha podido seleccionar la imagen.';

  @override
  String get chatOpenFailed => 'No se ha podido abrir el chat con este amigo.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get sendFriendRequest => 'Enviar solicitud de amistad';

  @override
  String get friendRequestSentCancel => 'Solicitud enviada · Cancelar';

  @override
  String get reject => 'Rechazar';

  @override
  String get removeFriend => 'Eliminar amistad';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get language => 'Idioma';

  @override
  String get chooseAppLanguage => 'Elige el idioma de la aplicación.';

  @override
  String get blockedUsersSubtitle => 'Revisa los perfiles que has bloqueado.';

  @override
  String get noBlockedUsers => 'No has bloqueado a ningún usuario.';

  @override
  String get notificationPreferencesTitle => 'Preferencias de alertas';

  @override
  String get eventRemindersTitle => 'Recordatorios de eventos';

  @override
  String get eventRemindersSubtitle =>
      'Avisos previos para no perder sesiones o actividades.';

  @override
  String get eventChangesTitle => 'Cambios en eventos';

  @override
  String get eventChangesSubtitle =>
      'Actualizaciones de horario, ubicación o cancelaciones.';

  @override
  String get socialAlertsTitle => 'Alertas sociales';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get editInterests => 'Editar intereses';

  @override
  String get languageErrorOffline =>
      'Error de conexión. Comprueba tu conexión.';

  @override
  String get languageSaveFailed => 'No se ha podido guardar el idioma.';

  @override
  String get confirmTitle => 'Confirma';

  @override
  String get logoutConfirmBody => '¿Seguro/a que quieres cerrar sesión?';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get blockUser => 'Bloquear usuario';

  @override
  String get unblockUser => 'Desbloquear usuario';

  @override
  String get blockedYou => 'Este usuario te ha bloqueado';

  @override
  String get translate => 'Traducir';

  @override
  String get reviewsTitle => 'Reseñas';

  @override
  String get cannotRateEventTitle => 'No puedes valorar este evento';

  @override
  String get understood => 'Entendido';

  @override
  String get alreadyRatedTitle => 'Ya has valorado este evento';

  @override
  String get deleteReviewTitle => 'Eliminar valoración';

  @override
  String get generalRating => 'General';

  @override
  String get priceRating => 'Precio';

  @override
  String get ambientRating => 'Ambiente';

  @override
  String get accessibilityRating => 'Accesibilidad';

  @override
  String addPhotosCounter(Object maxCount, Object selectedCount) {
    return 'Añadir fotos ($selectedCount/$maxCount)';
  }

  @override
  String get loginTitle => 'Inicia sesión';

  @override
  String get loginContinuePrompt => 'Inicia sesión para continuar';

  @override
  String get continueWithGoogle => 'Continúa con Google';

  @override
  String get orContinueWith => 'o continúa con';

  @override
  String get forgotPasswordLink => 'He olvidado mi contraseña';

  @override
  String get recoverAccess => 'Recupera el acceso';

  @override
  String get forgotPasswordPrompt =>
      'Escribe el correo de tu cuenta. Te enviaremos un código de 6 dígitos.';

  @override
  String get emailAddressLabel => 'Correo electrónico';

  @override
  String get emailExampleHint => 'ejemplo@correo.cat';

  @override
  String get checkYourEmail => 'Revisa tu correo';

  @override
  String get verificationCodeLabel => 'Código de verificación';

  @override
  String get newPasswordPrompt => 'Elige una contraseña nueva';

  @override
  String get enterResetCodeAndPassword =>
      'Introduce el código que has recibido por correo y la nueva contraseña.';

  @override
  String signupCheckEmailPrompt(Object email) {
    return 'Hemos enviado un código de 6 dígitos a $email. Introdúcelo para crear la cuenta.';
  }

  @override
  String get confirmPasswordLabel => 'Confirma la contraseña';

  @override
  String get repeatPasswordHint => 'Repite la contraseña';

  @override
  String get interestsPrompt => '¿Qué te interesa?';

  @override
  String get enterUsername => 'Introduce tu nombre de usuario.';

  @override
  String get enterPassword => 'Introduce la contraseña.';

  @override
  String get enterEmail => 'Introduce el correo electrónico.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get enterCode6Digits => 'Introduce el código de 6 dígitos.';

  @override
  String get codeMustBe6Digits => 'El código debe tener 6 dígitos.';

  @override
  String get invalidEmailFormat => 'Formato de correo electrónico no válido';

  @override
  String get profileUpdatedSuccessfully => 'Perfil actualizado correctamente';

  @override
  String get emailAlreadyRegistered =>
      'El correo introducido ya está registrado en el sistema';

  @override
  String get invalidUsername => 'Nombre de usuario no válido';

  @override
  String get connectionErrorCheckYourConnection =>
      'Error de conexión. Comprueba tu conexión.';

  @override
  String serverErrorWithCode(Object statusCode) {
    return 'Error del servidor (código $statusCode).';
  }

  @override
  String get googleTokenError => 'No se ha podido obtener el token de Google.';

  @override
  String get verifyAccountTitle => 'Verifica la cuenta';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get newPasswordTitle => 'Nueva contraseña';

  @override
  String get savePassword => 'Guardar contraseña';

  @override
  String get forgotPasswordTitle => 'Contraseña olvidada';

  @override
  String get continueButton => 'Continuar';

  @override
  String get savePasswordButton => 'Guardar contraseña';

  @override
  String get savePasswordSuccess => 'Contraseña guardada correctamente';

  @override
  String get retryTryAgain => 'Volver a probar';

  @override
  String get saveInterestsFailed => 'No se han podido guardar los intereses.';

  @override
  String get editInterestsTitle => 'Editar intereses';

  @override
  String get showAttended => 'Asistidos';

  @override
  String get edit => 'Editar';

  @override
  String get confirmDeleteAccount => 'Eliminar mi cuenta';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get sessionExpiredTitle => 'Sesión caducada';

  @override
  String get deleteAccountErrorTitle => 'Error al eliminar la cuenta';

  @override
  String get ok => 'OK';

  @override
  String get deleteAccountButton => 'Eliminar mi cuenta';

  @override
  String get blockedProfilesSubtitle =>
      'Revisa los perfiles que has bloqueado.';

  @override
  String sessionTimeAt(Object timeLabel) {
    return 'A las $timeLabel';
  }

  @override
  String get sessionTimeAtDesc => 'Muestra la hora de una sesión';

  @override
  String generalAllRatingLabel(Object value) {
    return 'General ($value)';
  }

  @override
  String priceAllRatingLabel(Object value) {
    return 'Precio ($value)';
  }

  @override
  String ambientAllRatingLabel(Object value) {
    return 'Ambiente ($value)';
  }

  @override
  String accessibilityAllRatingLabel(Object value) {
    return 'Accesibilidad ($value)';
  }
}
