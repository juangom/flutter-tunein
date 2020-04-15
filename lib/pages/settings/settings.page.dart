import 'package:Tunein/components/pagenavheader.dart';
import 'package:Tunein/globals.dart';
import 'package:Tunein/services/dialogService.dart';
import 'package:Tunein/services/layout.dart';
import 'package:Tunein/services/locator.dart';
import 'package:Tunein/services/settingService.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatelessWidget {

  final SettingService = locator<settingService>();
  final layoutService = locator<LayoutService>();



  @override
  Widget build(BuildContext gcontext) {
    return Material(
      color: MyTheme.darkBlack,
      child: Column(
        children: <Widget>[
          PageNavHeader(
            pageIndex: 2,
          ),
          Flexible(
            child: PageView(
              physics: AlwaysScrollableScrollPhysics(),
              controller: layoutService.pageServices[2].pageViewController,
              children: <Widget>[
                StreamBuilder(
                  stream: SettingService.settings$,
                  builder: (BuildContext context,
                      AsyncSnapshot<Map<SettingsIds,String>> snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    final _settings = snapshot.data;
                    return Container(
                      child: SettingsList(
                        backgroundColor: MyTheme.darkBlack,
                        textColor: MyTheme.grey300,
                        headingTextColor: MyTheme.darkRed,
                        sections: [
                          SettingsSection(
                            title: 'Region Settings',
                            tiles: [
                              SettingsTile(
                                title: 'Language',
                                subtitle: _settings[SettingsIds.SET_LANG],
                                leading: Icon(
                                  Icons.language,
                                  color: MyTheme.grey300,
                                ),
                                onTap: () {
                                  changeSystemLanguage(gcontext, _settings[SettingsIds.SET_LANG]);
                                },
                              ),

                            ],
                          ),
                          SettingsSection(
                            title: 'Aritsts',
                            tiles: [
                              SettingsTile.switchTile(
                                title: 'Update Artist thumbnails',
                                subtitle: 'Automatically update artist thumbnails via the internet',
                                leading: Icon(
                                    Icons.update,
                                    color: MyTheme.grey300
                                ),
                                switchValue: _settings[SettingsIds.SET_ARTIST_THUMB_UPDATE]=="true",
                                onToggle: (bool value) async{
                                  print("got the value : ${value}");
                                  bool validityCheck = await checkDiscogAPIValidity(context);
                                  if(!validityCheck){
                                    DialogService.showAlertDialog(context,
                                      message: "Can't turn on this feature unless all necessary fields are correctly filled",
                                      title: "Feature not available"
                                    );
                                  }else{
                                    SettingService.updateSingleSetting(SettingsIds.SET_ARTIST_THUMB_UPDATE, value.toString());
                                  }
                                },
                              ),

                            ],
                          ),
                          SettingsSection(
                            title: 'Advanced Settings',
                            tiles: [
                              SettingsTile(
                                title: 'Discogs API Token',
                                subtitle: _settings[SettingsIds.SET_DISCOG_API_KEY]!=null?"key is set":"no key is set",
                                leading: Icon(
                                  Icons.vpn_key,
                                  color: MyTheme.grey300,
                                ),
                                onTap: () async {
                                  String newKey = await openDiscogKeyTypeDialog(gcontext, _settings[SettingsIds.SET_DISCOG_API_KEY]);
                                  if(newKey!=_settings[SettingsIds.SET_DISCOG_API_KEY] && newKey!=null){
                                    SettingService.updateSingleSetting(SettingsIds.SET_DISCOG_API_KEY, newKey);
                                  }
                                },
                              ),
                              SettingsTile(
                                title: 'Discogs thumbnail quality',
                                subtitle: _settings[SettingsIds.SET_DISCOG_THUMB_QUALITY],
                                leading: Icon(
                                  Icons.high_quality,
                                  color: MyTheme.grey300,
                                ),
                                onTap: () async {
                                  changeDiscogThumbnailDownloadQuality(gcontext, _settings[SettingsIds.SET_DISCOG_THUMB_QUALITY]);
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                    );

                  },
                ),
                Center(
                  child: Container(
                    child: Text(
                      "SERVERS SETTINGS",
                      style: TextStyle(
                        fontSize: 40,
                        color: MyTheme.grey300,
                        fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );

  }


  changeSystemLanguage(context, String current)async{
    String Language = await openLanguageSelectDialog(context, current);
    SettingService.updateSingleSetting(SettingsIds.SET_LANG, Language);
  }

  changeDiscogThumbnailDownloadQuality(context, String current)async{
    String quality = await openThumbDownloadQualityDialog(context, current);
    if(quality!=null){
      SettingService.updateSingleSetting(SettingsIds.SET_DISCOG_THUMB_QUALITY, quality);
    }
  }

  Future<bool> checkDiscogAPIValidity(context) async{
    //This will check the validity of the discog API INFO stored in teh settings
    //in the future this should be a generic check for any API that can be used and exactly the API that is selected from a list

    Map<SettingsIds,String> currentSettings = SettingService.settings$.value;
    //checks in place
    //check for Token
    if(currentSettings[SettingsIds.SET_DISCOG_API_KEY]!=null){
      return true;
    }else{
      return false;
    }
  }


  Future<String> openLanguageSelectDialog(context, String current){

    void changeLanguage(String language) {
      Navigator.of(context, rootNavigator: true).pop(language);
    }

    bool isSelectedLanguage(String lang){
      return current==lang;
    }

    List<dynamic> languages = [
      "English",
      "Spanish",
      "Chinese",
      "German"
    ];

    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: MyTheme.darkBlack,
            title: Text(
              "Select language",
              style: TextStyle(
                  color: Colors.white70
              ),
            ),
            content: Material(
              child: Container(
                height: MediaQuery.of(context).size.height/2.5,
                width: MediaQuery.of(context).size.width/1.2,
                child: SettingsList(
                  textColor: MyTheme.grey300,
                  sections: [
                    SettingsSection(
                      title: "Chose the language to use",
                        tiles: languages.map((lang){
                          return SettingsTile(
                            trailing: isSelectedLanguage(lang)?Icon(Icons.check, color: MyTheme.grey300):Icon(null),
                            title: lang,
                            onTap: () {
                              changeLanguage(lang);
                            },
                          );
                        }).toList().cast<SettingsTile>()
                    ),
                  ],
                ),
              ),
              color:Colors.transparent
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: MyTheme.darkRed
                    ),
                  ),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(null))
            ],
          );
        });
  }
  Future<String> openThumbDownloadQualityDialog(context, String current){

    void changeQuality(String language) {
      Navigator.of(context, rootNavigator: true).pop(language);
    }

    bool isSelectedquality(String lang){
      return current==lang;
    }

    List<dynamic> qualitites = [
      "Low",
      "Medium",
      "High",
    ];

    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: MyTheme.darkBlack,
            title: Text(
              "Select Discog thumbnail download quality",
              style: TextStyle(
                  color: Colors.white70
              ),
            ),
            content: Material(
              child: Container(
                height: MediaQuery.of(context).size.height/2.5,
                width: MediaQuery.of(context).size.width/1.2,
                child: SettingsList(
                  textColor: MyTheme.grey300,
                  sections: [
                    SettingsSection(
                      title: "Chose the quality to use",
                        tiles: qualitites.map((quality){
                          return SettingsTile(
                            trailing: isSelectedquality(quality)?Icon(Icons.check, color: MyTheme.grey300):Icon(null),
                            title: quality,
                            onTap: () {
                              changeQuality(quality);
                            },
                          );
                        }).toList().cast<SettingsTile>()
                    ),
                  ],
                ),
              ),
              color:Colors.transparent
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: MyTheme.darkRed
                    ),
                  ),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(null))
            ],
          );
        });
  }

  Future<String> openDiscogKeyTypeDialog(context, String current){
    String currentKey = "";
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: MyTheme.darkBlack,
            title: Text(
              "Discog API key",
              style: TextStyle(
                  color: Colors.white70
              ),
            ),
            content: TextField(
              autofocus: true,
              onChanged: (string){
                currentKey=string;
              },
              style: TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                  hintText: "${current}",
                  hintStyle: TextStyle(
                      color: MyTheme.grey500.withOpacity(0.2)
                  )
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "Save Changes",
                  style: TextStyle(
                      color: MyTheme.grey300
                  ),
                ),
                onPressed: (){
                  print("keyset is ${currentKey}");
                  Navigator.of(context, rootNavigator: true).pop(currentKey);
                },
              ),
              FlatButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: MyTheme.darkRed
                    ),
                  ),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(null))
            ],
          );
        });
  }



}

