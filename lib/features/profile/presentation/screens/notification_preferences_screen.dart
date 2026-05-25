import 'package:flutter/material.dart';

import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/services/push_notifications_service.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/features/profile/application/notification_preferences.dart';
import 'package:agendat/features/profile/presentation/widgets/notification_alerts_block.dart';
import 'package:agendat/l10n/app_localizations.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({
    super.key,
    required this.currentProfile,
  });

  final UserProfile currentProfile;

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late NotificationPreferences _notificationPreferences;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notificationPreferences = NotificationPreferences.fromProfile(
      widget.currentProfile,
    );
  }

  Future<void> _persistPreferences({
    required NotificationPreferences requested,
    required NotificationPreferences previous,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(l10n.loginRequired);
      return;
    }

    final result = await updateUserProfile(
      widget.currentProfile.id,
      requested.toJson(),
    );

    if (!mounted) return;

    switch (result) {
      case UpdateProfileSuccess(:final profile):
        await setCurrentLoggedInUser({
          ...currentLoggedInUser ?? <String, dynamic>{},
          ...profile.toJson(),
          'id': profile.id,
          ...requested.toJson(),
        });
        if (requested.notificationsAllowed) {
          await PushNotificationsService.instance
              .requestPermissionAndRegisterDevice();
        } else {
          await PushNotificationsService.instance.unregisterDevice();
        }
        if (!mounted) return;
        setState(() {
          _notificationPreferences = requested;
          _isSaving = false;
        });
      case UpdateProfileFailure(:final statusCode):
        setState(() {
          _notificationPreferences = previous;
          _isSaving = false;
        });
        if (statusCode == 401 || statusCode == 403) {
          _showMessage(l10n.loginRequired);
        } else if (statusCode == -1) {
          _showMessage(l10n.profileConnectionError);
        } else {
          _showMessage(l10n.notificationPreferencesIntro);
        }
      case UpdateProfileValidationError():
        setState(() {
          _notificationPreferences = previous;
          _isSaving = false;
        });
        _showMessage(l10n.notificationPreferencesIntro);
    }
  }

  Future<void> _updateNotificationsAllowed(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(l10n.loginRequired);
      return;
    }

    final previous = _notificationPreferences;
    final requested = previous.withMasterSwitch(enabled);
    setState(() {
      _isSaving = true;
      _notificationPreferences = requested;
    });

    await _persistPreferences(requested: requested, previous: previous);
  }

  Future<void> _updateSubalert({
    required bool value,
    required NotificationPreferenceChannel channel,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(l10n.loginRequired);
      return;
    }

    final previous = _notificationPreferences;
    final requested = previous.withChannel(channel, value);
    setState(() {
      _isSaving = true;
      _notificationPreferences = requested;
    });

    await _persistPreferences(requested: requested, previous: previous);
  }

  void _showMessage(String message) {
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.notificationPreferencesTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: AppScreenSpacing.content,
        children: [
          Text(
            l10n.notificationPreferencesIntro,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          NotificationAlertsBlock(
            notificationsAllowed: _notificationPreferences.notificationsAllowed,
            enabled: !_isSaving,
            onToggleNotifications: _updateNotificationsAllowed,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _notificationPreferences.notificationsAllowed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  SubalertSwitchTile(
                    title: l10n.eventRemindersTitle,
                    subtitle: l10n.eventRemindersSubtitle,
                    value: _notificationPreferences.eventRemindersAllowed,
                    enabled: !_isSaving,
                    onChanged: (value) => _updateSubalert(
                      value: value,
                      channel: NotificationPreferenceChannel.eventReminders,
                    ),
                  ),
                  SubalertSwitchTile(
                    title: l10n.eventChangesTitle,
                    subtitle: l10n.eventChangesSubtitle,
                    value: _notificationPreferences.eventUpdatesAllowed,
                    enabled: !_isSaving,
                    onChanged: (value) => _updateSubalert(
                      value: value,
                      channel: NotificationPreferenceChannel.eventUpdates,
                    ),
                  ),
                  SubalertSwitchTile(
                    title: l10n.socialAlertsTitle,
                    subtitle: l10n.notificationPreferencesIntro,
                    value: _notificationPreferences.socialAlertsAllowed,
                    enabled: !_isSaving,
                    onChanged: (value) => _updateSubalert(
                      value: value,
                      channel: NotificationPreferenceChannel.socialAlerts,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _isSaving ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
