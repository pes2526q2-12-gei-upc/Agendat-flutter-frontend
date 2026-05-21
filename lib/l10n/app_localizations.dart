import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsCa();
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In ca, this message translates to:
  /// **'Agenda\'t'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In ca, this message translates to:
  /// **'Inici'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In ca, this message translates to:
  /// **'Mapa'**
  String get navMap;

  /// No description provided for @navAgenda.
  ///
  /// In ca, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navSocial.
  ///
  /// In ca, this message translates to:
  /// **'Social'**
  String get navSocial;

  /// No description provided for @navProfile.
  ///
  /// In ca, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @retry.
  ///
  /// In ca, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @noEvents.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha esdeveniments.'**
  String get noEvents;

  /// No description provided for @viewRoute.
  ///
  /// In ca, this message translates to:
  /// **'Veure ruta'**
  String get viewRoute;

  /// No description provided for @viewDetails.
  ///
  /// In ca, this message translates to:
  /// **'Veure detalls'**
  String get viewDetails;

  /// No description provided for @detailsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Detalls'**
  String get detailsTitle;

  /// No description provided for @agendaTitle.
  ///
  /// In ca, this message translates to:
  /// **'Agenda'**
  String get agendaTitle;

  /// No description provided for @filtersTitle.
  ///
  /// In ca, this message translates to:
  /// **'Filtres'**
  String get filtersTitle;

  /// No description provided for @category.
  ///
  /// In ca, this message translates to:
  /// **'Categoria'**
  String get category;

  /// No description provided for @province.
  ///
  /// In ca, this message translates to:
  /// **'Província'**
  String get province;

  /// No description provided for @county.
  ///
  /// In ca, this message translates to:
  /// **'Comarca'**
  String get county;

  /// No description provided for @municipality.
  ///
  /// In ca, this message translates to:
  /// **'Municipi'**
  String get municipality;

  /// No description provided for @selectProvince.
  ///
  /// In ca, this message translates to:
  /// **'Selecciona una província'**
  String get selectProvince;

  /// No description provided for @selectCounty.
  ///
  /// In ca, this message translates to:
  /// **'Selecciona una comarca'**
  String get selectCounty;

  /// No description provided for @calendarTab.
  ///
  /// In ca, this message translates to:
  /// **'Calendari'**
  String get calendarTab;

  /// No description provided for @listTab.
  ///
  /// In ca, this message translates to:
  /// **'Llista'**
  String get listTab;

  /// No description provided for @sessionsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Sessions'**
  String get sessionsTitle;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In ca, this message translates to:
  /// **'No tens cap esdeveniment programat pròximament.'**
  String get noUpcomingEvents;

  /// No description provided for @loadAgendaFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar l\'agenda.'**
  String get loadAgendaFailed;

  /// No description provided for @loadAgendaListFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar la llista.'**
  String get loadAgendaListFailed;

  /// No description provided for @loadEventsFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han pogut carregar els esdeveniments.'**
  String get loadEventsFailed;

  /// No description provided for @navigationOpenFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut obrir la navegació.'**
  String get navigationOpenFailed;

  /// No description provided for @distanceFromLocation.
  ///
  /// In ca, this message translates to:
  /// **'{distance} km des de la teva ubicació'**
  String distanceFromLocation(Object distance);

  /// No description provided for @inviteToSessionTitle.
  ///
  /// In ca, this message translates to:
  /// **'A quina sessió convides?'**
  String get inviteToSessionTitle;

  /// No description provided for @loadEventSessionsFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han pogut carregar les teves sessions per a aquest esdeveniment.'**
  String get loadEventSessionsFailed;

  /// No description provided for @noEventSessions.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens cap sessió per aquest esdeveniment. Crea\'n una de nova per convidar als teus amics.'**
  String get noEventSessions;

  /// No description provided for @createNewSession.
  ///
  /// In ca, this message translates to:
  /// **'Crea una sessió nova'**
  String get createNewSession;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar sessió'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In ca, this message translates to:
  /// **'Vols eliminar aquesta sessió de l’agenda?'**
  String get deleteSessionBody;

  /// No description provided for @deleteSessionTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar sessió'**
  String get deleteSessionTooltip;

  /// No description provided for @cancel.
  ///
  /// In ca, this message translates to:
  /// **'Cancel·lar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @applyFilters.
  ///
  /// In ca, this message translates to:
  /// **'Aplicar filtres'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In ca, this message translates to:
  /// **'Netejar filtres'**
  String get clearFilters;

  /// No description provided for @allFeminine.
  ///
  /// In ca, this message translates to:
  /// **'Totes'**
  String get allFeminine;

  /// No description provided for @allMasculine.
  ///
  /// In ca, this message translates to:
  /// **'Tots'**
  String get allMasculine;

  /// No description provided for @cultureNearYou.
  ///
  /// In ca, this message translates to:
  /// **'La cultura a prop teu'**
  String get cultureNearYou;

  /// No description provided for @date.
  ///
  /// In ca, this message translates to:
  /// **'Data'**
  String get date;

  /// No description provided for @time.
  ///
  /// In ca, this message translates to:
  /// **'Hora'**
  String get time;

  /// No description provided for @change.
  ///
  /// In ca, this message translates to:
  /// **'Canvia'**
  String get change;

  /// No description provided for @confirm.
  ///
  /// In ca, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @sendSummaryTitle.
  ///
  /// In ca, this message translates to:
  /// **'Resum de l\'enviament'**
  String get sendSummaryTitle;

  /// No description provided for @close.
  ///
  /// In ca, this message translates to:
  /// **'Tanca'**
  String get close;

  /// No description provided for @horari.
  ///
  /// In ca, this message translates to:
  /// **'Horari'**
  String get horari;

  /// No description provided for @privacy.
  ///
  /// In ca, this message translates to:
  /// **'Privacitat'**
  String get privacy;

  /// No description provided for @price.
  ///
  /// In ca, this message translates to:
  /// **'Preu'**
  String get price;

  /// No description provided for @modalitat.
  ///
  /// In ca, this message translates to:
  /// **'Modalitat'**
  String get modalitat;

  /// No description provided for @address.
  ///
  /// In ca, this message translates to:
  /// **'Adreça'**
  String get address;

  /// No description provided for @location.
  ///
  /// In ca, this message translates to:
  /// **'Ubicació'**
  String get location;

  /// No description provided for @activityWebsite.
  ///
  /// In ca, this message translates to:
  /// **'Web de l\'activitat'**
  String get activityWebsite;

  /// No description provided for @localityWebsite.
  ///
  /// In ca, this message translates to:
  /// **'Web de la localitat'**
  String get localityWebsite;

  /// No description provided for @tickets.
  ///
  /// In ca, this message translates to:
  /// **'Compra d\'entrades'**
  String get tickets;

  /// No description provided for @socialTitle.
  ///
  /// In ca, this message translates to:
  /// **'Social'**
  String get socialTitle;

  /// No description provided for @refresh.
  ///
  /// In ca, this message translates to:
  /// **'Actualitza'**
  String get refresh;

  /// No description provided for @myFriends.
  ///
  /// In ca, this message translates to:
  /// **'Els meus amics'**
  String get myFriends;

  /// No description provided for @deleteTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Esborra'**
  String get deleteTooltip;

  /// No description provided for @searchRetry.
  ///
  /// In ca, this message translates to:
  /// **'Reintentar'**
  String get searchRetry;

  /// No description provided for @noChatsYet.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens cap xat.'**
  String get noChatsYet;

  /// No description provided for @noChatsYetSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Pots iniciar una conversa amb qualsevol amic.'**
  String get noChatsYetSubtitle;

  /// No description provided for @noChatsMatchSearch.
  ///
  /// In ca, this message translates to:
  /// **'Cap xat coincideix amb la cerca.'**
  String get noChatsMatchSearch;

  /// No description provided for @clearSearch.
  ///
  /// In ca, this message translates to:
  /// **'Esborra cerca'**
  String get clearSearch;

  /// No description provided for @removeImage.
  ///
  /// In ca, this message translates to:
  /// **'Treu la imatge'**
  String get removeImage;

  /// No description provided for @addImage.
  ///
  /// In ca, this message translates to:
  /// **'Afegir imatge'**
  String get addImage;

  /// No description provided for @writeMessageHint.
  ///
  /// In ca, this message translates to:
  /// **'Escriu un missatge...'**
  String get writeMessageHint;

  /// No description provided for @invitationAcceptedRegistered.
  ///
  /// In ca, this message translates to:
  /// **'Invitació acceptada. Assistència registrada.'**
  String get invitationAcceptedRegistered;

  /// No description provided for @invitationRejected.
  ///
  /// In ca, this message translates to:
  /// **'Invitació rebutjada.'**
  String get invitationRejected;

  /// No description provided for @loginRequiredToManageInvitations.
  ///
  /// In ca, this message translates to:
  /// **'Cal iniciar sessió per gestionar invitacions.'**
  String get loginRequiredToManageInvitations;

  /// No description provided for @invitationNoLongerValid.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta invitació ja no és vàlida.'**
  String get invitationNoLongerValid;

  /// No description provided for @actionFailedFallback.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut completar l\'acció.'**
  String get actionFailedFallback;

  /// No description provided for @invitationSentByYou.
  ///
  /// In ca, this message translates to:
  /// **'Has enviat una invitació'**
  String get invitationSentByYou;

  /// No description provided for @invitationReceived.
  ///
  /// In ca, this message translates to:
  /// **'T\'han convidat a un esdeveniment'**
  String get invitationReceived;

  /// No description provided for @eventLabel.
  ///
  /// In ca, this message translates to:
  /// **'Esdeveniment'**
  String get eventLabel;

  /// No description provided for @invitationStatusPending.
  ///
  /// In ca, this message translates to:
  /// **'Pendent'**
  String get invitationStatusPending;

  /// No description provided for @invitationStatusAccepted.
  ///
  /// In ca, this message translates to:
  /// **'Acceptada'**
  String get invitationStatusAccepted;

  /// No description provided for @invitationStatusDenied.
  ///
  /// In ca, this message translates to:
  /// **'Denegada'**
  String get invitationStatusDenied;

  /// No description provided for @deny.
  ///
  /// In ca, this message translates to:
  /// **'Denegar'**
  String get deny;

  /// No description provided for @accept.
  ///
  /// In ca, this message translates to:
  /// **'Acceptar'**
  String get accept;

  /// No description provided for @imageFormatsOnly.
  ///
  /// In ca, this message translates to:
  /// **'Només es poden enviar imatges JPG, JPEG o PNG.'**
  String get imageFormatsOnly;

  /// No description provided for @emptyImage.
  ///
  /// In ca, this message translates to:
  /// **'La imatge seleccionada és buida.'**
  String get emptyImage;

  /// No description provided for @imageSelectFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut seleccionar la imatge.'**
  String get imageSelectFailed;

  /// No description provided for @chatOpenFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut obrir el xat amb aquest amic.'**
  String get chatOpenFailed;

  /// No description provided for @chatsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Xats'**
  String get chatsTitle;

  /// No description provided for @sendFriendRequest.
  ///
  /// In ca, this message translates to:
  /// **'Enviar sol·licitud d\'amistat'**
  String get sendFriendRequest;

  /// No description provided for @friendRequestSentCancel.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licitud enviada · Cancel·lar'**
  String get friendRequestSentCancel;

  /// No description provided for @reject.
  ///
  /// In ca, this message translates to:
  /// **'Rebutjar'**
  String get reject;

  /// No description provided for @removeFriend.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar amistat'**
  String get removeFriend;

  /// No description provided for @unblock.
  ///
  /// In ca, this message translates to:
  /// **'Desbloquejar'**
  String get unblock;

  /// No description provided for @language.
  ///
  /// In ca, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @chooseAppLanguage.
  ///
  /// In ca, this message translates to:
  /// **'Tria l\'idioma de l\'aplicació.'**
  String get chooseAppLanguage;

  /// No description provided for @blockedUsersSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Revisa els perfils que has bloquejat.'**
  String get blockedUsersSubtitle;

  /// No description provided for @noBlockedUsers.
  ///
  /// In ca, this message translates to:
  /// **'No has bloquejat cap usuari.'**
  String get noBlockedUsers;

  /// No description provided for @notificationPreferencesTitle.
  ///
  /// In ca, this message translates to:
  /// **'Preferències d\'alertes'**
  String get notificationPreferencesTitle;

  /// No description provided for @eventRemindersTitle.
  ///
  /// In ca, this message translates to:
  /// **'Recordatoris d\'esdeveniments'**
  String get eventRemindersTitle;

  /// No description provided for @eventRemindersSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Avisos previs per no perdre sessions o activitats.'**
  String get eventRemindersSubtitle;

  /// No description provided for @eventChangesTitle.
  ///
  /// In ca, this message translates to:
  /// **'Canvis en esdeveniments'**
  String get eventChangesTitle;

  /// No description provided for @eventChangesSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Actualitzacions d\'horari, ubicació o cancel·lacions.'**
  String get eventChangesSubtitle;

  /// No description provided for @socialAlertsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Alertes socials'**
  String get socialAlertsTitle;

  /// No description provided for @editProfile.
  ///
  /// In ca, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @editInterests.
  ///
  /// In ca, this message translates to:
  /// **'Editar interessos'**
  String get editInterests;

  /// No description provided for @languageErrorOffline.
  ///
  /// In ca, this message translates to:
  /// **'Error de connexió. Comprova la teva connexió.'**
  String get languageErrorOffline;

  /// No description provided for @languageSaveFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut desar l\'idioma.'**
  String get languageSaveFailed;

  /// No description provided for @confirmTitle.
  ///
  /// In ca, this message translates to:
  /// **'Confirma'**
  String get confirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In ca, this message translates to:
  /// **'Estàs segur/a que vols tancar la sessió?'**
  String get logoutConfirmBody;

  /// No description provided for @logout.
  ///
  /// In ca, this message translates to:
  /// **'Tancar sessió'**
  String get logout;

  /// No description provided for @moreOptions.
  ///
  /// In ca, this message translates to:
  /// **'Més opcions'**
  String get moreOptions;

  /// No description provided for @blockUser.
  ///
  /// In ca, this message translates to:
  /// **'Bloquejar usuari'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In ca, this message translates to:
  /// **'Desbloquejar usuari'**
  String get unblockUser;

  /// No description provided for @blockedYou.
  ///
  /// In ca, this message translates to:
  /// **'Aquest usuari t\'ha bloquejat'**
  String get blockedYou;

  /// No description provided for @translate.
  ///
  /// In ca, this message translates to:
  /// **'Traduir'**
  String get translate;

  /// No description provided for @reviewsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Ressenyes'**
  String get reviewsTitle;

  /// No description provided for @cannotRateEventTitle.
  ///
  /// In ca, this message translates to:
  /// **'No pots valorar aquest esdeveniment'**
  String get cannotRateEventTitle;

  /// No description provided for @understood.
  ///
  /// In ca, this message translates to:
  /// **'Entesos'**
  String get understood;

  /// No description provided for @alreadyRatedTitle.
  ///
  /// In ca, this message translates to:
  /// **'Ja has valorat aquest esdeveniment'**
  String get alreadyRatedTitle;

  /// No description provided for @deleteReviewTitle.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar valoració'**
  String get deleteReviewTitle;

  /// No description provided for @generalRating.
  ///
  /// In ca, this message translates to:
  /// **'General'**
  String get generalRating;

  /// No description provided for @priceRating.
  ///
  /// In ca, this message translates to:
  /// **'Preu'**
  String get priceRating;

  /// No description provided for @ambientRating.
  ///
  /// In ca, this message translates to:
  /// **'Ambient'**
  String get ambientRating;

  /// No description provided for @accessibilityRating.
  ///
  /// In ca, this message translates to:
  /// **'Accessibilitat'**
  String get accessibilityRating;

  /// No description provided for @addPhotosCounter.
  ///
  /// In ca, this message translates to:
  /// **'Afegir fotos ({selectedCount}/{maxCount})'**
  String addPhotosCounter(Object maxCount, Object selectedCount);

  /// No description provided for @loginTitle.
  ///
  /// In ca, this message translates to:
  /// **'Inicia sessió'**
  String get loginTitle;

  /// No description provided for @loginContinuePrompt.
  ///
  /// In ca, this message translates to:
  /// **'Inicia sessió per continuar'**
  String get loginContinuePrompt;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ca, this message translates to:
  /// **'Continua amb Google'**
  String get continueWithGoogle;

  /// No description provided for @orContinueWith.
  ///
  /// In ca, this message translates to:
  /// **'o continua amb'**
  String get orContinueWith;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In ca, this message translates to:
  /// **'He oblidat la meva contrasenya'**
  String get forgotPasswordLink;

  /// No description provided for @recoverAccess.
  ///
  /// In ca, this message translates to:
  /// **'Recupera l\'accés'**
  String get recoverAccess;

  /// No description provided for @forgotPasswordPrompt.
  ///
  /// In ca, this message translates to:
  /// **'Escriu el correu del teu compte. T\'enviarem un codi de 6 dígits.'**
  String get forgotPasswordPrompt;

  /// No description provided for @emailAddressLabel.
  ///
  /// In ca, this message translates to:
  /// **'Correu electrònic'**
  String get emailAddressLabel;

  /// No description provided for @emailExampleHint.
  ///
  /// In ca, this message translates to:
  /// **'exemple@correu.cat'**
  String get emailExampleHint;

  /// No description provided for @checkYourEmail.
  ///
  /// In ca, this message translates to:
  /// **'Revisa el teu correu'**
  String get checkYourEmail;

  /// No description provided for @verificationCodeLabel.
  ///
  /// In ca, this message translates to:
  /// **'Codi de verificació'**
  String get verificationCodeLabel;

  /// No description provided for @newPasswordPrompt.
  ///
  /// In ca, this message translates to:
  /// **'Tria una contrasenya nova'**
  String get newPasswordPrompt;

  /// No description provided for @enterResetCodeAndPassword.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el codi que has rebut per correu i la nova contrasenya.'**
  String get enterResetCodeAndPassword;

  /// No description provided for @signupCheckEmailPrompt.
  ///
  /// In ca, this message translates to:
  /// **'Hem enviat un codi de 6 dígits a {email}. Introdueix-lo per crear el compte.'**
  String signupCheckEmailPrompt(Object email);

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In ca, this message translates to:
  /// **'Confirma la contrasenya'**
  String get confirmPasswordLabel;

  /// No description provided for @repeatPasswordHint.
  ///
  /// In ca, this message translates to:
  /// **'Repeteix la contrasenya'**
  String get repeatPasswordHint;

  /// No description provided for @interestsPrompt.
  ///
  /// In ca, this message translates to:
  /// **'Què t\'interessa?'**
  String get interestsPrompt;

  /// No description provided for @enterUsername.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el teu nom d\'usuari.'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix la contrasenya.'**
  String get enterPassword;

  /// No description provided for @enterEmail.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el correu electrònic.'**
  String get enterEmail;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ca, this message translates to:
  /// **'Les contrasenyes no coincideixen.'**
  String get passwordsDoNotMatch;

  /// No description provided for @enterCode6Digits.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el codi de 6 dígits.'**
  String get enterCode6Digits;

  /// No description provided for @codeMustBe6Digits.
  ///
  /// In ca, this message translates to:
  /// **'El codi ha de tenir 6 dígits.'**
  String get codeMustBe6Digits;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In ca, this message translates to:
  /// **'Format de correu electrònic no vàlid'**
  String get invalidEmailFormat;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In ca, this message translates to:
  /// **'Perfil actualitzat correctament'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In ca, this message translates to:
  /// **'El correu introduït ja està registrat al sistema'**
  String get emailAlreadyRegistered;

  /// No description provided for @invalidUsername.
  ///
  /// In ca, this message translates to:
  /// **'Nom d\'usuari no vàlid'**
  String get invalidUsername;

  /// No description provided for @connectionErrorCheckYourConnection.
  ///
  /// In ca, this message translates to:
  /// **'Error de connexió. Comprova la teva connexió.'**
  String get connectionErrorCheckYourConnection;

  /// No description provided for @serverErrorWithCode.
  ///
  /// In ca, this message translates to:
  /// **'Error del servidor (codi {statusCode}).'**
  String serverErrorWithCode(Object statusCode);

  /// No description provided for @googleTokenError.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut obtenir el token de Google.'**
  String get googleTokenError;

  /// No description provided for @verifyAccountTitle.
  ///
  /// In ca, this message translates to:
  /// **'Verifica el compte'**
  String get verifyAccountTitle;

  /// No description provided for @createAccount.
  ///
  /// In ca, this message translates to:
  /// **'Crear compte'**
  String get createAccount;

  /// No description provided for @newPasswordTitle.
  ///
  /// In ca, this message translates to:
  /// **'Nova contrasenya'**
  String get newPasswordTitle;

  /// No description provided for @savePassword.
  ///
  /// In ca, this message translates to:
  /// **'Desar contrasenya'**
  String get savePassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ca, this message translates to:
  /// **'Contrasenya oblidada'**
  String get forgotPasswordTitle;

  /// No description provided for @continueButton.
  ///
  /// In ca, this message translates to:
  /// **'Continuar'**
  String get continueButton;

  /// No description provided for @savePasswordButton.
  ///
  /// In ca, this message translates to:
  /// **'Desar contrasenya'**
  String get savePasswordButton;

  /// No description provided for @savePasswordSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Contrasenya desada correctament'**
  String get savePasswordSuccess;

  /// No description provided for @retryTryAgain.
  ///
  /// In ca, this message translates to:
  /// **'Tornar-ho a provar'**
  String get retryTryAgain;

  /// No description provided for @saveInterestsFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han pogut guardar els interessos.'**
  String get saveInterestsFailed;

  /// No description provided for @editInterestsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Editar interessos'**
  String get editInterestsTitle;

  /// No description provided for @showAttended.
  ///
  /// In ca, this message translates to:
  /// **'Assistits'**
  String get showAttended;

  /// No description provided for @edit.
  ///
  /// In ca, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar el meu compte'**
  String get confirmDeleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar compte'**
  String get deleteAccountTitle;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In ca, this message translates to:
  /// **'Sessió caducada'**
  String get sessionExpiredTitle;

  /// No description provided for @deleteAccountErrorTitle.
  ///
  /// In ca, this message translates to:
  /// **'Error en eliminar el compte'**
  String get deleteAccountErrorTitle;

  /// No description provided for @ok.
  ///
  /// In ca, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deleteAccountButton.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar el meu compte'**
  String get deleteAccountButton;

  /// No description provided for @blockedProfilesSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Revisa els perfils que has bloquejat.'**
  String get blockedProfilesSubtitle;

  /// No description provided for @sessionTimeAt.
  ///
  /// In ca, this message translates to:
  /// **'A les {timeLabel}'**
  String sessionTimeAt(Object timeLabel);

  /// No description provided for @sessionTimeAtDesc.
  ///
  /// In ca, this message translates to:
  /// **'Mostra l\'hora d\'una sessió'**
  String get sessionTimeAtDesc;

  /// No description provided for @generalAllRatingLabel.
  ///
  /// In ca, this message translates to:
  /// **'General ({value})'**
  String generalAllRatingLabel(Object value);

  /// No description provided for @priceAllRatingLabel.
  ///
  /// In ca, this message translates to:
  /// **'Preu ({value})'**
  String priceAllRatingLabel(Object value);

  /// No description provided for @ambientAllRatingLabel.
  ///
  /// In ca, this message translates to:
  /// **'Ambient ({value})'**
  String ambientAllRatingLabel(Object value);

  /// No description provided for @accessibilityAllRatingLabel.
  ///
  /// In ca, this message translates to:
  /// **'Accessibilitat ({value})'**
  String accessibilityAllRatingLabel(Object value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
