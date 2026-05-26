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
  String get noRecommendationsAvailable =>
      'No hay recomendaciones disponibles.';

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
  String get searchChatHint => 'Busca un chat';

  @override
  String get filterFriendsHint => 'Filtra tus amigos';

  @override
  String get noChatsMatchSearchSubtitle =>
      'Prueba otro nombre o borra el texto para ver todos los chats.';

  @override
  String get loadChatsFailed => 'No se han podido cargar los chats.';

  @override
  String get addFriend => 'Añadir';

  @override
  String get sharedFriendsOne => '1 amigo en común';

  @override
  String sharedFriendsMany(Object count) {
    return '$count amigos en común';
  }

  @override
  String get unknownUser => 'Usuario desconocido';

  @override
  String get friendRequestAccepted => 'Solicitud aceptada. ¡Ahora sois amigos!';

  @override
  String get friendRequestRejected => 'Solicitud rechazada.';

  @override
  String get friendRequestAcceptFailed =>
      'No se ha podido aceptar la solicitud.';

  @override
  String get friendRequestRejectFailed =>
      'No se ha podido rechazar la solicitud.';

  @override
  String get removeImage => 'Quitar imagen';

  @override
  String get addImage => 'Añadir imagen';

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
  String get inactiveUnfriendBanner =>
      'Ya no sois amigos con este usuario. El chat se mantiene en la lista pero solo puedes leer los mensajes anteriores.';

  @override
  String get inactiveBlockedByPartnerBanner =>
      'Este usuario te ha bloqueado. El chat se mantiene en la lista pero solo puedes leer los mensajes anteriores.';

  @override
  String get inactiveBlockedByMeBanner =>
      'Has bloqueado a este usuario. El chat ya no aparece en la lista de conversaciones.';

  @override
  String get chatReadOnlyNotice =>
      'Este chat está inactivo. Solo puedes leer la conversación.';

  @override
  String get loadMessagesFailed => 'No se han podido cargar los mensajes.';

  @override
  String get sendMessageFailed => 'No se ha podido enviar el mensaje.';

  @override
  String get sendImageTooLarge =>
      'La imagen es demasiado grande. Prueba con una imagen más pequeña.';

  @override
  String get sendImageServerFailed =>
      'El servidor no ha podido subir la imagen. Vuelve a intentarlo.';

  @override
  String get sendImageFailed => 'No se ha podido enviar la imagen.';

  @override
  String get startChatWithFriendsTitle => 'Inicia chat con amigos';

  @override
  String get noFriendsAvailableToStartChat =>
      'No tienes amigos disponibles para iniciar un chat.';

  @override
  String get noMessagesYetCanSend => 'Aún no hay mensajes. Envía el primero.';

  @override
  String get noMessagesYetReadOnly => 'Aún no hay mensajes en este chat.';

  @override
  String get sent => 'Enviado';

  @override
  String get read => 'Leído';

  @override
  String get back => 'Atrás';

  @override
  String get createYourAccountTitle => 'Crea tu cuenta';

  @override
  String get joinAgendaSubtitle => 'Únete a Agenda\'t';

  @override
  String get usernameUniqueHint => 'Nombre de usuario único';

  @override
  String get nameHint => 'Tu nombre';

  @override
  String get repeatPasswordHintAuth => 'Repite la contraseña';

  @override
  String get createAccountLoading => 'Creando cuenta...';

  @override
  String get haveAccountPrompt => '¿Ya tienes cuenta?';

  @override
  String get signIn => 'Inicia sesión';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get signupCodeSendFailed =>
      'No se ha podido enviar el código de verificación.';

  @override
  String get passwordRequirementsHint =>
      'Mín. 8 caracteres, mayúscula, minúscula, número y carácter especial';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get passwordNeedsUppercase =>
      'La contraseña debe contener al menos una mayúscula.';

  @override
  String get passwordNeedsLowercase =>
      'La contraseña debe contener al menos una minúscula.';

  @override
  String get passwordNeedsNumber =>
      'La contraseña debe contener al menos un número.';

  @override
  String get passwordNeedsSpecialChar =>
      'La contraseña debe contener al menos un carácter especial.';

  @override
  String get signupTermsText =>
      'Al registrarte aceptas los Términos de uso y la Política de privacidad.';

  @override
  String get loadEventFailed => 'No se ha podido cargar el evento.';

  @override
  String get cannotInviteToEvent => 'No se puede invitar a este evento.';

  @override
  String get sessionBeforeEventStart =>
      'La sesión seleccionada es anterior al inicio del evento.';

  @override
  String get sessionAfterEventEnd =>
      'La sesión seleccionada es posterior al final del evento.';

  @override
  String get createInvitationSessionFailed =>
      'No se ha podido crear la sesión para invitar.';

  @override
  String get invitationSentSuccessfully => 'Invitación enviada correctamente.';

  @override
  String invitationSummaryCounts(Object errors, Object successes) {
    return '$successes invitaciones enviadas · $errors con error';
  }

  @override
  String get inviteSummaryTitle => 'Resumen del envío';

  @override
  String get inviteSummaryClose => 'Cerrar';

  @override
  String get inviteSummaryOk => 'OK';

  @override
  String get inviteInvalidRecipient => 'Usuario destinatario no válido.';

  @override
  String get inviteAlreadySent =>
      'Ya has enviado una invitación para este evento.';

  @override
  String get inviteSendFailed => 'No se ha podido enviar la invitación.';

  @override
  String get selectAtLeastOneFriend => 'Selecciona al menos un amigo';

  @override
  String get sendOneInvitation => 'Enviar 1 invitación';

  @override
  String sendInvitationsCount(Object count) {
    return 'Enviar $count invitaciones';
  }

  @override
  String get invitationPending => 'Pendiente';

  @override
  String get invitationAccepted => 'Aceptada';

  @override
  String get invitationDenied => 'Denegada';

  @override
  String get openLinkFailed => 'No se ha podido abrir el enlace.';

  @override
  String get free => 'Gratis';

  @override
  String get paid => 'De pago';

  @override
  String get eventInformationTitle => 'Información del evento';

  @override
  String get interestingLinksTitle => 'Enlaces de interés';

  @override
  String get attendButton => 'Asistir';

  @override
  String get publicEvent => 'Público';

  @override
  String get privateEvent => 'Privado';

  @override
  String get toBeDetermined => 'Por determinar';

  @override
  String get attendanceCalendarSyncDescription =>
      'Sesión sincronizada automáticamente desde la aplicación Agenda\'t';

  @override
  String get attendanceCalendarSyncPartial =>
      'Asistencia registrada, pero no se ha podido añadir a Google Calendar.';

  @override
  String get attendanceRegistered => 'Asistencia registrada correctamente.';

  @override
  String get attendanceRegisterFailed =>
      'No se ha podido registrar la asistencia.';

  @override
  String get chatNotAvailableYet =>
      'Este chat todavía no está disponible. Vuelve a intentarlo en unos segundos.';

  @override
  String get noFriendsYet => 'Aún no tienes ningún amigo.';

  @override
  String get noFriendsYetSubtitle =>
      'Busca usuarios y envíales una solicitud de amistad.';

  @override
  String get noFriendsMatchSearch => 'Ningún amigo coincide con la búsqueda.';

  @override
  String get translate => 'Traducir';

  @override
  String get loginRequired => 'Debes iniciar sesión para continuar.';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get myProfileTitle => 'Mi perfil';

  @override
  String get moreOptionsTooltip => 'Más opciones';

  @override
  String get blockedUsersTitle => 'Usuarios bloqueados';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get profilePhotoLabel => 'Foto de perfil';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get fullNameLabel => 'Nombre completo';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get usernameHint => 'Tu nombre de usuario';

  @override
  String get fullNameHint => 'Tu nombre';

  @override
  String get emailHint => 'ejemplo@correo.com';

  @override
  String get descriptionHint => 'Escribe una descripción sobre ti...';

  @override
  String get changePasswordLabel => 'Cambiar contraseña';

  @override
  String get saveLabel => 'Guardar cambios';

  @override
  String get changePasswordComingSoon =>
      'Esta función todavía no está disponible.';

  @override
  String get profileImageSelectFailed =>
      'No se ha podido seleccionar la imagen.';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado correctamente';

  @override
  String get profileUsernameRequired => 'Introduce un nombre de usuario.';

  @override
  String get profileEmailRequired => 'Introduce el correo electrónico.';

  @override
  String get profileInvalidEmail => 'Formato de correo electrónico no válido';

  @override
  String get profileEmailAlreadyRegistered =>
      'El correo introducido ya está registrado en el sistema';

  @override
  String get profileUsernameInvalid => 'Nombre de usuario no válido';

  @override
  String get profileConnectionError =>
      'Error de conexión. Comprueba tu conexión.';

  @override
  String profileServerError(Object statusCode) {
    return 'Error del servidor (código $statusCode).';
  }

  @override
  String get openInterestsEditorFailed =>
      'No se ha podido abrir el editor de intereses. Vuelve a iniciar sesión.';

  @override
  String get interestsUpdatedSuccess =>
      'Preferencias actualizadas correctamente';

  @override
  String get notificationPreferencesIntro =>
      'Decide qué alertas quieres recibir. Los cambios se aplican al momento.';

  @override
  String get deleteAccountDescription =>
      'Si eliminas tu cuenta, se borrarán tus datos personales y se cerrará la sesión.';

  @override
  String get deleteAccountConfirmBody =>
      '¿Seguro/a que quieres eliminar tu cuenta? Esta acción no se puede deshacer.';

  @override
  String get deleteAccountSessionExpiredBody =>
      'Tu sesión ha caducado. Cierra sesión y vuelve a iniciarla para eliminar la cuenta.';

  @override
  String get deleteAccountFailureBody =>
      'Se ha producido un error. Por favor, vuelve a intentarlo más tarde.';

  @override
  String get unfriendTitle => 'Eliminar amistad';

  @override
  String unfriendConfirmBody(Object username) {
    return '¿Quieres eliminar a @$username de tu red de amigos? Dejaréis de tener un vínculo directo y, si queréis, podréis volver a enviaros una solicitud de amistad en el futuro.';
  }

  @override
  String get unfriendSuccess => 'Amistad eliminada.';

  @override
  String get unfriendError => 'No se ha podido eliminar la amistad.';

  @override
  String get unfriendUnauthorized =>
      'Debes iniciar sesión para eliminar amistades.';

  @override
  String get unfriendNotFound => 'Perfil no válido.';

  @override
  String get unfriendInvalidAction =>
      'Esta acción no es válida porque actualmente no sois amigos.';

  @override
  String blockUserConfirmBody(Object username) {
    return '¿Seguro/a que quieres bloquear a @$username? Si ya sois amigos, perderéis la amistad. No podrá enviarte mensajes, solicitudes ni interactuar con tu contenido.';
  }

  @override
  String get blockUserSuccess => 'Has bloqueado a este usuario.';

  @override
  String get blockUserError => 'No se ha podido bloquear al usuario.';

  @override
  String get blockUserUnauthorized =>
      'Debes iniciar sesión para bloquear usuarios.';

  @override
  String get blockUserNotFound => 'Perfil no válido.';

  @override
  String get blockUserAlreadyBlocked => 'Este usuario ya estaba bloqueado.';

  @override
  String unblockUserConfirmBody(Object username) {
    return '¿Quieres desbloquear a @$username? Podrá ver tu perfil y volver a enviarte mensajes y solicitudes de amistad. La amistad anterior no se restablece automáticamente.';
  }

  @override
  String get unblockUserSuccess => 'Has desbloqueado a este usuario.';

  @override
  String get unblockUserError => 'No se ha podido desbloquear al usuario.';

  @override
  String get unblockUserUnauthorized =>
      'Debes iniciar sesión para bloquear usuarios.';

  @override
  String get unblockUserNotFound => 'Perfil no válido.';

  @override
  String get unblockUserAlreadyUnblocked =>
      'Este usuario ya no estaba bloqueado.';

  @override
  String get myInterestsTitle => 'Mis intereses';

  @override
  String get interestsTitle => 'Intereses';

  @override
  String get noInterestsAdded => 'Ningún interés añadido';

  @override
  String get cannotRateEventBody =>
      'Solo puedes valorar eventos a los que has asistido.';

  @override
  String get alreadyRatedBody =>
      'Ya tienes una valoración para este evento. Si la quieres cambiar, usa el lápiz de tu valoración.';

  @override
  String get loadReviewsFailed => 'No se han podido cargar las valoraciones.';

  @override
  String get loadingReviews => 'Cargando valoraciones...';

  @override
  String get noReviewsYet => 'Aún no hay valoraciones.';

  @override
  String get addReview => 'Añadir valoración';

  @override
  String get reviewPublishedSuccess => 'Valoración publicada correctamente.';

  @override
  String get reviewUpdatedSuccess => 'Valoración actualizada correctamente.';

  @override
  String get reviewDeletedSuccess => 'Valoración eliminada.';

  @override
  String get reviewDeleteFailed => 'No se ha podido eliminar la valoración.';

  @override
  String get reviewModerationThanks =>
      'Muchas gracias por tu valoración; cuando la validemos la publicaremos.';

  @override
  String get reviewImageLimitReached =>
      'Una valoración puede contener como máximo 3 imágenes.';

  @override
  String get reviewClearExistingImagesLabel =>
      'Eliminar las imágenes anteriores';

  @override
  String get reviewClearExistingImagesHelp =>
      'Actívalo para borrar las imágenes actuales antes de guardar las nuevas.';

  @override
  String get loginRequiredToLike => 'Debes iniciar sesión para poner me gusta.';

  @override
  String get reviewNoCommentToTranslate =>
      'Esta valoración no tiene comentario para traducir.';

  @override
  String get reviewAlreadyInLanguage => 'La valoración ya está en este idioma.';

  @override
  String get reviewTranslateUnavailable =>
      'Traducción no disponible temporalmente.';

  @override
  String get reviewTranslateFailed => 'No se ha podido traducir la valoración.';

  @override
  String get deleteReviewBody =>
      '¿Seguro que quieres eliminar tu valoración? Esta acción no se puede deshacer.';

  @override
  String get profileNotFound => 'Perfil no encontrado.';

  @override
  String get profileUnavailable => 'Perfil no disponible.';

  @override
  String get logoutFailed => 'No se ha podido cerrar sesión.';

  @override
  String get reviewNoEvent => 'Esta reseña no tiene evento.';

  @override
  String get sessionNoEvent => 'Esta sesión no tiene evento.';

  @override
  String get loadFriendsFailed => 'No se ha podido cargar la lista de amigos.';

  @override
  String get friendRequestNoLongerValid => 'La solicitud ya no es válida.';

  @override
  String get friendRequestSent => 'Solicitud enviada.';

  @override
  String get friendRecommendationNoLongerValid =>
      'La recomendación ya no es válida.';

  @override
  String get calendarSyncTitle => 'Sincronizar con el calendario';

  @override
  String get calendarSyncSubtitle => 'Importa las sesiones a tu calendario';

  @override
  String get inviteButton => 'Invitar';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get searchEventsHint => 'Buscar eventos...';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get agendaDetailNoSessions =>
      'No tienes ningún evento programado para este día.';

  @override
  String get dateTimeToBeDetermined => 'Fecha y hora por determinar';

  @override
  String get friendRecommendationsTitle => 'Recomendaciones de amigos';

  @override
  String get peopleYouMightKnowTitle => 'Personas que podrías conocer';

  @override
  String get friendRequestsTitle => 'Solicitudes de amistad';

  @override
  String pendingRequestsToReview(Object count) {
    return '$count pendientes por revisar';
  }

  @override
  String get noActiveChatsYet => 'Aún no tienes ningún chat activo.';

  @override
  String get noUsersFoundWithThisName =>
      'No se ha encontrado ningún usuario con este nombre.';

  @override
  String get loadRecommendationsFailed =>
      'No se han podido cargar las recomendaciones.';

  @override
  String get friendRecommendationsOne => '1 recomendación';

  @override
  String friendRecommendationsMany(Object count) {
    return '$count recomendaciones';
  }
}
