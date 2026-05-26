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
  String get dateRange => 'Dates';

  @override
  String get dateFrom => 'Start';

  @override
  String get dateTo => 'End';

  @override
  String get dateRangeInvalid => 'The start date must be before the end date';

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
  String get noRecommendationsAvailable => 'No recommendations available.';

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
  String get searchChatHint => 'Search a chat';

  @override
  String get filterFriendsHint => 'Filter your friends';

  @override
  String get noChatsMatchSearchSubtitle =>
      'Try another name or clear the text to see all chats.';

  @override
  String get loadChatsFailed => 'Could not load chats.';

  @override
  String get addFriend => 'Add';

  @override
  String get sharedFriendsOne => '1 shared friend';

  @override
  String sharedFriendsMany(Object count) {
    return '$count shared friends';
  }

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get friendRequestAccepted => 'Request accepted. You are now friends!';

  @override
  String get friendRequestRejected => 'Request rejected.';

  @override
  String get friendRequestAcceptFailed => 'Could not accept the request.';

  @override
  String get friendRequestRejectFailed => 'Could not reject the request.';

  @override
  String get removeImage => 'Remove image';

  @override
  String get addImage => 'Add image';

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
  String get inactiveUnfriendBanner =>
      'You are no longer friends with this user. The chat remains in the list but you can only read previous messages.';

  @override
  String get inactiveBlockedByPartnerBanner =>
      'This user has blocked you. The chat remains in the list but you can only read previous messages.';

  @override
  String get inactiveBlockedByMeBanner =>
      'You have blocked this user. The chat no longer appears in the conversations list.';

  @override
  String get chatReadOnlyNotice =>
      'This chat is inactive. You can only read the conversation.';

  @override
  String get loadMessagesFailed => 'Could not load messages.';

  @override
  String get sendMessageFailed => 'Could not send the message.';

  @override
  String get sendImageTooLarge =>
      'The image is too large. Try a smaller image.';

  @override
  String get sendImageServerFailed =>
      'The server could not upload the image. Try again.';

  @override
  String get sendImageFailed => 'Could not send the image.';

  @override
  String get startChatWithFriendsTitle => 'Start a chat with friends';

  @override
  String get noFriendsAvailableToStartChat =>
      'You have no friends available to start a chat.';

  @override
  String get noMessagesYetCanSend =>
      'There are no messages yet. Send the first one.';

  @override
  String get noMessagesYetReadOnly => 'There are no messages in this chat yet.';

  @override
  String get sent => 'Sent';

  @override
  String get read => 'Read';

  @override
  String get back => 'Back';

  @override
  String get createYourAccountTitle => 'Create your account';

  @override
  String get joinAgendaSubtitle => 'Join Agenda\'t';

  @override
  String get usernameUniqueHint => 'Unique username';

  @override
  String get nameHint => 'Your name';

  @override
  String get repeatPasswordHintAuth => 'Repeat the password';

  @override
  String get createAccountLoading => 'Creating account...';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get signIn => 'Sign in';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signupCodeSendFailed => 'Could not send the verification code.';

  @override
  String get passwordRequirementsHint =>
      'Min. 8 characters, uppercase, lowercase, number, and special character';

  @override
  String get passwordTooShort =>
      'The password must contain at least 8 characters.';

  @override
  String get passwordNeedsUppercase =>
      'The password must contain at least one uppercase letter.';

  @override
  String get passwordNeedsLowercase =>
      'The password must contain at least one lowercase letter.';

  @override
  String get passwordNeedsNumber =>
      'The password must contain at least one number.';

  @override
  String get passwordNeedsSpecialChar =>
      'The password must contain at least one special character.';

  @override
  String get signupTermsText =>
      'By signing up, you accept the Terms of Use and Privacy Policy.';

  @override
  String get loadEventFailed => 'Could not load the event.';

  @override
  String get cannotInviteToEvent => 'You cannot invite to this event.';

  @override
  String get sessionBeforeEventStart =>
      'The selected session is before the start of the event.';

  @override
  String get sessionAfterEventEnd =>
      'The selected session is after the end of the event.';

  @override
  String get createInvitationSessionFailed =>
      'Could not create the session for inviting.';

  @override
  String get invitationSentSuccessfully => 'Invitation sent successfully.';

  @override
  String invitationSummaryCounts(Object errors, Object successes) {
    return '$successes invitations sent · $errors with error';
  }

  @override
  String get inviteSummaryTitle => 'Sending summary';

  @override
  String get inviteSummaryClose => 'Close';

  @override
  String get inviteSummaryOk => 'OK';

  @override
  String get inviteInvalidRecipient => 'Invalid recipient user.';

  @override
  String get inviteAlreadySent =>
      'You have already sent an invitation for this event.';

  @override
  String get inviteSendFailed => 'Could not send the invitation.';

  @override
  String get selectAtLeastOneFriend => 'Select at least one friend';

  @override
  String get sendOneInvitation => 'Send 1 invitation';

  @override
  String sendInvitationsCount(Object count) {
    return 'Send $count invitations';
  }

  @override
  String get invitationPending => 'Pending';

  @override
  String get invitationAccepted => 'Accepted';

  @override
  String get invitationDenied => 'Denied';

  @override
  String get openLinkFailed => 'Could not open the link.';

  @override
  String get free => 'Free';

  @override
  String get paid => 'Paid';

  @override
  String get eventInformationTitle => 'Event information';

  @override
  String get interestingLinksTitle => 'Interesting links';

  @override
  String get attendButton => 'Attend';

  @override
  String get viewOnMap => 'See on the map';

  @override
  String get publicEvent => 'Public';

  @override
  String get privateEvent => 'Private';

  @override
  String get toBeDetermined => 'To be determined';

  @override
  String get attendanceCalendarSyncDescription =>
      'Session synced automatically from the Agenda\'t app';

  @override
  String get attendanceCalendarSyncPartial =>
      'Attendance recorded, but it could not be added to Google Calendar.';

  @override
  String get attendanceRegistered => 'Attendance recorded successfully.';

  @override
  String get attendanceRegisterFailed => 'Could not record attendance.';

  @override
  String get chatNotAvailableYet =>
      'This chat is not available yet. Try again in a few seconds.';

  @override
  String get noFriendsYet => 'You do not have any friends yet.';

  @override
  String get noFriendsYetSubtitle =>
      'Search for users and send them a friend request.';

  @override
  String get noFriendsMatchSearch => 'No friends match the search.';

  @override
  String get translate => 'Translate';

  @override
  String get loginRequired => 'You must sign in to continue.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileTitle => 'Profile';

  @override
  String get myProfileTitle => 'My profile';

  @override
  String get moreOptionsTooltip => 'More options';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get profilePhotoLabel => 'Profile photo';

  @override
  String get usernameLabel => 'Username';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get emailLabel => 'Email address';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get usernameHint => 'Your username';

  @override
  String get fullNameHint => 'Your name';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get descriptionHint => 'Write a description about yourself...';

  @override
  String get changePasswordLabel => 'Change password';

  @override
  String get saveLabel => 'Save changes';

  @override
  String get changePasswordComingSoon => 'This feature is not available yet.';

  @override
  String get profileImageSelectFailed => 'Could not select the image.';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get profileUsernameRequired => 'Enter a username.';

  @override
  String get profileEmailRequired => 'Enter the email address.';

  @override
  String get profileInvalidEmail => 'Invalid email format';

  @override
  String get profileEmailAlreadyRegistered =>
      'The entered email is already registered in the system';

  @override
  String get profileUsernameInvalid => 'Invalid username';

  @override
  String get profileConnectionError =>
      'Connection error. Check your connection.';

  @override
  String profileServerError(Object statusCode) {
    return 'Server error (code $statusCode).';
  }

  @override
  String get openInterestsEditorFailed =>
      'Could not open the interests editor. Please sign in again.';

  @override
  String get interestsUpdatedSuccess => 'Preferences updated successfully';

  @override
  String get notificationPreferencesIntro =>
      'Choose which alerts you want to receive. Changes apply immediately.';

  @override
  String get deleteAccountDescription =>
      'If you delete your account, your personal data will be erased and the session will be closed.';

  @override
  String get deleteAccountConfirmBody =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get deleteAccountSessionExpiredBody =>
      'Your session has expired. Sign out and sign in again to delete the account.';

  @override
  String get deleteAccountFailureBody =>
      'An error occurred. Please try again later.';

  @override
  String get unfriendTitle => 'Remove friend';

  @override
  String unfriendConfirmBody(Object username) {
    return 'Do you want to remove @$username from your friends network? You will no longer have a direct connection and, if you want, you will be able to send each other a friend request again in the future.';
  }

  @override
  String get unfriendSuccess => 'Friendship removed.';

  @override
  String get unfriendError => 'Could not remove the friendship.';

  @override
  String get unfriendUnauthorized => 'You must sign in to remove friends.';

  @override
  String get unfriendNotFound => 'Invalid profile.';

  @override
  String get unfriendInvalidAction =>
      'This action is not valid because you are not currently friends.';

  @override
  String blockUserConfirmBody(Object username) {
    return 'Are you sure you want to block @$username? If you are already friends, the friendship will be lost. They will not be able to send you messages, requests, or interact with your content.';
  }

  @override
  String get blockUserSuccess => 'You have blocked this user.';

  @override
  String get blockUserError => 'Could not block the user.';

  @override
  String get blockUserUnauthorized => 'You must sign in to block users.';

  @override
  String get blockUserNotFound => 'Invalid profile.';

  @override
  String get blockUserAlreadyBlocked => 'This user was already blocked.';

  @override
  String unblockUserConfirmBody(Object username) {
    return 'Do you want to unblock @$username? They will be able to see your profile and send you messages and friend requests again. The previous friendship is not restored automatically.';
  }

  @override
  String get unblockUserSuccess => 'You have unblocked this user.';

  @override
  String get unblockUserError => 'Could not unblock the user.';

  @override
  String get unblockUserUnauthorized => 'You must sign in to block users.';

  @override
  String get unblockUserNotFound => 'Invalid profile.';

  @override
  String get unblockUserAlreadyUnblocked => 'This user was no longer blocked.';

  @override
  String get myInterestsTitle => 'My interests';

  @override
  String get interestsTitle => 'Interests';

  @override
  String get noInterestsAdded => 'No interests added yet';

  @override
  String get profileNoDescription => 'No description';

  @override
  String get profileLevel => 'Level';

  @override
  String get profileLevelBronze => 'Bronze level';

  @override
  String get profileLevelSilver => 'Silver level';

  @override
  String get profileLevelGold => 'Gold level';

  @override
  String get profileAttendedOnlyOwn =>
      'Attendances are only available on your profile';

  @override
  String get profileAttendancesLoadFailed => 'Could not load attendances';

  @override
  String get profileNoAttendances =>
      'You do not have any registered attendances yet';

  @override
  String get profileNoReviews => 'No reviews';

  @override
  String get profileReviewFallbackEvent => 'Event';

  @override
  String interestsSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'None selected',
    );
    return '$_temp0';
  }

  @override
  String get editInterestsLoadCategoriesFailed =>
      'Could not load the categories. Refresh the page.';

  @override
  String get registerInterestsLoadFailed => 'Could not load the interests.';

  @override
  String get registerInterestsTitle => 'Choose your interests';

  @override
  String get registerInterestsSubtitle =>
      'Personalize your cultural recommendations';

  @override
  String get registerInterestsInstruction =>
      'Select at least one category to continue';

  @override
  String get skip => 'Skip';

  @override
  String get cannotRateEventBody =>
      'You can only rate events you have attended.';

  @override
  String get alreadyRatedBody =>
      'You already have a review for this event. To change it, use the edit icon on your review.';

  @override
  String get loadReviewsFailed => 'Could not load reviews.';

  @override
  String get loadingReviews => 'Loading reviews...';

  @override
  String get noReviewsYet => 'There are no reviews yet.';

  @override
  String get addReview => 'Add review';

  @override
  String get reviewPublishedSuccess => 'Review published successfully.';

  @override
  String get reviewUpdatedSuccess => 'Review updated successfully.';

  @override
  String get reviewDeletedSuccess => 'Review deleted.';

  @override
  String get reviewDeleteFailed => 'Could not delete the review.';

  @override
  String get reviewModerationThanks =>
      'Thanks for your review — we will publish it once validated.';

  @override
  String get reviewImageLimitReached =>
      'A review can contain at most 3 images.';

  @override
  String get reviewClearExistingImagesLabel => 'Remove previous images';

  @override
  String get reviewClearExistingImagesHelp =>
      'Enable this to delete current images before saving the new ones.';

  @override
  String get loginRequiredToLike => 'You must sign in to like.';

  @override
  String get reviewNoCommentToTranslate =>
      'This review has no comment to translate.';

  @override
  String get reviewAlreadyInLanguage =>
      'The review is already in this language.';

  @override
  String get reviewTranslateUnavailable =>
      'Translation temporarily unavailable.';

  @override
  String get reviewTranslateFailed => 'Could not translate the review.';

  @override
  String get deleteReviewBody =>
      'Are you sure you want to delete your review? This action cannot be undone.';

  @override
  String get profileNotFound => 'Profile not found.';

  @override
  String get profileUnavailable => 'Profile unavailable.';

  @override
  String get logoutFailed => 'Could not sign out.';

  @override
  String get reviewNoEvent => 'This review has no event.';

  @override
  String get sessionNoEvent => 'This session has no event.';

  @override
  String get loadFriendsFailed => 'Could not load friends list.';

  @override
  String get friendRequestNoLongerValid => 'Request is no longer valid.';

  @override
  String get friendRequestSent => 'Request sent.';

  @override
  String get friendRecommendationNoLongerValid =>
      'Recommendation is no longer valid.';

  @override
  String get calendarSyncTitle => 'Sync with calendar';

  @override
  String get calendarSyncSubtitle => 'Import sessions to your calendar';

  @override
  String get inviteButton => 'Invite';

  @override
  String get searchHint => 'Search...';

  @override
  String get searchEventsHint => 'Search events...';

  @override
  String get noResults => 'No results';

  @override
  String get agendaDetailNoSessions =>
      'You do not have any events scheduled for this day.';

  @override
  String get dateTimeToBeDetermined => 'Date and time to be determined';

  @override
  String get friendRecommendationsTitle => 'Friend recommendations';

  @override
  String get peopleYouMightKnowTitle => 'People you might know';

  @override
  String get friendRequestsTitle => 'Friend requests';

  @override
  String pendingRequestsToReview(Object count) {
    return '$count pending to review';
  }

  @override
  String get noActiveChatsYet => 'You do not have any active chats yet.';

  @override
  String get noUsersFoundWithThisName => 'No user was found with this name.';

  @override
  String get loadRecommendationsFailed => 'Could not load recommendations.';

  @override
  String get friendRecommendationsOne => '1 recommendation';

  @override
  String friendRecommendationsMany(Object count) {
    return '$count recommendations';
  }
}
