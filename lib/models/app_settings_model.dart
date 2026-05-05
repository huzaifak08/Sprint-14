class AppSettingsModel {
  final bool isDarkMode;
  final String? defaultBusinessId;

  AppSettingsModel({this.isDarkMode = false, this.defaultBusinessId});

  Map<String, dynamic> toJsonDb() => {
    'isDarkMode': isDarkMode ? 1 : 0,
    'defaultBusinessId': defaultBusinessId,
  };

  factory AppSettingsModel.fromJsonDb(Map<String, dynamic> map) =>
      AppSettingsModel(
        isDarkMode: map['isDarkMode'] == 1,
        defaultBusinessId: map['defaultBusinessId'],
      );
}
