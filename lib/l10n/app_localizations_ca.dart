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
  String get dateRange => 'Dates';

  @override
  String get dateFrom => 'Inici';

  @override
  String get dateTo => 'Fi';

  @override
  String get dateRangeInvalid =>
      'La data d\'inici ha de ser anterior a la data fi';

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
  String get noRecommendationsAvailable =>
      'No hi ha recomanacions disponibles.';

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
  String get searchChatHint => 'Cerca un xat';

  @override
  String get filterFriendsHint => 'Filtra els teus amics';

  @override
  String get noChatsMatchSearchSubtitle =>
      'Prova un altre nom o esborra el text per veure tots els xats.';

  @override
  String get loadChatsFailed => 'No s\'ha pogut carregar els xats.';

  @override
  String get addFriend => 'Afegir';

  @override
  String get sharedFriendsOne => '1 amic en comú';

  @override
  String sharedFriendsMany(Object count) {
    return '$count amics en comú';
  }

  @override
  String get unknownUser => 'Usuari desconegut';

  @override
  String get friendRequestAccepted => 'Sol·licitud acceptada. Ara sou amics!';

  @override
  String get friendRequestRejected => 'Sol·licitud rebutjada.';

  @override
  String get friendRequestAcceptFailed =>
      'No s\'ha pogut acceptar la sol·licitud.';

  @override
  String get friendRequestRejectFailed =>
      'No s\'ha pogut rebutjar la sol·licitud.';

  @override
  String get removeImage => 'Treu la imatge';

  @override
  String get addImage => 'Afegir imatge';

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
  String get inactiveUnfriendBanner =>
      'Ja no sou amics amb aquest usuari. El xat es manté al llistat però només pots llegir els missatges anteriors.';

  @override
  String get inactiveBlockedByPartnerBanner =>
      'Aquest usuari t\'ha bloquejat. El xat es manté al llistat però només pots llegir els missatges anteriors.';

  @override
  String get inactiveBlockedByMeBanner =>
      'Has bloquejat aquest usuari. El xat ja no apareix al llistat de converses.';

  @override
  String get chatReadOnlyNotice =>
      'Aquest xat està inactiu. Només podeu llegir la conversa.';

  @override
  String get loadMessagesFailed => 'No s\'han pogut carregar els missatges.';

  @override
  String get sendMessageFailed => 'No s\'ha pogut enviar el missatge.';

  @override
  String get sendImageTooLarge =>
      'La imatge és massa gran. Prova amb una imatge més petita.';

  @override
  String get sendImageServerFailed =>
      'El servidor no ha pogut pujar la imatge. Torna-ho a provar.';

  @override
  String get sendImageFailed => 'No s\'ha pogut enviar la imatge.';

  @override
  String get startChatWithFriendsTitle => 'Inicia xat amb amics';

  @override
  String get noFriendsAvailableToStartChat =>
      'No tens amics disponibles per iniciar un xat.';

  @override
  String get noMessagesYetCanSend =>
      'Encara no hi ha missatges. Envia el primer.';

  @override
  String get noMessagesYetReadOnly =>
      'Encara no hi ha missatges en aquest xat.';

  @override
  String get sent => 'Enviat';

  @override
  String get read => 'Llegit';

  @override
  String get back => 'Enrere';

  @override
  String get createYourAccountTitle => 'Crea el teu compte';

  @override
  String get joinAgendaSubtitle => 'Uneix-te a Agenda\'t';

  @override
  String get usernameUniqueHint => 'Nom d\'usuari únic';

  @override
  String get nameHint => 'El teu nom';

  @override
  String get repeatPasswordHintAuth => 'Repeteix la contrasenya';

  @override
  String get createAccountLoading => 'Creant compte...';

  @override
  String get haveAccountPrompt => 'Ja tens compte?';

  @override
  String get signIn => 'Inicia sessió';

  @override
  String get passwordLabel => 'Contrasenya';

  @override
  String get signupCodeSendFailed =>
      'No s\'ha pogut enviar el codi de verificació.';

  @override
  String get passwordRequirementsHint =>
      'Mín. 8 caràcters, majúscula, minúscula, número i caràcter especial';

  @override
  String get passwordTooShort =>
      'La contrasenya ha de tenir almenys 8 caràcters.';

  @override
  String get passwordNeedsUppercase =>
      'La contrasenya ha de contenir almenys una majúscula.';

  @override
  String get passwordNeedsLowercase =>
      'La contrasenya ha de contenir almenys una minúscula.';

  @override
  String get passwordNeedsNumber =>
      'La contrasenya ha de contenir almenys un número.';

  @override
  String get passwordNeedsSpecialChar =>
      'La contrasenya ha de contenir almenys un caràcter especial.';

  @override
  String get signupTermsText =>
      'En registrar-te acceptes els Termes d\'ús i la Política de privacitat.';

  @override
  String get loadEventFailed => 'No s\'ha pogut carregar l\'esdeveniment.';

  @override
  String get cannotInviteToEvent => 'No es pot convidar a aquest esdeveniment.';

  @override
  String get sessionBeforeEventStart =>
      'La sessió seleccionada és anterior a l\'inici de l\'esdeveniment.';

  @override
  String get sessionAfterEventEnd =>
      'La sessió seleccionada és posterior al final de l\'esdeveniment.';

  @override
  String get createInvitationSessionFailed =>
      'No s\'ha pogut crear la sessió per convidar.';

  @override
  String get invitationSentSuccessfully => 'Invitació enviada correctament.';

  @override
  String invitationSummaryCounts(Object errors, Object successes) {
    return '$successes invitacions enviades · $errors amb error';
  }

  @override
  String get inviteSummaryTitle => 'Resum de l\'enviament';

  @override
  String get inviteSummaryClose => 'Tanca';

  @override
  String get inviteSummaryOk => 'OK';

  @override
  String get inviteInvalidRecipient => 'Usuari destinatari no vàlid.';

  @override
  String get inviteAlreadySent =>
      'Ja has enviat una invitació per aquest esdeveniment.';

  @override
  String get inviteSendFailed => 'No s\'ha pogut enviar la invitació.';

  @override
  String get selectAtLeastOneFriend => 'Selecciona almenys un amic';

  @override
  String get sendOneInvitation => 'Enviar 1 invitació';

  @override
  String sendInvitationsCount(Object count) {
    return 'Enviar $count invitacions';
  }

  @override
  String get invitationPending => 'Pendent';

  @override
  String get invitationAccepted => 'Acceptada';

  @override
  String get invitationDenied => 'Denegada';

  @override
  String get openLinkFailed => 'No s\'ha pogut obrir l\'enllaç.';

  @override
  String get free => 'Gratuït';

  @override
  String get paid => 'De pagament';

  @override
  String get eventInformationTitle => 'Informació de l\'esdeveniment';

  @override
  String get interestingLinksTitle => 'Enllaços d\'interès';

  @override
  String get attendButton => 'Assistir';

  @override
  String get viewOnMap => 'Veure en el mapa';

  @override
  String get publicEvent => 'Públic';

  @override
  String get privateEvent => 'Privat';

  @override
  String get toBeDetermined => 'Per determinar';

  @override
  String get attendanceCalendarSyncDescription =>
      'Sessió sincronitzada automàticament des de l\'aplicació Agenda\'t';

  @override
  String get attendanceCalendarSyncPartial =>
      'Assistència registrada, però no s\'ha pogut afegir a Google Calendar.';

  @override
  String get attendanceRegistered => 'Assistència registrada correctament.';

  @override
  String get attendanceRegisterFailed =>
      'No s\'ha pogut registrar l\'assistència.';

  @override
  String get chatNotAvailableYet =>
      'Aquest xat encara no està disponible. Torna-ho a provar en uns segons.';

  @override
  String get noFriendsYet => 'Encara no tens cap amic.';

  @override
  String get noFriendsYetSubtitle =>
      'Cerca usuaris i envia\'ls una sol·licitud d\'amistat.';

  @override
  String get noFriendsMatchSearch => 'Cap amic coincideix amb la cerca.';

  @override
  String get translate => 'Traduir';

  @override
  String get loginRequired => 'Cal iniciar sessió per continuar.';

  @override
  String get settingsTitle => 'Configuració';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get myProfileTitle => 'El meu perfil';

  @override
  String get moreOptionsTooltip => 'Més opcions';

  @override
  String get blockedUsersTitle => 'Usuaris bloquejats';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get profilePhotoLabel => 'Foto de perfil';

  @override
  String get usernameLabel => 'Nom d\'usuari';

  @override
  String get fullNameLabel => 'Nom complet';

  @override
  String get emailLabel => 'Correu electrònic';

  @override
  String get descriptionLabel => 'Descripció';

  @override
  String get usernameHint => 'El teu nom d\'usuari';

  @override
  String get fullNameHint => 'El teu nom';

  @override
  String get emailHint => 'exemple@correu.com';

  @override
  String get descriptionHint => 'Escriu una descripció sobre tu...';

  @override
  String get changePasswordLabel => 'Canviar contrasenya';

  @override
  String get saveLabel => 'Desar canvis';

  @override
  String get changePasswordComingSoon =>
      'Aquesta funció encara no està disponible.';

  @override
  String get profileImageSelectFailed =>
      'No s\'ha pogut seleccionar la imatge.';

  @override
  String get profileUpdatedSuccess => 'Perfil actualitzat correctament';

  @override
  String get profileUsernameRequired => 'Introdueix un nom d\'usuari.';

  @override
  String get profileEmailRequired => 'Introdueix el correu electrònic.';

  @override
  String get profileInvalidEmail => 'Format de correu electrònic no vàlid';

  @override
  String get profileEmailAlreadyRegistered =>
      'El correu introduït ja està registrat al sistema';

  @override
  String get profileUsernameInvalid => 'Nom d\'usuari no vàlid';

  @override
  String get profileConnectionError =>
      'Error de connexió. Comprova la teva connexió.';

  @override
  String profileServerError(Object statusCode) {
    return 'Error del servidor (codi $statusCode).';
  }

  @override
  String get openInterestsEditorFailed =>
      'No s\'ha pogut obrir l\'editor d\'interessos. Torna a iniciar sessió.';

  @override
  String get interestsUpdatedSuccess =>
      'Preferències actualitzades correctament';

  @override
  String get notificationPreferencesIntro =>
      'Decideix quines alertes vols rebre. Els canvis s\'apliquen al moment.';

  @override
  String get deleteAccountDescription =>
      'Si elimines el teu compte, s\'esborraran les teves dades personals i es tancarà la sessió.';

  @override
  String get deleteAccountConfirmBody =>
      'Estàs segur/a que vols eliminar el teu compte? Aquesta acció no es pot desfer.';

  @override
  String get deleteAccountSessionExpiredBody =>
      'La teva sessió ha caducat. Tanca la sessió i torna a iniciar-la per eliminar el compte.';

  @override
  String get deleteAccountFailureBody =>
      'S\'ha produït un error. Si us plau, torna-ho a intentar més tard.';

  @override
  String get unfriendTitle => 'Eliminar amistat';

  @override
  String unfriendConfirmBody(Object username) {
    return 'Vols eliminar @$username de la teva xarxa d\'amics? Deixareu de tenir un vincle directe i, si voleu, podreu tornar-vos a enviar una sol·licitud d\'amistat en el futur.';
  }

  @override
  String get unfriendSuccess => 'Amistat eliminada.';

  @override
  String get unfriendError => 'No s\'ha pogut eliminar l\'amistat.';

  @override
  String get unfriendUnauthorized =>
      'Cal iniciar sessió per eliminar amistats.';

  @override
  String get unfriendNotFound => 'Perfil no vàlid.';

  @override
  String get unfriendInvalidAction =>
      'Aquesta acció no és vàlida perquè actualment no sou amics.';

  @override
  String blockUserConfirmBody(Object username) {
    return 'Estàs segur/a que vols bloquejar @$username? Si ja sou amics, perdreu l\'amistat. No podrà enviar-te missatges, sol·licituds ni interactuar amb el teu contingut.';
  }

  @override
  String get blockUserSuccess => 'Has bloquejat aquest usuari.';

  @override
  String get blockUserError => 'No s\'ha pogut bloquejar l\'usuari.';

  @override
  String get blockUserUnauthorized =>
      'Cal iniciar sessió per bloquejar usuaris.';

  @override
  String get blockUserNotFound => 'Perfil no vàlid.';

  @override
  String get blockUserAlreadyBlocked => 'Aquest usuari ja estava bloquejat.';

  @override
  String unblockUserConfirmBody(Object username) {
    return 'Vols desbloquejar @$username? Podrà veure el teu perfil i tornar a enviar-te missatges i sol·licituds d\'amistat. L\'amistat anterior no es restableix automàticament.';
  }

  @override
  String get unblockUserSuccess => 'Has desbloquejat aquest usuari.';

  @override
  String get unblockUserError => 'No s\'ha pogut desbloquejar l\'usuari.';

  @override
  String get unblockUserUnauthorized =>
      'Cal iniciar sessió per bloquejar usuaris.';

  @override
  String get unblockUserNotFound => 'Perfil no vàlid.';

  @override
  String get unblockUserAlreadyUnblocked =>
      'Aquest usuari ja no estava bloquejat.';

  @override
  String get myInterestsTitle => 'Els meus interessos';

  @override
  String get interestsTitle => 'Interessos';

  @override
  String get noInterestsAdded => 'Cap interès afegit';

  @override
  String get profileNoDescription => 'Sense descripció';

  @override
  String get profileLevel => 'Nivell';

  @override
  String get profileLevelBronze => 'Nivell Bronze';

  @override
  String get profileLevelSilver => 'Nivell Plata';

  @override
  String get profileLevelGold => 'Nivell Or';

  @override
  String get profileAttendedOnlyOwn =>
      'Assistències només disponibles al teu perfil';

  @override
  String get profileAttendancesLoadFailed =>
      'No s\'han pogut carregar les assistències';

  @override
  String get profileNoAttendances => 'Encara no tens assistències registrades';

  @override
  String get profileNoReviews => 'No hi ha ressenyes';

  @override
  String get profileReviewFallbackEvent => 'Esdeveniment';

  @override
  String interestsSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionats',
      one: '1 seleccionat',
      zero: 'Cap seleccionat',
    );
    return '$_temp0';
  }

  @override
  String get editInterestsLoadCategoriesFailed =>
      'Error en carregar les categories. Refresca la pàgina.';

  @override
  String get registerInterestsLoadFailed =>
      'No s\'han pogut carregar els interessos.';

  @override
  String get registerInterestsTitle => 'Tria els teus interessos';

  @override
  String get registerInterestsSubtitle =>
      'Personalitza les recomanacions culturals';

  @override
  String get registerInterestsInstruction =>
      'Selecciona almenys una categoria per continuar';

  @override
  String get skip => 'Saltar';

  @override
  String get cannotRateEventBody =>
      'Només pots valorar esdeveniments als quals has assistit.';

  @override
  String get alreadyRatedBody =>
      'Ja tens una valoració per aquest esdeveniment. Si la vols canviar, fes servir el llapis de la teva valoració.';

  @override
  String get loadReviewsFailed => 'No s\'ha pogut carregar les valoracions.';

  @override
  String get loadingReviews => 'Carregant valoracions...';

  @override
  String get noReviewsYet => 'Encara no hi ha valoracions.';

  @override
  String get addReview => 'Afegir valoració';

  @override
  String get reviewPublishedSuccess => 'Valoració publicada correctament.';

  @override
  String get reviewUpdatedSuccess => 'Valoració actualitzada correctament.';

  @override
  String get reviewDeletedSuccess => 'Valoració eliminada.';

  @override
  String get reviewDeleteFailed => 'No s\'ha pogut eliminar la valoració.';

  @override
  String get reviewModerationThanks =>
      'Moltes gràcies per la teva valoració, quan l\'haguem validat la publicarem.';

  @override
  String get reviewImageLimitReached =>
      'Una valoració pot contenir com a màxim 3 imatges.';

  @override
  String get reviewClearExistingImagesLabel => 'Eliminar les imatges anteriors';

  @override
  String get reviewClearExistingImagesHelp =>
      'Activa-ho per esborrar les imatges actuals abans de desar les noves.';

  @override
  String get loginRequiredToLike => 'Cal iniciar sessió per fer like.';

  @override
  String get reviewNoCommentToTranslate =>
      'Aquesta valoració no té comentari per traduir.';

  @override
  String get reviewAlreadyInLanguage =>
      'La valoració ja està en aquest idioma.';

  @override
  String get reviewTranslateUnavailable =>
      'Traducció no disponible temporalment.';

  @override
  String get reviewTranslateFailed => 'No s\'ha pogut traduir la valoració.';

  @override
  String get deleteReviewBody =>
      'Segur que vols eliminar la teva valoració? Aquesta acció no es pot desfer.';

  @override
  String get profileNotFound => 'Perfil no trobat.';

  @override
  String get profileUnavailable => 'Perfil no disponible.';

  @override
  String get logoutFailed => 'No s\'ha pogut tancar la sessió.';

  @override
  String get reviewNoEvent => 'Aquesta ressenya no té esdeveniment.';

  @override
  String get sessionNoEvent => 'Aquesta sessió no té esdeveniment.';

  @override
  String get loadFriendsFailed => 'No s\'ha pogut carregar la llista d\'amics.';

  @override
  String get friendRequestNoLongerValid => 'La sol·licitud ja no és vàlida.';

  @override
  String get friendRequestSent => 'Sol·licitud enviada.';

  @override
  String get friendRecommendationNoLongerValid =>
      'La recomanació ja no és vàlida.';

  @override
  String get calendarSyncTitle => 'Sincronitza amb el calendari';

  @override
  String get calendarSyncSubtitle => 'Importa les sessions al teu calendari';

  @override
  String get inviteButton => 'Convidar';

  @override
  String get searchHint => 'Cerca...';

  @override
  String get searchEventsHint => 'Cerca esdeveniments...';

  @override
  String get noResults => 'Cap resultat';

  @override
  String get agendaDetailNoSessions =>
      'No tens cap esdeveniment programat per aquest dia.';

  @override
  String get dateTimeToBeDetermined => 'Data i hora per determinar';

  @override
  String get friendRecommendationsTitle => 'Recomanacions d\'amic';

  @override
  String get peopleYouMightKnowTitle => 'Persones que podries conèixer';

  @override
  String get friendRequestsTitle => 'Sol·licituds d\'amistat';

  @override
  String pendingRequestsToReview(Object count) {
    return '$count pendents per revisar';
  }

  @override
  String get noActiveChatsYet => 'Encara no tens cap conversa activa.';

  @override
  String get noUsersFoundWithThisName =>
      'No s\'ha trobat cap usuari amb aquest nom.';

  @override
  String get loadRecommendationsFailed =>
      'No s\'han pogut carregar les recomanacions.';

  @override
  String get friendRecommendationsOne => '1 recomanació';

  @override
  String friendRecommendationsMany(Object count) {
    return '$count recomanacions';
  }
}
