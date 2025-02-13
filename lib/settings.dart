import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mcmodpackmanager_reborn/backend.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key, required this.setLocale});

  final Function(String locale) setLocale;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late TextEditingController _controller;
  late String mcFolder;
  late String latestVersion;
  bool clipButtons = GetStorage().read("clipIcons");
  bool collectData = GetStorage().read("collectUserData");
  @override
  void dispose() {
    super.dispose();
  }

  void updateMinecraftFolderText() {
    setState(() {
      mcFolder = getMinecraftFolder().path;
    });
  }

  void setClipButtons(bool newValue) {
    GetStorage().write("clipIcons", newValue);
    setState(() {
      clipButtons = newValue;
    });
  }

  void setCollectData(bool newValue) {
    GetStorage().write("collectUserData", newValue);
    setState(() {
      collectData = newValue;
    });
  }

  @override
  void initState() {
    mcFolder = getMinecraftFolder().path;
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    void updateReleaseInfo() async {
      try {
        var release = await getReleaseInfo();

        GetStorage().write("latestVersion", release["latestRelease"]);
        GetStorage().write("currentVersion", release["currentRelease"]);
        GetStorage().write("latestVersionUrl", release["url"]);
      } catch (e) {}
    }

    updateReleaseInfo();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              children: [
                Text(AppLocalizations.of(context)!.settings),
                Text(
                  AppLocalizations.of(context)!.someSettingsRequireReload,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Center(
            child: DropdownMenu(
              width: 300,
              controller: _controller,
              label: Text(AppLocalizations.of(context)!.language),
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: "en", label: "English"),
                const DropdownMenuEntry(value: "uk", label: "Українська"),
                const DropdownMenuEntry(value: "tr", label: "Türkçe"),
                DropdownMenuEntry(
                    value: "native",
                    label: AppLocalizations.of(context)!.systemLocale),
              ],
              onSelected: (value) async {
                debugPrint("Selected value: ${value ?? "en"}");
                widget.setLocale(value ?? "en");
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.currentVersion(
                    "v${GetStorage().read("currentVersion")}",
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  AppLocalizations.of(context)!.latestVersion(
                    GetStorage().read("latestVersion") ??
                        AppLocalizations.of(context)!.unknown,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: TextButton.icon(
                    onPressed: () {
                      Uri uri = Uri.parse(
                        GetStorage().read("latestVersionUrl") ??
                            AppLocalizations.of(context)!.unknown,
                      );
                      launchUrl(uri);
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: Text(
                      AppLocalizations.of(context)!.openLatestRelease,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Text(mcFolder),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  child: TextButton(
                    onPressed: () =>
                        overwriteMinecraftFolder(updateMinecraftFolderText),
                    child: Text(
                        AppLocalizations.of(context)!.overrideMinecraftFolder),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  child: TextButton(
                    onPressed: () => clearMinecraftFolderOverwrite(
                        updateMinecraftFolderText),
                    child: Text(
                        AppLocalizations.of(context)!.resetMinecraftFolder),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  child: Switch(
                    value: clipButtons,
                    onChanged: setClipButtons,
                  ),
                ),
                Text(AppLocalizations.of(context)!.clipIcons),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  child: Switch(
                    value: collectData,
                    onChanged: setCollectData,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.dataCollectionQuestionShort,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.save),
              onPressed: () => collectUserInfo(saveToFile: true),
              label: Text(
                AppLocalizations.of(context)!.collectData,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                await launchUrl(
                  Uri.parse(
                      "https://mrquantumoff.dev/projects/mcmodpackmanager_reborn/analytics"),
                );
              },
              label: Text(
                AppLocalizations.of(context)!.viewPublicUsage(
                  AppLocalizations.of(context)!.productName,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                if (GetStorage().read("collectUserData")) {
                  MachineIdAndOS info = await getMachineIdAndOs();

                  await launchUrl(
                    Uri.parse(
                        "https://mrquantumoff.dev/projects/mcmodpackmanager_reborn/analytics/${info.machineId}"),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.invalidData,
                      ),
                    ),
                  );
                }
              },
              label: Text(
                AppLocalizations.of(context)!.viewYourUsageData,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.delete_forever),
              style: const ButtonStyle(
                iconColor: MaterialStatePropertyAll<Color>(Colors.redAccent),
              ),
              onPressed: () {
                try {
                  deleteUsageInfo();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .failedToDeleteUsageInfo),
                    ),
                  );
                }
              },
              label: Text(
                AppLocalizations.of(context)!.deleteYourUsageData,
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
