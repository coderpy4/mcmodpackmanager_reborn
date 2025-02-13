// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:get_storage/get_storage.dart';
import "package:http/http.dart" as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mcmodpackmanager_reborn/backend.dart';
import 'package:mcmodpackmanager_reborn/modpack_installer/web/filter_mods.dart';
import 'package:mcmodpackmanager_reborn/modpack_installer/web/generate_user_agent.dart';
import 'package:mcmodpackmanager_reborn/modpack_installer/web_sources.dart';

class ModpackInstallerPage extends StatefulWidget {
  const ModpackInstallerPage({super.key});

  @override
  State<ModpackInstallerPage> createState() => _ModpackInstallerPageState();
}

class _ModpackInstallerPageState extends State<ModpackInstallerPage> {
  late double progressValue;
  TextEditingController _controller = TextEditingController();
  TextEditingController _controller2 = TextEditingController();
  bool areButtonsEnabled = false;
  late double downloadSpeed = 0.0;

  @override
  void dispose() {
    super.dispose();
    downloadSpeed = 0.0;
    progressValue = 0.0;
    _controller.dispose();
    _controller2.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller2 = TextEditingController();
    downloadSpeed = 0.0;
    progressValue = 0.0;
    areButtonsEnabled = true;
  }

  void setDownloadProgress(double progress) {
    setState(() {
      progressValue = progress;
    });
  }

  void setDownloadSpeed(double speed) {
    setState(() {
      downloadSpeed = speed;
    });
  }

  void setButtonsEnabled(bool newValue) {
    setState(() {
      areButtonsEnabled = newValue;
    });
  }

  void displayErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.downloadFail),
      ),
    );
  }

  void displaySuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.downloadSuccess),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: areButtonsEnabled
              ? () {
                  Get.back();
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .downloadIsAlreadyInProgress),
                    ),
                  );
                },
        ),
        title: Text(AppLocalizations.of(context)!.installModpacks),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.all(15),
              child: ElevatedButton(
                onPressed: areButtonsEnabled
                    ? () async {
                        FilePickerResult? filePickerResult =
                            await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          dialogTitle:
                              AppLocalizations.of(context)!.installModpacks,
                          allowedExtensions: [
                            "mcmodpackref.json",
                            "mcmodpackref"
                          ],
                        );
                        try {
                          if (filePickerResult == null ||
                              filePickerResult.paths.isEmpty) return;
                          Map<String, dynamic> modpackref = jsonDecode(
                            await File(filePickerResult.paths.first!)
                                .readAsString(),
                          );
                          if (!modpackref.keys.toList().contains("name") ||
                              !modpackref.keys
                                  .toList()
                                  .contains("downloadUrl")) {
                            displayErrorSnackBar();
                          }
                          GetStorage().write(
                              "referenceFileUsage",
                              (GetStorage().read("referenceFileUsage") ?? 0) +
                                  1);
                          installModpack(
                              modpackref["downloadUrl"],
                              modpackref["name"],
                              setDownloadProgress,
                              setButtonsEnabled,
                              AppLocalizations.of(context)!.overwriteQuestion,
                              AppLocalizations.of(context)!
                                  .overwriteQuestionText,
                              displayErrorSnackBar,
                              displaySuccessSnackBar,
                              setDownloadSpeed);
                        } catch (err) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  AppLocalizations.of(context)!.installError),
                            ),
                          );
                        }
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .downloadIsAlreadyInProgress),
                          ),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_open_outlined),
                      Text("  ${AppLocalizations.of(context)!.referenceFile}"),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: areButtonsEnabled
                    ? () => showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text(
                                AppLocalizations.of(context)!.installModpacks),
                            content: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: TextField(
                                    controller: _controller,
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(context)!.name),
                                  ),
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: TextField(
                                    controller: _controller2,
                                    autocorrect: false,
                                    decoration:
                                        const InputDecoration(labelText: "URL"),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () async {
                                  if (_controller.text == "" ||
                                      _controller2.text == "") return;
                                  Navigator.pop(context);
                                  GetStorage().write(
                                      "manualInputUsage",
                                      (GetStorage().read("manualInputUsage") ??
                                              0) +
                                          1);
                                  installModpack(
                                      _controller2.text,
                                      _controller.text,
                                      setDownloadProgress,
                                      setButtonsEnabled,
                                      AppLocalizations.of(context)!
                                          .overwriteQuestion,
                                      AppLocalizations.of(context)!
                                          .overwriteQuestionText,
                                      displayErrorSnackBar,
                                      displaySuccessSnackBar,
                                      setDownloadSpeed);
                                },
                                icon: const Icon(Icons.file_download),
                                label: Text(
                                    AppLocalizations.of(context)!.download),
                              )
                            ],
                          ),
                        )
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .downloadIsAlreadyInProgress),
                          ),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard_alt_outlined),
                      Text("  ${AppLocalizations.of(context)!.manualInput}"),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: (const String.fromEnvironment("ETERNAL_API_KEY") ==
                        "")
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.noEternalKey),
                          ),
                        );
                      }
                    : areButtonsEnabled
                        ? () async {
                            final String apiKey =
                                const String.fromEnvironment("ETERNAL_API_KEY")
                                    .replaceAll("\"", "");
                            http.Response res = await http.get(
                              Uri.parse("https://api.curseforge.com/v1/games"),
                              headers: {
                                "User-Agent": await generateUserAgent(),
                                "X-API-Key": apiKey
                              },
                            );

                            if (res.statusCode == 200) {
                              var data = json.decode(res.body);
                              bool isValid = false;
                              for (var game in data["data"]) {
                                if (game["id"] == 432) {
                                  final clickedButton =
                                      await FlutterPlatformAlert.showAlert(
                                    windowTitle: AppLocalizations.of(context)!
                                        .productName,
                                    text: AppLocalizations.of(context)!
                                        .filterModpacksQ,
                                    alertStyle: AlertButtonStyle.yesNo,
                                    iconStyle: IconStyle.question,
                                  );
                                  if (clickedButton == AlertButton.yesButton) {
                                    Get.to(
                                      () => const FilterMods(),
                                      transition: Transition.rightToLeft,
                                    );
                                  } else {
                                    Get.to(
                                      () => const WebSourcesPage(),
                                      transition: Transition.rightToLeft,
                                    );
                                  }
                                  isValid = true;
                                }
                              }
                              if (!isValid) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!
                                        .noEternalKey),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!
                                      .noEternalKey),
                                ),
                              );
                            }
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .downloadIsAlreadyInProgress),
                              ),
                            );
                          },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_sharp),
                      Text("  ${AppLocalizations.of(context)!.web}"),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progressValue,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        "${AppLocalizations.of(context)!.speed}: $downloadSpeed MB/s"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
