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
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @noRecommendationsAvailable.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha recomanacions disponibles.'**
  String get noRecommendationsAvailable;

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

  /// No description provided for @searchChatHint.
  ///
  /// In ca, this message translates to:
  /// **'Cerca un xat'**
  String get searchChatHint;

  /// No description provided for @filterFriendsHint.
  ///
  /// In ca, this message translates to:
  /// **'Filtra els teus amics'**
  String get filterFriendsHint;

  /// No description provided for @noChatsMatchSearchSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Prova un altre nom o esborra el text per veure tots els xats.'**
  String get noChatsMatchSearchSubtitle;

  /// No description provided for @loadChatsFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar els xats.'**
  String get loadChatsFailed;

  /// No description provided for @addFriend.
  ///
  /// In ca, this message translates to:
  /// **'Afegir'**
  String get addFriend;

  /// No description provided for @sharedFriendsOne.
  ///
  /// In ca, this message translates to:
  /// **'1 amic en comú'**
  String get sharedFriendsOne;

  /// No description provided for @sharedFriendsMany.
  ///
  /// In ca, this message translates to:
  /// **'{count} amics en comú'**
  String sharedFriendsMany(Object count);

  /// No description provided for @unknownUser.
  ///
  /// In ca, this message translates to:
  /// **'Usuari desconegut'**
  String get unknownUser;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licitud acceptada. Ara sou amics!'**
  String get friendRequestAccepted;

  /// No description provided for @friendRequestRejected.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licitud rebutjada.'**
  String get friendRequestRejected;

  /// No description provided for @friendRequestAcceptFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut acceptar la sol·licitud.'**
  String get friendRequestAcceptFailed;

  /// No description provided for @friendRequestRejectFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut rebutjar la sol·licitud.'**
  String get friendRequestRejectFailed;

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

  /// No description provided for @inactiveUnfriendBanner.
  ///
  /// In ca, this message translates to:
  /// **'Ja no sou amics amb aquest usuari. El xat es manté al llistat però només pots llegir els missatges anteriors.'**
  String get inactiveUnfriendBanner;

  /// No description provided for @inactiveBlockedByPartnerBanner.
  ///
  /// In ca, this message translates to:
  /// **'Aquest usuari t\'ha bloquejat. El xat es manté al llistat però només pots llegir els missatges anteriors.'**
  String get inactiveBlockedByPartnerBanner;

  /// No description provided for @inactiveBlockedByMeBanner.
  ///
  /// In ca, this message translates to:
  /// **'Has bloquejat aquest usuari. El xat ja no apareix al llistat de converses.'**
  String get inactiveBlockedByMeBanner;

  /// No description provided for @chatReadOnlyNotice.
  ///
  /// In ca, this message translates to:
  /// **'Aquest xat està inactiu. Només podeu llegir la conversa.'**
  String get chatReadOnlyNotice;

  /// No description provided for @loadMessagesFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han pogut carregar els missatges.'**
  String get loadMessagesFailed;

  /// No description provided for @sendMessageFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut enviar el missatge.'**
  String get sendMessageFailed;

  /// No description provided for @sendImageTooLarge.
  ///
  /// In ca, this message translates to:
  /// **'La imatge és massa gran. Prova amb una imatge més petita.'**
  String get sendImageTooLarge;

  /// No description provided for @sendImageServerFailed.
  ///
  /// In ca, this message translates to:
  /// **'El servidor no ha pogut pujar la imatge. Torna-ho a provar.'**
  String get sendImageServerFailed;

  /// No description provided for @sendImageFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut enviar la imatge.'**
  String get sendImageFailed;

  /// No description provided for @startChatWithFriendsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Inicia xat amb amics'**
  String get startChatWithFriendsTitle;

  /// No description provided for @noFriendsAvailableToStartChat.
  ///
  /// In ca, this message translates to:
  /// **'No tens amics disponibles per iniciar un xat.'**
  String get noFriendsAvailableToStartChat;

  /// No description provided for @noMessagesYetCanSend.
  ///
  /// In ca, this message translates to:
  /// **'Encara no hi ha missatges. Envia el primer.'**
  String get noMessagesYetCanSend;

  /// No description provided for @noMessagesYetReadOnly.
  ///
  /// In ca, this message translates to:
  /// **'Encara no hi ha missatges en aquest xat.'**
  String get noMessagesYetReadOnly;

  /// No description provided for @sent.
  ///
  /// In ca, this message translates to:
  /// **'Enviat'**
  String get sent;

  /// No description provided for @read.
  ///
  /// In ca, this message translates to:
  /// **'Llegit'**
  String get read;

  /// No description provided for @back.
  ///
  /// In ca, this message translates to:
  /// **'Enrere'**
  String get back;

  /// No description provided for @createYourAccountTitle.
  ///
  /// In ca, this message translates to:
  /// **'Crea el teu compte'**
  String get createYourAccountTitle;

  /// No description provided for @joinAgendaSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Uneix-te a Agenda\'t'**
  String get joinAgendaSubtitle;

  /// No description provided for @usernameUniqueHint.
  ///
  /// In ca, this message translates to:
  /// **'Nom d\'usuari únic'**
  String get usernameUniqueHint;

  /// No description provided for @nameHint.
  ///
  /// In ca, this message translates to:
  /// **'El teu nom'**
  String get nameHint;

  /// No description provided for @repeatPasswordHintAuth.
  ///
  /// In ca, this message translates to:
  /// **'Repeteix la contrasenya'**
  String get repeatPasswordHintAuth;

  /// No description provided for @createAccountLoading.
  ///
  /// In ca, this message translates to:
  /// **'Creant compte...'**
  String get createAccountLoading;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In ca, this message translates to:
  /// **'Ja tens compte?'**
  String get haveAccountPrompt;

  /// No description provided for @signIn.
  ///
  /// In ca, this message translates to:
  /// **'Inicia sessió'**
  String get signIn;

  /// No description provided for @passwordLabel.
  ///
  /// In ca, this message translates to:
  /// **'Contrasenya'**
  String get passwordLabel;

  /// No description provided for @signupCodeSendFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut enviar el codi de verificació.'**
  String get signupCodeSendFailed;

  /// No description provided for @passwordRequirementsHint.
  ///
  /// In ca, this message translates to:
  /// **'Mín. 8 caràcters, majúscula, minúscula, número i caràcter especial'**
  String get passwordRequirementsHint;

  /// No description provided for @passwordTooShort.
  ///
  /// In ca, this message translates to:
  /// **'La contrasenya ha de tenir almenys 8 caràcters.'**
  String get passwordTooShort;

  /// No description provided for @passwordNeedsUppercase.
  ///
  /// In ca, this message translates to:
  /// **'La contrasenya ha de contenir almenys una majúscula.'**
  String get passwordNeedsUppercase;

  /// No description provided for @passwordNeedsLowercase.
  ///
  /// In ca, this message translates to:
  /// **'La contrasenya ha de contenir almenys una minúscula.'**
  String get passwordNeedsLowercase;

  /// No description provided for @passwordNeedsNumber.
  ///
  /// In ca, this message translates to:
  /// **'La contrasenya ha de contenir almenys un número.'**
  String get passwordNeedsNumber;

  /// No description provided for @passwordNeedsSpecialChar.
  ///
  /// In ca, this message translates to:
  /// **'La contrasenya ha de contenir almenys un caràcter especial.'**
  String get passwordNeedsSpecialChar;

  /// No description provided for @signupTermsText.
  ///
  /// In ca, this message translates to:
  /// **'En registrar-te acceptes els Termes d\'ús i la Política de privacitat.'**
  String get signupTermsText;

  /// No description provided for @loadEventFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar l\'esdeveniment.'**
  String get loadEventFailed;

  /// No description provided for @cannotInviteToEvent.
  ///
  /// In ca, this message translates to:
  /// **'No es pot convidar a aquest esdeveniment.'**
  String get cannotInviteToEvent;

  /// No description provided for @sessionBeforeEventStart.
  ///
  /// In ca, this message translates to:
  /// **'La sessió seleccionada és anterior a l\'inici de l\'esdeveniment.'**
  String get sessionBeforeEventStart;

  /// No description provided for @sessionAfterEventEnd.
  ///
  /// In ca, this message translates to:
  /// **'La sessió seleccionada és posterior al final de l\'esdeveniment.'**
  String get sessionAfterEventEnd;

  /// No description provided for @createInvitationSessionFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut crear la sessió per convidar.'**
  String get createInvitationSessionFailed;

  /// No description provided for @invitationSentSuccessfully.
  ///
  /// In ca, this message translates to:
  /// **'Invitació enviada correctament.'**
  String get invitationSentSuccessfully;

  /// No description provided for @invitationSummaryCounts.
  ///
  /// In ca, this message translates to:
  /// **'{successes} invitacions enviades · {errors} amb error'**
  String invitationSummaryCounts(Object errors, Object successes);

  /// No description provided for @inviteSummaryTitle.
  ///
  /// In ca, this message translates to:
  /// **'Resum de l\'enviament'**
  String get inviteSummaryTitle;

  /// No description provided for @inviteSummaryClose.
  ///
  /// In ca, this message translates to:
  /// **'Tanca'**
  String get inviteSummaryClose;

  /// No description provided for @inviteSummaryOk.
  ///
  /// In ca, this message translates to:
  /// **'OK'**
  String get inviteSummaryOk;

  /// No description provided for @inviteInvalidRecipient.
  ///
  /// In ca, this message translates to:
  /// **'Usuari destinatari no vàlid.'**
  String get inviteInvalidRecipient;

  /// No description provided for @inviteAlreadySent.
  ///
  /// In ca, this message translates to:
  /// **'Ja has enviat una invitació per aquest esdeveniment.'**
  String get inviteAlreadySent;

  /// No description provided for @inviteSendFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut enviar la invitació.'**
  String get inviteSendFailed;

  /// No description provided for @selectAtLeastOneFriend.
  ///
  /// In ca, this message translates to:
  /// **'Selecciona almenys un amic'**
  String get selectAtLeastOneFriend;

  /// No description provided for @sendOneInvitation.
  ///
  /// In ca, this message translates to:
  /// **'Enviar 1 invitació'**
  String get sendOneInvitation;

  /// No description provided for @sendInvitationsCount.
  ///
  /// In ca, this message translates to:
  /// **'Enviar {count} invitacions'**
  String sendInvitationsCount(Object count);

  /// No description provided for @invitationPending.
  ///
  /// In ca, this message translates to:
  /// **'Pendent'**
  String get invitationPending;

  /// No description provided for @invitationAccepted.
  ///
  /// In ca, this message translates to:
  /// **'Acceptada'**
  String get invitationAccepted;

  /// No description provided for @invitationDenied.
  ///
  /// In ca, this message translates to:
  /// **'Denegada'**
  String get invitationDenied;

  /// No description provided for @openLinkFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut obrir l\'enllaç.'**
  String get openLinkFailed;

  /// No description provided for @free.
  ///
  /// In ca, this message translates to:
  /// **'Gratuït'**
  String get free;

  /// No description provided for @paid.
  ///
  /// In ca, this message translates to:
  /// **'De pagament'**
  String get paid;

  /// No description provided for @eventInformationTitle.
  ///
  /// In ca, this message translates to:
  /// **'Informació de l\'esdeveniment'**
  String get eventInformationTitle;

  /// No description provided for @interestingLinksTitle.
  ///
  /// In ca, this message translates to:
  /// **'Enllaços d\'interès'**
  String get interestingLinksTitle;

  /// No description provided for @attendButton.
  ///
  /// In ca, this message translates to:
  /// **'Assistir'**
  String get attendButton;

  /// No description provided for @viewOnMap.
  ///
  /// In ca, this message translates to:
  /// **'Veure en el mapa'**
  String get viewOnMap;

  /// No description provided for @publicEvent.
  ///
  /// In ca, this message translates to:
  /// **'Públic'**
  String get publicEvent;

  /// No description provided for @privateEvent.
  ///
  /// In ca, this message translates to:
  /// **'Privat'**
  String get privateEvent;

  /// No description provided for @toBeDetermined.
  ///
  /// In ca, this message translates to:
  /// **'Per determinar'**
  String get toBeDetermined;

  /// No description provided for @attendanceCalendarSyncDescription.
  ///
  /// In ca, this message translates to:
  /// **'Sessió sincronitzada automàticament des de l\'aplicació Agenda\'t'**
  String get attendanceCalendarSyncDescription;

  /// No description provided for @attendanceCalendarSyncPartial.
  ///
  /// In ca, this message translates to:
  /// **'Assistència registrada, però no s\'ha pogut afegir a Google Calendar.'**
  String get attendanceCalendarSyncPartial;

  /// No description provided for @attendanceRegistered.
  ///
  /// In ca, this message translates to:
  /// **'Assistència registrada correctament.'**
  String get attendanceRegistered;

  /// No description provided for @attendanceRegisterFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut registrar l\'assistència.'**
  String get attendanceRegisterFailed;

  /// No description provided for @chatNotAvailableYet.
  ///
  /// In ca, this message translates to:
  /// **'Aquest xat encara no està disponible. Torna-ho a provar en uns segons.'**
  String get chatNotAvailableYet;

  /// No description provided for @noFriendsYet.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens cap amic.'**
  String get noFriendsYet;

  /// No description provided for @noFriendsYetSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Cerca usuaris i envia\'ls una sol·licitud d\'amistat.'**
  String get noFriendsYetSubtitle;

  /// No description provided for @noFriendsMatchSearch.
  ///
  /// In ca, this message translates to:
  /// **'Cap amic coincideix amb la cerca.'**
  String get noFriendsMatchSearch;

  /// No description provided for @translate.
  ///
  /// In ca, this message translates to:
  /// **'Traduir'**
  String get translate;

  /// No description provided for @loginRequired.
  ///
  /// In ca, this message translates to:
  /// **'Cal iniciar sessió per continuar.'**
  String get loginRequired;

  /// No description provided for @settingsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Configuració'**
  String get settingsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In ca, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @myProfileTitle.
  ///
  /// In ca, this message translates to:
  /// **'El meu perfil'**
  String get myProfileTitle;

  /// No description provided for @moreOptionsTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Més opcions'**
  String get moreOptionsTooltip;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In ca, this message translates to:
  /// **'Usuaris bloquejats'**
  String get blockedUsersTitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In ca, this message translates to:
  /// **'Editar perfil'**
  String get editProfileTitle;

  /// No description provided for @profilePhotoLabel.
  ///
  /// In ca, this message translates to:
  /// **'Foto de perfil'**
  String get profilePhotoLabel;

  /// No description provided for @usernameLabel.
  ///
  /// In ca, this message translates to:
  /// **'Nom d\'usuari'**
  String get usernameLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In ca, this message translates to:
  /// **'Nom complet'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In ca, this message translates to:
  /// **'Correu electrònic'**
  String get emailLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In ca, this message translates to:
  /// **'Descripció'**
  String get descriptionLabel;

  /// No description provided for @usernameHint.
  ///
  /// In ca, this message translates to:
  /// **'El teu nom d\'usuari'**
  String get usernameHint;

  /// No description provided for @fullNameHint.
  ///
  /// In ca, this message translates to:
  /// **'El teu nom'**
  String get fullNameHint;

  /// No description provided for @emailHint.
  ///
  /// In ca, this message translates to:
  /// **'exemple@correu.com'**
  String get emailHint;

  /// No description provided for @descriptionHint.
  ///
  /// In ca, this message translates to:
  /// **'Escriu una descripció sobre tu...'**
  String get descriptionHint;

  /// No description provided for @changePasswordLabel.
  ///
  /// In ca, this message translates to:
  /// **'Canviar contrasenya'**
  String get changePasswordLabel;

  /// No description provided for @saveLabel.
  ///
  /// In ca, this message translates to:
  /// **'Desar canvis'**
  String get saveLabel;

  /// No description provided for @changePasswordComingSoon.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta funció encara no està disponible.'**
  String get changePasswordComingSoon;

  /// No description provided for @profileImageSelectFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut seleccionar la imatge.'**
  String get profileImageSelectFailed;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Perfil actualitzat correctament'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUsernameRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix un nom d\'usuari.'**
  String get profileUsernameRequired;

  /// No description provided for @profileEmailRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el correu electrònic.'**
  String get profileEmailRequired;

  /// No description provided for @profileInvalidEmail.
  ///
  /// In ca, this message translates to:
  /// **'Format de correu electrònic no vàlid'**
  String get profileInvalidEmail;

  /// No description provided for @profileEmailAlreadyRegistered.
  ///
  /// In ca, this message translates to:
  /// **'El correu introduït ja està registrat al sistema'**
  String get profileEmailAlreadyRegistered;

  /// No description provided for @profileUsernameInvalid.
  ///
  /// In ca, this message translates to:
  /// **'Nom d\'usuari no vàlid'**
  String get profileUsernameInvalid;

  /// No description provided for @profileConnectionError.
  ///
  /// In ca, this message translates to:
  /// **'Error de connexió. Comprova la teva connexió.'**
  String get profileConnectionError;

  /// No description provided for @profileServerError.
  ///
  /// In ca, this message translates to:
  /// **'Error del servidor (codi {statusCode}).'**
  String profileServerError(Object statusCode);

  /// No description provided for @openInterestsEditorFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut obrir l\'editor d\'interessos. Torna a iniciar sessió.'**
  String get openInterestsEditorFailed;

  /// No description provided for @interestsUpdatedSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Preferències actualitzades correctament'**
  String get interestsUpdatedSuccess;

  /// No description provided for @notificationPreferencesIntro.
  ///
  /// In ca, this message translates to:
  /// **'Decideix quines alertes vols rebre. Els canvis s\'apliquen al moment.'**
  String get notificationPreferencesIntro;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In ca, this message translates to:
  /// **'Si elimines el teu compte, s\'esborraran les teves dades personals i es tancarà la sessió.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In ca, this message translates to:
  /// **'Estàs segur/a que vols eliminar el teu compte? Aquesta acció no es pot desfer.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountSessionExpiredBody.
  ///
  /// In ca, this message translates to:
  /// **'La teva sessió ha caducat. Tanca la sessió i torna a iniciar-la per eliminar el compte.'**
  String get deleteAccountSessionExpiredBody;

  /// No description provided for @deleteAccountFailureBody.
  ///
  /// In ca, this message translates to:
  /// **'S\'ha produït un error. Si us plau, torna-ho a intentar més tard.'**
  String get deleteAccountFailureBody;

  /// No description provided for @unfriendTitle.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar amistat'**
  String get unfriendTitle;

  /// No description provided for @unfriendConfirmBody.
  ///
  /// In ca, this message translates to:
  /// **'Vols eliminar @{username} de la teva xarxa d\'amics? Deixareu de tenir un vincle directe i, si voleu, podreu tornar-vos a enviar una sol·licitud d\'amistat en el futur.'**
  String unfriendConfirmBody(Object username);

  /// No description provided for @unfriendSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Amistat eliminada.'**
  String get unfriendSuccess;

  /// No description provided for @unfriendError.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut eliminar l\'amistat.'**
  String get unfriendError;

  /// No description provided for @unfriendUnauthorized.
  ///
  /// In ca, this message translates to:
  /// **'Cal iniciar sessió per eliminar amistats.'**
  String get unfriendUnauthorized;

  /// No description provided for @unfriendNotFound.
  ///
  /// In ca, this message translates to:
  /// **'Perfil no vàlid.'**
  String get unfriendNotFound;

  /// No description provided for @unfriendInvalidAction.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta acció no és vàlida perquè actualment no sou amics.'**
  String get unfriendInvalidAction;

  /// No description provided for @blockUserConfirmBody.
  ///
  /// In ca, this message translates to:
  /// **'Estàs segur/a que vols bloquejar @{username}? Si ja sou amics, perdreu l\'amistat. No podrà enviar-te missatges, sol·licituds ni interactuar amb el teu contingut.'**
  String blockUserConfirmBody(Object username);

  /// No description provided for @blockUserSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Has bloquejat aquest usuari.'**
  String get blockUserSuccess;

  /// No description provided for @blockUserError.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut bloquejar l\'usuari.'**
  String get blockUserError;

  /// No description provided for @blockUserUnauthorized.
  ///
  /// In ca, this message translates to:
  /// **'Cal iniciar sessió per bloquejar usuaris.'**
  String get blockUserUnauthorized;

  /// No description provided for @blockUserNotFound.
  ///
  /// In ca, this message translates to:
  /// **'Perfil no vàlid.'**
  String get blockUserNotFound;

  /// No description provided for @blockUserAlreadyBlocked.
  ///
  /// In ca, this message translates to:
  /// **'Aquest usuari ja estava bloquejat.'**
  String get blockUserAlreadyBlocked;

  /// No description provided for @unblockUserConfirmBody.
  ///
  /// In ca, this message translates to:
  /// **'Vols desbloquejar @{username}? Podrà veure el teu perfil i tornar a enviar-te missatges i sol·licituds d\'amistat. L\'amistat anterior no es restableix automàticament.'**
  String unblockUserConfirmBody(Object username);

  /// No description provided for @unblockUserSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Has desbloquejat aquest usuari.'**
  String get unblockUserSuccess;

  /// No description provided for @unblockUserError.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut desbloquejar l\'usuari.'**
  String get unblockUserError;

  /// No description provided for @unblockUserUnauthorized.
  ///
  /// In ca, this message translates to:
  /// **'Cal iniciar sessió per bloquejar usuaris.'**
  String get unblockUserUnauthorized;

  /// No description provided for @unblockUserNotFound.
  ///
  /// In ca, this message translates to:
  /// **'Perfil no vàlid.'**
  String get unblockUserNotFound;

  /// No description provided for @unblockUserAlreadyUnblocked.
  ///
  /// In ca, this message translates to:
  /// **'Aquest usuari ja no estava bloquejat.'**
  String get unblockUserAlreadyUnblocked;

  /// No description provided for @myInterestsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Els meus interessos'**
  String get myInterestsTitle;

  /// No description provided for @interestsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Interessos'**
  String get interestsTitle;

  /// No description provided for @noInterestsAdded.
  ///
  /// In ca, this message translates to:
  /// **'Cap interès afegit'**
  String get noInterestsAdded;

  /// No description provided for @cannotRateEventBody.
  ///
  /// In ca, this message translates to:
  /// **'Només pots valorar esdeveniments als quals has assistit.'**
  String get cannotRateEventBody;

  /// No description provided for @alreadyRatedBody.
  ///
  /// In ca, this message translates to:
  /// **'Ja tens una valoració per aquest esdeveniment. Si la vols canviar, fes servir el llapis de la teva valoració.'**
  String get alreadyRatedBody;

  /// No description provided for @loadReviewsFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar les valoracions.'**
  String get loadReviewsFailed;

  /// No description provided for @loadingReviews.
  ///
  /// In ca, this message translates to:
  /// **'Carregant valoracions...'**
  String get loadingReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In ca, this message translates to:
  /// **'Encara no hi ha valoracions.'**
  String get noReviewsYet;

  /// No description provided for @addReview.
  ///
  /// In ca, this message translates to:
  /// **'Afegir valoració'**
  String get addReview;

  /// No description provided for @reviewPublishedSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Valoració publicada correctament.'**
  String get reviewPublishedSuccess;

  /// No description provided for @reviewUpdatedSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Valoració actualitzada correctament.'**
  String get reviewUpdatedSuccess;

  /// No description provided for @reviewDeletedSuccess.
  ///
  /// In ca, this message translates to:
  /// **'Valoració eliminada.'**
  String get reviewDeletedSuccess;

  /// No description provided for @reviewDeleteFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut eliminar la valoració.'**
  String get reviewDeleteFailed;

  /// No description provided for @reviewModerationThanks.
  ///
  /// In ca, this message translates to:
  /// **'Moltes gràcies per la teva valoració, quan l\'haguem validat la publicarem.'**
  String get reviewModerationThanks;

  /// No description provided for @reviewImageLimitReached.
  ///
  /// In ca, this message translates to:
  /// **'Una valoració pot contenir com a màxim 3 imatges.'**
  String get reviewImageLimitReached;

  /// No description provided for @reviewClearExistingImagesLabel.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar les imatges anteriors'**
  String get reviewClearExistingImagesLabel;

  /// No description provided for @reviewClearExistingImagesHelp.
  ///
  /// In ca, this message translates to:
  /// **'Activa-ho per esborrar les imatges actuals abans de desar les noves.'**
  String get reviewClearExistingImagesHelp;

  /// No description provided for @loginRequiredToLike.
  ///
  /// In ca, this message translates to:
  /// **'Cal iniciar sessió per fer like.'**
  String get loginRequiredToLike;

  /// No description provided for @reviewNoCommentToTranslate.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta valoració no té comentari per traduir.'**
  String get reviewNoCommentToTranslate;

  /// No description provided for @reviewAlreadyInLanguage.
  ///
  /// In ca, this message translates to:
  /// **'La valoració ja està en aquest idioma.'**
  String get reviewAlreadyInLanguage;

  /// No description provided for @reviewTranslateUnavailable.
  ///
  /// In ca, this message translates to:
  /// **'Traducció no disponible temporalment.'**
  String get reviewTranslateUnavailable;

  /// No description provided for @reviewTranslateFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut traduir la valoració.'**
  String get reviewTranslateFailed;

  /// No description provided for @deleteReviewBody.
  ///
  /// In ca, this message translates to:
  /// **'Segur que vols eliminar la teva valoració? Aquesta acció no es pot desfer.'**
  String get deleteReviewBody;

  /// No description provided for @profileNotFound.
  ///
  /// In ca, this message translates to:
  /// **'Perfil no trobat.'**
  String get profileNotFound;

  /// No description provided for @profileUnavailable.
  ///
  /// In ca, this message translates to:
  /// **'Perfil no disponible.'**
  String get profileUnavailable;

  /// No description provided for @logoutFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut tancar la sessió.'**
  String get logoutFailed;

  /// No description provided for @reviewNoEvent.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta ressenya no té esdeveniment.'**
  String get reviewNoEvent;

  /// No description provided for @sessionNoEvent.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta sessió no té esdeveniment.'**
  String get sessionNoEvent;

  /// No description provided for @loadFriendsFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar la llista d\'amics.'**
  String get loadFriendsFailed;

  /// No description provided for @friendRequestNoLongerValid.
  ///
  /// In ca, this message translates to:
  /// **'La sol·licitud ja no és vàlida.'**
  String get friendRequestNoLongerValid;

  /// No description provided for @friendRequestSent.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licitud enviada.'**
  String get friendRequestSent;

  /// No description provided for @friendRecommendationNoLongerValid.
  ///
  /// In ca, this message translates to:
  /// **'La recomanació ja no és vàlida.'**
  String get friendRecommendationNoLongerValid;

  /// No description provided for @calendarSyncTitle.
  ///
  /// In ca, this message translates to:
  /// **'Sincronitza amb el calendari'**
  String get calendarSyncTitle;

  /// No description provided for @calendarSyncSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Importa les sessions al teu calendari'**
  String get calendarSyncSubtitle;

  /// No description provided for @inviteButton.
  ///
  /// In ca, this message translates to:
  /// **'Convidar'**
  String get inviteButton;

  /// No description provided for @searchHint.
  ///
  /// In ca, this message translates to:
  /// **'Cerca...'**
  String get searchHint;

  /// No description provided for @searchEventsHint.
  ///
  /// In ca, this message translates to:
  /// **'Cerca esdeveniments...'**
  String get searchEventsHint;

  /// No description provided for @noResults.
  ///
  /// In ca, this message translates to:
  /// **'Cap resultat'**
  String get noResults;

  /// No description provided for @agendaDetailNoSessions.
  ///
  /// In ca, this message translates to:
  /// **'No tens cap esdeveniment programat per aquest dia.'**
  String get agendaDetailNoSessions;

  /// No description provided for @dateTimeToBeDetermined.
  ///
  /// In ca, this message translates to:
  /// **'Data i hora per determinar'**
  String get dateTimeToBeDetermined;

  /// No description provided for @friendRecommendationsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Recomanacions d\'amic'**
  String get friendRecommendationsTitle;

  /// No description provided for @peopleYouMightKnowTitle.
  ///
  /// In ca, this message translates to:
  /// **'Persones que podries conèixer'**
  String get peopleYouMightKnowTitle;

  /// No description provided for @friendRequestsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licituds d\'amistat'**
  String get friendRequestsTitle;

  /// No description provided for @pendingRequestsToReview.
  ///
  /// In ca, this message translates to:
  /// **'{count} pendents per revisar'**
  String pendingRequestsToReview(Object count);

  /// No description provided for @noActiveChatsYet.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens cap conversa activa.'**
  String get noActiveChatsYet;

  /// No description provided for @noUsersFoundWithThisName.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha trobat cap usuari amb aquest nom.'**
  String get noUsersFoundWithThisName;

  /// No description provided for @loadRecommendationsFailed.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han pogut carregar les recomanacions.'**
  String get loadRecommendationsFailed;

  /// No description provided for @friendRecommendationsOne.
  ///
  /// In ca, this message translates to:
  /// **'1 recomanació'**
  String get friendRecommendationsOne;

  /// No description provided for @friendRecommendationsMany.
  ///
  /// In ca, this message translates to:
  /// **'{count} recomanacions'**
  String friendRecommendationsMany(Object count);
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
