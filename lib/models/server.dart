class Server {
  bool? caldavEnabled;
  bool? emailRemindersEnabled;
  String? frontendUrl;
  bool? linkSharingEnabled;
  String? maxFileSize;
  String? motd;
  bool? taskAttachmentsEnabled;
  bool? taskCommentsEnabled;
  bool? totpEnabled;
  String? version;

  // New fields
  Auth? auth;
  List<String>? availableMigrators;
  bool? demoModeEnabled;
  List<String>? enabledBackgroundProviders;
  Legal? legal;
  bool? publicTeamsEnabled;
  bool? userDeletionEnabled;
  bool? webhooksEnabled;

  Server.fromJson(Map<String, dynamic> json)
      : caldavEnabled = json['caldav_enabled'],
        emailRemindersEnabled = json['email_reminders_enabled'],
        frontendUrl = json['frontend_url'],
        linkSharingEnabled = json['link_sharing_enabled'],
        maxFileSize = json['max_file_size'],
        motd = json['motd'],
        taskAttachmentsEnabled = json['task_attachments_enabled'],
        taskCommentsEnabled = json['task_comments_enabled'],
        totpEnabled = json['totp_enabled'],
        version = json['version'],
        auth = json['auth'] != null ? Auth.fromJson(json['auth']) : null,
        availableMigrators = (json['available_migrators'] as List?)?.map((e) => e.toString()).toList(),
        demoModeEnabled = json['demo_mode_enabled'],
        enabledBackgroundProviders = (json['enabled_background_providers'] as List?)?.map((e) => e.toString()).toList(),
        legal = json['legal'] != null ? Legal.fromJson(json['legal']) : null,
        publicTeamsEnabled = json['public_teams_enabled'],
        userDeletionEnabled = json['user_deletion_enabled'],
        webhooksEnabled = json['webhooks_enabled'];
}

class Auth {
  Ldap? ldap;
  Local? local;
  OpenIdConnect? openidConnect;

  Auth({this.ldap, this.local, this.openidConnect});

  factory Auth.fromJson(Map<String, dynamic> json) => Auth(
        ldap: json['ldap'] != null ? Ldap.fromJson(json['ldap']) : null,
        local: json['local'] != null ? Local.fromJson(json['local']) : null,
        openidConnect: json['openid_connect'] != null ? OpenIdConnect.fromJson(json['openid_connect']) : null,
      );
}

class Ldap {
  bool? enabled;
  Ldap({this.enabled});
  factory Ldap.fromJson(Map<String, dynamic> json) => Ldap(enabled: json['enabled']);
}

class Local {
  bool? enabled;
  bool? registrationEnabled;
  Local({this.enabled, this.registrationEnabled});
  factory Local.fromJson(Map<String, dynamic> json) => Local(
        enabled: json['enabled'],
        registrationEnabled: json['registration_enabled'],
      );
}

class OpenIdConnect {
  bool? enabled;
  List<OpenIdProvider>? providers;
  OpenIdConnect({this.enabled, this.providers});
  factory OpenIdConnect.fromJson(Map<String, dynamic> json) => OpenIdConnect(
        enabled: json['enabled'],
        providers: (json['providers'] as List?)?.map((e) => OpenIdProvider.fromJson(e)).toList(),
      );
}

class OpenIdProvider {
  String? authUrl;
  String? clientId;
  bool? emailFallback;
  bool? forceUserInfo;
  String? key;
  String? logoutUrl;
  String? name;
  String? scope;
  bool? usernameFallback;

  OpenIdProvider({
    this.authUrl,
    this.clientId,
    this.emailFallback,
    this.forceUserInfo,
    this.key,
    this.logoutUrl,
    this.name,
    this.scope,
    this.usernameFallback,
  });

  factory OpenIdProvider.fromJson(Map<String, dynamic> json) => OpenIdProvider(
        authUrl: json['auth_url'],
        clientId: json['client_id'],
        emailFallback: json['email_fallback'],
        forceUserInfo: json['force_user_info'],
        key: json['key'],
        logoutUrl: json['logout_url'],
        name: json['name'],
        scope: json['scope'],
        usernameFallback: json['username_fallback'],
      );
}

class Legal {
  String? imprintUrl;
  String? privacyPolicyUrl;
  Legal({this.imprintUrl, this.privacyPolicyUrl});
  factory Legal.fromJson(Map<String, dynamic> json) => Legal(
        imprintUrl: json['imprint_url'],
        privacyPolicyUrl: json['privacy_policy_url'],
      );
}
