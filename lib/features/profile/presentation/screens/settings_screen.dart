import 'package:flutter/material.dart';

import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/services/push_notifications_service.dart';
import 'package:agendat/core/services/user_preferences_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/features/profile/application/notification_preferences.dart';
import 'package:agendat/features/profile/presentation/screens/blockedUsers.dart';
import 'package:agendat/features/profile/presentation/widgets/language_selector_tile.dart';
import 'package:agendat/features/profile/presentation/widgets/notification_alerts_block.dart';
import 'package:agendat/core/utils/event_text_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.currentProfile});

  final UserProfile currentProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _unauthenticatedMessage =
      LanguageSelectorTile.unauthenticatedMessageDefault;

  late NotificationPreferences _notificationPreferences;
  late bool _calendarSyncAllowed;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notificationPreferences = NotificationPreferences.fromProfile(
      widget.currentProfile,
    );
    _calendarSyncAllowed = widget.currentProfile.calendarSyncAllowed;
  }

  Future<void> _persistPreferences({
    required NotificationPreferences requested,
    required NotificationPreferences previous,
  }) async {
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(_unauthenticatedMessage);
      return;
    }

    final previousCalendarSync = _calendarSyncAllowed;

    final result = await updateUserProfile(widget.currentProfile.id, {
      ...requested.toJson(),
      'calendar_sync_allowed': _calendarSyncAllowed,
    });

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
          _calendarSyncAllowed = profile.calendarSyncAllowed;
          _isSaving = false;
        });
      case UpdateProfileFailure(:final statusCode):
        setState(() {
          _notificationPreferences = previous;
          _calendarSyncAllowed = previousCalendarSync;
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
          _notificationPreferences = previous;
          _calendarSyncAllowed = previousCalendarSync;
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
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(_unauthenticatedMessage);
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

  Future<void> _updateCalendarSyncAllowed(bool enabled) async {
    if (currentLoggedInUser == null || currentAuthToken == null) {
      _showMessage(_unauthenticatedMessage);
      return;
    }

    final previousCalendarSync = _calendarSyncAllowed;

    setState(() {
      _isSaving = true;
      _calendarSyncAllowed = enabled;
    });

    final result = await updateCalendarSyncAllowed(
      widget.currentProfile.id,
      enabled,
    );

    if (!mounted) return;

    switch (result) {
      case UpdateProfileSuccess(:final profile):
        await setCurrentLoggedInUser({
          ...currentLoggedInUser ?? <String, dynamic>{},
          ...profile.toJson(),
          'id': profile.id,
        });
        setState(() {
          _calendarSyncAllowed = profile.calendarSyncAllowed;
          _isSaving = false;
        });
      case UpdateProfileFailure(:final statusCode):
        setState(() {
          _calendarSyncAllowed = previousCalendarSync;
          _isSaving = false;
        });
        if (statusCode == 401 || statusCode == 403) {
          _showMessage(_unauthenticatedMessage);
        } else if (statusCode == -1) {
          _showMessage('Error de connexió. Comprova la teva connexió.');
        } else {
          _showMessage(
            'No s\'ha pogut actualitzar la sincronització de calendari.',
          );
        }
      case UpdateProfileValidationError():
        setState(() {
          _calendarSyncAllowed = previousCalendarSync;
          _isSaving = false;
        });
        _showMessage(
          'No s\'ha pogut actualitzar la sincronització de calendari.',
        );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Configuració',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: AppScreenSpacing.content,
      children: [
        _buildIntroText(),
        const SizedBox(height: 24),
        LanguageSelectorTile(
          unauthenticatedMessage: _unauthenticatedMessage,
          onShowMessage: _showMessage,
        ),
        const SizedBox(height: 12),
        _buildBlockedUsersShortcut(),
        const SizedBox(height: 12),
        _buildNotificationBlock(),
        const SizedBox(height: 12),
        _buildCalendarSyncBlock(),
        const SizedBox(height: 12),
        _buildSavingIndicator(),
      ],
    );
  }

  Widget _buildBlockedUsersShortcut() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: EventTextUtils.kPrimaryRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.block, color: EventTextUtils.kPrimaryRed),
        ),
        title: const Text(
          'Usuaris bloquejats',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Revisa els perfils que has bloquejat.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
        },
      ),
    );
  }

  Widget _buildIntroText() {
    return Text(
      'Decideix quines alertes vols rebre. Els canvis s\'apliquen al moment.',
      style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
    );
  }

  Widget _buildNotificationBlock() {
    return NotificationAlertsBlock(
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
              title: 'Recordatoris d\'esdeveniments',
              subtitle: 'Avisos previs per no perdre sessions o activitats.',
              value: _notificationPreferences.eventRemindersAllowed,
              enabled: !_isSaving,
              onChanged: (value) => _updateSubalert(
                value: value,
                channel: NotificationPreferenceChannel.eventReminders,
              ),
            ),
            SubalertSwitchTile(
              title: 'Canvis en esdeveniments',
              subtitle: 'Actualitzacions d\'horari, ubicació o cancel·lacions.',
              value: _notificationPreferences.eventUpdatesAllowed,
              enabled: !_isSaving,
              onChanged: (value) => _updateSubalert(
                value: value,
                channel: NotificationPreferenceChannel.eventUpdates,
              ),
            ),
            SubalertSwitchTile(
              title: 'Alertes socials',
              subtitle:
                  'Notificacions relacionades amb amistats i activitat social.',
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
    );
  }

  Widget _buildCalendarSyncBlock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        title: const Text(
          'Sincronitzar amb Google Calendar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Afegeix automàticament les sessions que afegeixes a Google Calendar.',
        ),
        value: _calendarSyncAllowed,
        onChanged: !_isSaving ? _updateCalendarSyncAllowed : null,
        activeThumbColor: EventTextUtils.kPrimaryRed,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildSavingIndicator() {
    return AnimatedOpacity(
      opacity: _isSaving ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
