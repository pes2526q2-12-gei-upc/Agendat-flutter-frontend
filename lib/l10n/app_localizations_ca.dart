// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appName => 'Agenda\'t';

  @override
  String get navHome => 'Inici';

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
  String get noEvents => 'No hi ha esdeveniments.';

  @override
  String get viewRoute => 'Veure ruta';

  @override
  String get viewDetails => 'Veure detalls';

  @override
  String get detailsTitle => 'Detalls';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get category => 'Categoria';

  @override
  String get province => 'Província';

  @override
  String get county => 'Comarca';

  @override
  String get municipality => 'Municipi';

  @override
  String get selectProvince => 'Selecciona una província';

  @override
  String get selectCounty => 'Selecciona una comarca';

  @override
  String get calendarTab => 'Calendari';

  @override
  String get listTab => 'Llista';

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get noUpcomingEvents =>
      'No tens cap esdeveniment programat pròximament.';

  @override
  String get loadAgendaFailed => 'No s\'ha pogut carregar l\'agenda.';

  @override
  String get loadAgendaListFailed => 'No s\'ha pogut carregar la llista.';

  @override
  String get loadEventsFailed => 'No s\'han pogut carregar els esdeveniments.';

  @override
  String get navigationOpenFailed => 'No s\'ha pogut obrir la navegació.';

  @override
  String distanceFromLocation(Object distance) {
    return '$distance km des de la teva ubicació';
  }

  @override
  String get inviteToSessionTitle => 'A quina sessió convides?';

  @override
  String get loadEventSessionsFailed =>
      'No s\'han pogut carregar les teves sessions per a aquest esdeveniment.';

  @override
  String get noEventSessions =>
      'Encara no tens cap sessió per aquest esdeveniment. Crea\'n una de nova per convidar als teus amics.';

  @override
  String get createNewSession => 'Crea una sessió nova';

  @override
  String get deleteSessionTitle => 'Eliminar sessió';

  @override
  String get deleteSessionBody => 'Vols eliminar aquesta sessió de l’agenda?';

  @override
  String get deleteSessionTooltip => 'Eliminar sessió';

  @override
  String get cancel => 'Cancel·lar';

  @override
  String get delete => 'Eliminar';

  @override
  String get applyFilters => 'Aplicar filtres';

  @override
  String get clearFilters => 'Netejar filtres';

  @override
  String get allFeminine => 'Totes';

  @override
  String get allMasculine => 'Tots';

  @override
  String get cultureNearYou => 'La cultura a prop teu';

  @override
  String get date => 'Data';

  @override
  String get time => 'Hora';

  @override
  String get change => 'Canvia';

  @override
  String get confirm => 'Confirmar';

  @override
  String get sendSummaryTitle => 'Resum de l\'enviament';

  @override
  String get close => 'Tanca';

  @override
  String get horari => 'Horari';

  @override
  String get privacy => 'Privacitat';

  @override
  String get price => 'Preu';

  @override
  String get modalitat => 'Modalitat';

  @override
  String get address => 'Adreça';

  @override
  String get location => 'Ubicació';

  @override
  String get activityWebsite => 'Web de l\'activitat';

  @override
  String get localityWebsite => 'Web de la localitat';

  @override
  String get tickets => 'Compra d\'entrades';

  @override
  String get socialTitle => 'Social';

  @override
  String get refresh => 'Actualitza';

  @override
  String get myFriends => 'Els meus amics';

  @override
  String get deleteTooltip => 'Esborra';

  @override
  String get searchRetry => 'Reintentar';

  @override
  String get noChatsYet => 'Encara no tens cap xat.';

  @override
  String get noChatsYetSubtitle =>
      'Pots iniciar una conversa amb qualsevol amic.';

  @override
  String get noChatsMatchSearch => 'Cap xat coincideix amb la cerca.';

  @override
  String get clearSearch => 'Esborra cerca';

  @override
  String get removeImage => 'Treu la imatge';

  @override
  String get addImage => 'Afegir imatge';

  @override
  String get writeMessageHint => 'Escriu un missatge...';

  @override
  String get invitationAcceptedRegistered =>
      'Invitació acceptada. Assistència registrada.';

  @override
  String get invitationRejected => 'Invitació rebutjada.';

  @override
  String get loginRequiredToManageInvitations =>
      'Cal iniciar sessió per gestionar invitacions.';

  @override
  String get invitationNoLongerValid => 'Aquesta invitació ja no és vàlida.';

  @override
  String get actionFailedFallback => 'No s\'ha pogut completar l\'acció.';

  @override
  String get invitationSentByYou => 'Has enviat una invitació';

  @override
  String get invitationReceived => 'T\'han convidat a un esdeveniment';

  @override
  String get eventLabel => 'Esdeveniment';

  @override
  String get invitationStatusPending => 'Pendent';

  @override
  String get invitationStatusAccepted => 'Acceptada';

  @override
  String get invitationStatusDenied => 'Denegada';

  @override
  String get deny => 'Denegar';

  @override
  String get accept => 'Acceptar';

  @override
  String get imageFormatsOnly =>
      'Només es poden enviar imatges JPG, JPEG o PNG.';

  @override
  String get emptyImage => 'La imatge seleccionada és buida.';

  @override
  String get imageSelectFailed => 'No s\'ha pogut seleccionar la imatge.';

  @override
  String get chatOpenFailed => 'No s\'ha pogut obrir el xat amb aquest amic.';

  @override
  String get chatsTitle => 'Xats';

  @override
  String get sendFriendRequest => 'Enviar sol·licitud d\'amistat';

  @override
  String get friendRequestSentCancel => 'Sol·licitud enviada · Cancel·lar';

  @override
  String get reject => 'Rebutjar';

  @override
  String get removeFriend => 'Eliminar amistat';

  @override
  String get unblock => 'Desbloquejar';

  @override
  String get language => 'Idioma';

  @override
  String get chooseAppLanguage => 'Tria l\'idioma de l\'aplicació.';

  @override
  String get blockedUsersSubtitle => 'Revisa els perfils que has bloquejat.';

  @override
  String get noBlockedUsers => 'No has bloquejat cap usuari.';

  @override
  String get notificationPreferencesTitle => 'Preferències d\'alertes';

  @override
  String get eventRemindersTitle => 'Recordatoris d\'esdeveniments';

  @override
  String get eventRemindersSubtitle =>
      'Avisos previs per no perdre sessions o activitats.';

  @override
  String get eventChangesTitle => 'Canvis en esdeveniments';

  @override
  String get eventChangesSubtitle =>
      'Actualitzacions d\'horari, ubicació o cancel·lacions.';

  @override
  String get socialAlertsTitle => 'Alertes socials';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get editInterests => 'Editar interessos';

  @override
  String get languageErrorOffline =>
      'Error de connexió. Comprova la teva connexió.';

  @override
  String get languageSaveFailed => 'No s\'ha pogut desar l\'idioma.';

  @override
  String get confirmTitle => 'Confirma';

  @override
  String get logoutConfirmBody => 'Estàs segur/a que vols tancar la sessió?';

  @override
  String get logout => 'Tancar sessió';

  @override
  String get moreOptions => 'Més opcions';

  @override
  String get blockUser => 'Bloquejar usuari';

  @override
  String get unblockUser => 'Desbloquejar usuari';

  @override
  String get blockedYou => 'Aquest usuari t\'ha bloquejat';

  @override
  String get translate => 'Traduir';

  @override
  String get reviewsTitle => 'Ressenyes';

  @override
  String get cannotRateEventTitle => 'No pots valorar aquest esdeveniment';

  @override
  String get understood => 'Entesos';

  @override
  String get alreadyRatedTitle => 'Ja has valorat aquest esdeveniment';

  @override
  String get deleteReviewTitle => 'Eliminar valoració';

  @override
  String get generalRating => 'General';

  @override
  String get priceRating => 'Preu';

  @override
  String get ambientRating => 'Ambient';

  @override
  String get accessibilityRating => 'Accessibilitat';

  @override
  String addPhotosCounter(Object maxCount, Object selectedCount) {
    return 'Afegir fotos ($selectedCount/$maxCount)';
  }

  @override
  String get loginTitle => 'Inicia sessió';

  @override
  String get loginContinuePrompt => 'Inicia sessió per continuar';

  @override
  String get continueWithGoogle => 'Continua amb Google';

  @override
  String get orContinueWith => 'o continua amb';

  @override
  String get forgotPasswordLink => 'He oblidat la meva contrasenya';

  @override
  String get recoverAccess => 'Recupera l\'accés';

  @override
  String get forgotPasswordPrompt =>
      'Escriu el correu del teu compte. T\'enviarem un codi de 6 dígits.';

  @override
  String get emailAddressLabel => 'Correu electrònic';

  @override
  String get emailExampleHint => 'exemple@correu.cat';

  @override
  String get checkYourEmail => 'Revisa el teu correu';

  @override
  String get verificationCodeLabel => 'Codi de verificació';

  @override
  String get newPasswordPrompt => 'Tria una contrasenya nova';

  @override
  String get enterResetCodeAndPassword =>
      'Introdueix el codi que has rebut per correu i la nova contrasenya.';

  @override
  String signupCheckEmailPrompt(Object email) {
    return 'Hem enviat un codi de 6 dígits a $email. Introdueix-lo per crear el compte.';
  }

  @override
  String get confirmPasswordLabel => 'Confirma la contrasenya';

  @override
  String get repeatPasswordHint => 'Repeteix la contrasenya';

  @override
  String get interestsPrompt => 'Què t\'interessa?';

  @override
  String get enterUsername => 'Introdueix el teu nom d\'usuari.';

  @override
  String get enterPassword => 'Introdueix la contrasenya.';

  @override
  String get enterEmail => 'Introdueix el correu electrònic.';

  @override
  String get passwordsDoNotMatch => 'Les contrasenyes no coincideixen.';

  @override
  String get enterCode6Digits => 'Introdueix el codi de 6 dígits.';

  @override
  String get codeMustBe6Digits => 'El codi ha de tenir 6 dígits.';

  @override
  String get invalidEmailFormat => 'Format de correu electrònic no vàlid';

  @override
  String get profileUpdatedSuccessfully => 'Perfil actualitzat correctament';

  @override
  String get emailAlreadyRegistered =>
      'El correu introduït ja està registrat al sistema';

  @override
  String get invalidUsername => 'Nom d\'usuari no vàlid';

  @override
  String get connectionErrorCheckYourConnection =>
      'Error de connexió. Comprova la teva connexió.';

  @override
  String serverErrorWithCode(Object statusCode) {
    return 'Error del servidor (codi $statusCode).';
  }

  @override
  String get googleTokenError => 'No s\'ha pogut obtenir el token de Google.';

  @override
  String get verifyAccountTitle => 'Verifica el compte';

  @override
  String get createAccount => 'Crear compte';

  @override
  String get newPasswordTitle => 'Nova contrasenya';

  @override
  String get savePassword => 'Desar contrasenya';

  @override
  String get forgotPasswordTitle => 'Contrasenya oblidada';

  @override
  String get continueButton => 'Continuar';

  @override
  String get savePasswordButton => 'Desar contrasenya';

  @override
  String get savePasswordSuccess => 'Contrasenya desada correctament';

  @override
  String get retryTryAgain => 'Tornar-ho a provar';

  @override
  String get saveInterestsFailed => 'No s\'han pogut guardar els interessos.';

  @override
  String get editInterestsTitle => 'Editar interessos';

  @override
  String get showAttended => 'Assistits';

  @override
  String get edit => 'Editar';

  @override
  String get confirmDeleteAccount => 'Eliminar el meu compte';

  @override
  String get deleteAccountTitle => 'Eliminar compte';

  @override
  String get sessionExpiredTitle => 'Sessió caducada';

  @override
  String get deleteAccountErrorTitle => 'Error en eliminar el compte';

  @override
  String get ok => 'OK';

  @override
  String get deleteAccountButton => 'Eliminar el meu compte';

  @override
  String get blockedProfilesSubtitle => 'Revisa els perfils que has bloquejat.';

  @override
  String sessionTimeAt(Object timeLabel) {
    return 'A les $timeLabel';
  }

  @override
  String get sessionTimeAtDesc => 'Mostra l\'hora d\'una sessió';

  @override
  String generalAllRatingLabel(Object value) {
    return 'General ($value)';
  }

  @override
  String priceAllRatingLabel(Object value) {
    return 'Preu ($value)';
  }

  @override
  String ambientAllRatingLabel(Object value) {
    return 'Ambient ($value)';
  }

  @override
  String accessibilityAllRatingLabel(Object value) {
    return 'Accessibilitat ($value)';
  }
}
