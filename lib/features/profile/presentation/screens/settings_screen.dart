import 'package:flutter/material.dart';

import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.currentProfile});

  final UserProfile currentProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        _buildNotificationBlock(),
        const SizedBox(height: 12),
        _buildSavingIndicator(),
      ],
    );
  }

  Widget _buildIntroText() {
    return Text(
      'Decideix quines alertes vols rebre. Els canvis s\'apliquen al moment.',
      style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
    );
  }

  Widget _buildNotificationBlock() {
    return _NotificationBlock(
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
            _SubalertTile(
              title: 'Recordatoris d\'esdeveniments',
              subtitle: 'Avisos previs per no perdre sessions o activitats.',
              value: _eventRemindersAllowed,
              enabled: !_isSaving,
              onChanged: (value) => _updateSubalert(
                value: value,
                assignLocalValue: (nextValue) {
                  _eventRemindersAllowed = nextValue;
                },
              ),
            ),
            _SubalertTile(
              title: 'Canvis en esdeveniments',
              subtitle: 'Actualitzacions d\'horari, ubicació o cancel·lacions.',
              value: _eventUpdatesAllowed,
              enabled: !_isSaving,
              onChanged: (value) => _updateSubalert(
                value: value,
                assignLocalValue: (nextValue) {
                  _eventUpdatesAllowed = nextValue;
                },
              ),
            ),
            _SubalertTile(
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

class _NotificationBlock extends StatelessWidget {
  const _NotificationBlock({
    required this.notificationsAllowed,
    required this.enabled,
    required this.onToggleNotifications,
    required this.child,
  });

  final bool notificationsAllowed;
  final bool enabled;
  final ValueChanged<bool> onToggleNotifications;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: const Text(
              'Notificacions permeses',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              notificationsAllowed
                  ? 'Si les actives, els tipus d\'alerta queden disponibles a sota.'
                  : 'Si les desactives, tots els tipus d\'alerta s\'apaguen i s\'amaguen.',
            ),
            value: notificationsAllowed,
            onChanged: enabled ? onToggleNotifications : null,
            activeThumbColor: const Color(0xFFB71C1C),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
          ),
          if (notificationsAllowed)
            Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: child,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SubalertTile extends StatelessWidget {
  const _SubalertTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(subtitle),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: const Color(0xFFB71C1C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
