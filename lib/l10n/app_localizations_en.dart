// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Agenda\'t';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navSocial => 'Social';

  @override
  String get navProfile => 'Profile';

  @override
  String get retry => 'Retry';

  @override
  String get noEvents => 'No events.';

  @override
  String get viewRoute => 'View route';

  @override
  String get viewDetails => 'View details';

  @override
  String get detailsTitle => 'Details';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get category => 'Category';

  @override
  String get province => 'Province';

  @override
  String get county => 'County';

  @override
  String get municipality => 'Municipality';

  @override
  String get selectProvince => 'Select a province';

  @override
  String get selectCounty => 'Select a county';

  @override
  String get calendarTab => 'Calendar';

  @override
  String get listTab => 'List';

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get noUpcomingEvents =>
      'You do not have any upcoming scheduled events.';

  @override
  String get loadAgendaFailed => 'Could not load the agenda.';

  @override
  String get loadAgendaListFailed => 'Could not load the list.';

  @override
  String get loadEventsFailed => 'Could not load the events.';

  @override
  String get navigationOpenFailed => 'Could not open navigation.';

  @override
  String distanceFromLocation(Object distance) {
    return '$distance km from your location';
  }

  @override
  String get inviteToSessionTitle => 'Which session do you want to invite to?';

  @override
  String get loadEventSessionsFailed =>
      'Could not load your sessions for this event.';

  @override
  String get noEventSessions =>
      'You do not have any sessions for this event yet. Create a new one to invite your friends.';

  @override
  String get createNewSession => 'Create a new session';

  @override
  String get deleteSessionTitle => 'Delete session';

  @override
  String get deleteSessionBody =>
      'Do you want to delete this session from the agenda?';

  @override
  String get deleteSessionTooltip => 'Delete session';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get allFeminine => 'All';

  @override
  String get allMasculine => 'All';

  @override
  String get cultureNearYou => 'Culture near you';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get change => 'Change';

  @override
  String get confirm => 'Confirm';

  @override
  String get sendSummaryTitle => 'Sending summary';

  @override
  String get close => 'Close';

  @override
  String get horari => 'Schedule';

  @override
  String get privacy => 'Privacy';

  @override
  String get price => 'Price';

  @override
  String get modalitat => 'Mode';

  @override
  String get address => 'Address';

  @override
  String get location => 'Location';

  @override
  String get activityWebsite => 'Activity website';

  @override
  String get localityWebsite => 'Locality website';

  @override
  String get tickets => 'Buy tickets';

  @override
  String get socialTitle => 'Social';

  @override
  String get refresh => 'Refresh';

  @override
  String get myFriends => 'My friends';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get searchRetry => 'Retry';

  @override
  String get noChatsYet => 'You don\'t have any chats yet.';

  @override
  String get noChatsYetSubtitle =>
      'You can start a conversation with any friend.';

  @override
  String get noChatsMatchSearch => 'No chats match the search.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get removeImage => 'Remove image';

  @override
  String get addImage => 'Add image';

  @override
  String get writeMessageHint => 'Write a message...';

  @override
  String get invitationAcceptedRegistered =>
      'Invitation accepted. Attendance registered.';

  @override
  String get invitationRejected => 'Invitation rejected.';

  @override
  String get loginRequiredToManageInvitations =>
      'You must sign in to manage invitations.';

  @override
  String get invitationNoLongerValid => 'This invitation is no longer valid.';

  @override
  String get actionFailedFallback => 'The action could not be completed.';

  @override
  String get invitationSentByYou => 'You sent an invitation';

  @override
  String get invitationReceived => 'You have been invited to an event';

  @override
  String get eventLabel => 'Event';

  @override
  String get invitationStatusPending => 'Pending';

  @override
  String get invitationStatusAccepted => 'Accepted';

  @override
  String get invitationStatusDenied => 'Denied';

  @override
  String get deny => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get imageFormatsOnly => 'Only JPG, JPEG, or PNG images can be sent.';

  @override
  String get emptyImage => 'The selected image is empty.';

  @override
  String get imageSelectFailed => 'Could not select the image.';

  @override
  String get chatOpenFailed => 'Could not open the chat with this friend.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get sendFriendRequest => 'Send friend request';

  @override
  String get friendRequestSentCancel => 'Request sent · Cancel';

  @override
  String get reject => 'Reject';

  @override
  String get removeFriend => 'Remove friend';

  @override
  String get unblock => 'Unblock';

  @override
  String get language => 'Language';

  @override
  String get chooseAppLanguage => 'Choose the app language.';

  @override
  String get blockedUsersSubtitle => 'Review the profiles you have blocked.';

  @override
  String get noBlockedUsers => 'You have not blocked any users.';

  @override
  String get notificationPreferencesTitle => 'Notification preferences';

  @override
  String get eventRemindersTitle => 'Event reminders';

  @override
  String get eventRemindersSubtitle =>
      'Advance alerts so you do not miss sessions or activities.';

  @override
  String get eventChangesTitle => 'Event changes';

  @override
  String get eventChangesSubtitle =>
      'Updates to schedule, location, or cancellations.';

  @override
  String get socialAlertsTitle => 'Social alerts';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editInterests => 'Edit interests';

  @override
  String get languageErrorOffline => 'Connection error. Check your connection.';

  @override
  String get languageSaveFailed => 'Could not save the language.';

  @override
  String get confirmTitle => 'Confirm';

  @override
  String get logoutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String get logout => 'Sign out';

  @override
  String get moreOptions => 'More options';

  @override
  String get blockUser => 'Block user';

  @override
  String get unblockUser => 'Unblock user';

  @override
  String get blockedYou => 'This user has blocked you';

  @override
  String get translate => 'Translate';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get cannotRateEventTitle => 'You can\'t rate this event';

  @override
  String get understood => 'Understood';

  @override
  String get alreadyRatedTitle => 'You have already rated this event';

  @override
  String get deleteReviewTitle => 'Delete review';

  @override
  String get generalRating => 'General';

  @override
  String get priceRating => 'Price';

  @override
  String get ambientRating => 'Atmosphere';

  @override
  String get accessibilityRating => 'Accessibility';

  @override
  String addPhotosCounter(Object maxCount, Object selectedCount) {
    return 'Add photos ($selectedCount/$maxCount)';
  }

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginContinuePrompt => 'Sign in to continue';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get forgotPasswordLink => 'I forgot my password';

  @override
  String get recoverAccess => 'Recover access';

  @override
  String get forgotPasswordPrompt =>
      'Enter the email address for your account. We will send you a 6-digit code.';

  @override
  String get emailAddressLabel => 'Email address';

  @override
  String get emailExampleHint => 'example@email.com';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get newPasswordPrompt => 'Choose a new password';

  @override
  String get enterResetCodeAndPassword =>
      'Enter the code you received by email and the new password.';

  @override
  String signupCheckEmailPrompt(Object email) {
    return 'We sent a 6-digit code to $email. Enter it to create the account.';
  }

  @override
  String get confirmPasswordLabel => 'Confirm the password';

  @override
  String get repeatPasswordHint => 'Repeat the password';

  @override
  String get interestsPrompt => 'What interests you?';

  @override
  String get enterUsername => 'Enter your username.';

  @override
  String get enterPassword => 'Enter the password.';

  @override
  String get enterEmail => 'Enter the email address.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get enterCode6Digits => 'Enter the 6-digit code.';

  @override
  String get codeMustBe6Digits => 'The code must have 6 digits.';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get emailAlreadyRegistered =>
      'The entered email is already registered';

  @override
  String get invalidUsername => 'Invalid username';

  @override
  String get connectionErrorCheckYourConnection =>
      'Connection error. Check your connection.';

  @override
  String serverErrorWithCode(Object statusCode) {
    return 'Server error (code $statusCode).';
  }

  @override
  String get googleTokenError => 'Could not obtain the Google token.';

  @override
  String get verifyAccountTitle => 'Verify account';

  @override
  String get createAccount => 'Create account';

  @override
  String get newPasswordTitle => 'New password';

  @override
  String get savePassword => 'Save password';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get continueButton => 'Continue';

  @override
  String get savePasswordButton => 'Save password';

  @override
  String get savePasswordSuccess => 'Password saved successfully';

  @override
  String get retryTryAgain => 'Try again';

  @override
  String get saveInterestsFailed => 'Could not save the interests.';

  @override
  String get editInterestsTitle => 'Edit interests';

  @override
  String get showAttended => 'Attended';

  @override
  String get edit => 'Edit';

  @override
  String get confirmDeleteAccount => 'Delete my account';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get sessionExpiredTitle => 'Session expired';

  @override
  String get deleteAccountErrorTitle => 'Error deleting the account';

  @override
  String get ok => 'OK';

  @override
  String get deleteAccountButton => 'Delete my account';

  @override
  String get blockedProfilesSubtitle => 'Review the profiles you have blocked.';

  @override
  String sessionTimeAt(Object timeLabel) {
    return 'At $timeLabel';
  }

  @override
  String get sessionTimeAtDesc => 'Shows the time of a session';

  @override
  String generalAllRatingLabel(Object value) {
    return 'General ($value)';
  }

  @override
  String priceAllRatingLabel(Object value) {
    return 'Price ($value)';
  }

  @override
  String ambientAllRatingLabel(Object value) {
    return 'Atmosphere ($value)';
  }

  @override
  String accessibilityAllRatingLabel(Object value) {
    return 'Accessibility ($value)';
  }
}
