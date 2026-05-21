import 'package:flutter/material.dart';

import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/presentation/widgets/notification_alerts_block.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/api/profile_api.dart';

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
  static const _unauthenticatedMessage =
      'Cal iniciar sessió per configurar alertes.';

  late bool _notificationsAllowed;
  late bool _eventRemindersAllowed;
  late bool _eventUpdatesAllowed;
  late bool _socialAlertsAllowed;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notificationsAllowed = widget.currentProfile.notificationsAllowed;
    _eventRemindersAllowed = widget.currentProfile.eventRemindersAllowed;
    _eventUpdatesAllowed = widget.currentProfile.eventUpdatesAllowed;
    _socialAlertsAllowed = widget.currentProfile.socialAlertsAllowed;
  }

  Future<void> _persistPreferences() async {
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(_unauthenticatedMessage);
      return;
    }

    final previousNotificationsAllowed = _notificationsAllowed;
    final previousEventReminders = _eventRemindersAllowed;
    final previousEventUpdates = _eventUpdatesAllowed;
    final previousSocialAlerts = _socialAlertsAllowed;

    final result = await updateUserProfile(widget.currentProfile.id, {
      'notifications_allowed': _notificationsAllowed,
      'event_reminders_allowed': _eventRemindersAllowed,
      'event_updates_allowed': _eventUpdatesAllowed,
      'social_alerts_allowed': _socialAlertsAllowed,
    });

    if (!mounted) return;

    switch (result) {
      case UpdateProfileSuccess(:final profile):
        await setCurrentLoggedInUser({
          ...currentLoggedInUser ?? <String, dynamic>{},
          ...profile.toJson(),
          'id': profile.id,
        });
        setState(() {
          _notificationsAllowed = profile.notificationsAllowed;
          _eventRemindersAllowed = profile.eventRemindersAllowed;
          _eventUpdatesAllowed = profile.eventUpdatesAllowed;
          _socialAlertsAllowed = profile.socialAlertsAllowed;
          _isSaving = false;
        });
      case UpdateProfileFailure(:final statusCode):
        setState(() {
          _notificationsAllowed = previousNotificationsAllowed;
          _eventRemindersAllowed = previousEventReminders;
          _eventUpdatesAllowed = previousEventUpdates;
          _socialAlertsAllowed = previousSocialAlerts;
          _isSaving = false;
        });
        if (statusCode == 401 || statusCode == 403) {
          _showMessage(_unauthenticatedMessage);
        } else if (statusCode == -1) {
          _showMessage('Error de connexió. Comprova la teva connexió.');
        } else {
          _showMessage('No s\'han pogut desar les preferències d\'alertes.');
        }
      case UpdateProfileValidationError():
        setState(() {
          _notificationsAllowed = previousNotificationsAllowed;
          _eventRemindersAllowed = previousEventReminders;
          _eventUpdatesAllowed = previousEventUpdates;
          _socialAlertsAllowed = previousSocialAlerts;
          _isSaving = false;
        });
        _showMessage('No s\'han pogut desar les preferències d\'alertes.');
    }
  }

  Future<void> _updateNotificationsAllowed(bool enabled) async {
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(_unauthenticatedMessage);
      return;
    }

    setState(() {
      _isSaving = true;
      _notificationsAllowed = enabled;
      _eventRemindersAllowed = enabled;
      _eventUpdatesAllowed = enabled;
      _socialAlertsAllowed = enabled;
    });

    await _persistPreferences();
  }

  Future<void> _updateSubalert({
    required bool value,
    required void Function(bool value) assignLocalValue,
  }) async {
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(_unauthenticatedMessage);
      return;
    }

    setState(() {
      _isSaving = true;
      assignLocalValue(value);
      _notificationsAllowed =
          _eventRemindersAllowed ||
          _eventUpdatesAllowed ||
          _socialAlertsAllowed;
    });

    await _persistPreferences();
  }

  void _showMessage(String message) {
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Preferències d\'alertes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: AppScreenSpacing.content,
        children: [
          Text(
            'Decideix quines alertes vols rebre. Els canvis s\'apliquen al moment.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          NotificationAlertsBlock(
            notificationsAllowed: _notificationsAllowed,
            enabled: !_isSaving,
            onToggleNotifications: _updateNotificationsAllowed,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _notificationsAllowed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  SubalertSwitchTile(
                    title: 'Recordatoris d\'esdeveniments',
                    subtitle:
                        'Avisos previs per no perdre sessions o activitats.',
                    value: _eventRemindersAllowed,
                    enabled: !_isSaving,
                    onChanged: (value) => _updateSubalert(
                      value: value,
                      assignLocalValue: (nextValue) {
                        _eventRemindersAllowed = nextValue;
                      },
                    ),
                  ),
                  SubalertSwitchTile(
                    title: 'Canvis en esdeveniments',
                    subtitle:
                        'Actualitzacions d\'horari, ubicació o cancel·lacions.',
                    value: _eventUpdatesAllowed,
                    enabled: !_isSaving,
                    onChanged: (value) => _updateSubalert(
                      value: value,
                      assignLocalValue: (nextValue) {
                        _eventUpdatesAllowed = nextValue;
                      },
                    ),
                  ),
                  SubalertSwitchTile(
                    title: 'Alertes socials',
                    subtitle:
                        'Notificacions relacionades amb amistats i activitat social.',
                    value: _socialAlertsAllowed,
                    enabled: !_isSaving,
                    onChanged: (value) => _updateSubalert(
                      value: value,
                      assignLocalValue: (nextValue) {
                        _socialAlertsAllowed = nextValue;
                      },
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
