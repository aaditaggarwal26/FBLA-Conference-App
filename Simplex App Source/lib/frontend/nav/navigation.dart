import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../chats/chats_page.dart';
import '../create/create_screen.dart';
import '../gallery/gallery_page.dart';
import '../home/home_page.dart';
import '../create/create_sheet.dart';
import '../settings/settings_page.dart';

import '../../app_info.dart';

class Navigation extends StatefulWidget {
  final int pIndex;

  const Navigation({
    super.key,
    required this.pIndex,
  });

  @override
  // ignore: no_logic_in_create_state
  State<Navigation> createState() => _NavigationState(pIndex);
}

class _NavigationState extends State<Navigation> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late int pI;

  _NavigationState(
    int pIndex,
  ) {
    pI = pIndex;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(initialPage: pI);

    double addHeight = 0.0;
    if (!kIsWeb && Platform.isIOS) {
      addHeight = 10.0;
    }

    List<Widget> pages = [
      const HomeWidget(),
      const ChatsWidget(),
      const GalleryPage(),
      const SettingsPage(),
      CreateScreen(),
    ];

    double iconSize = 28;

    List<Widget> icons = [
      InkWell(
        onTap: () {
          setState(() {
            pI = 0;
          });
          pageController.jumpToPage(0);
        },
        child: Icon(
          Symbols.home,
          fill: pI == 0 ? 1.0 : 0.0,
          color: pI == 0 ? const Color(0xFF333333) : const Color(0xFFDFDFDF),
          size: iconSize,
        ),
      ),
      InkWell(
        onTap: () {
          setState(() {
            pI = 1;
          });
          pageController.jumpToPage(1);
        },
        child: Icon(
          Symbols.chat_bubble,
          fill: pI == 1 ? 1.0 : 0.0,
          color: pI == 1 ? const Color(0xFF333333) : const Color(0xFFDFDFDF),
          size: iconSize,
        ),
      ),
      InkWell(
        onTap: () {
          setState(() {
            pI = 2;
          });
          pageController.jumpToPage(2);
        },
        child: Icon(
          Symbols.widgets,
          fill: pI == 2 ? 1.0 : 0.0,
          color: pI == 2 ? const Color(0xFF333333) : const Color(0xFFDFDFDF),
          size: iconSize,
        ),
      ),
      InkWell(
        onTap: () {
          setState(() {
            pI = 3;
          });
          pageController.jumpToPage(3);
        },
        child: Icon(
          Symbols.settings,
          fill: pI == 3 ? 1.0 : 0.0,
          color: pI == 3 ? const Color(0xFF333333) : const Color(0xFFDFDFDF),
          size: iconSize,
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      extendBody: true,
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        children: [
          for (Widget item in pages) (item),
        ],
      ),
      bottomNavigationBar: !AppInfo.isAdmin
          ? Container(
              width: MediaQuery.sizeOf(context).width,
              height: 100 + addHeight,
              child: Stack(
                children: [
                  Align(
                    alignment: const AlignmentDirectional(0, 1),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: 75 + addHeight,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(25, 0, 25, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            icons[0],
                            icons[1],
                            icons[2],
                            icons[3],
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppInfo.isAdmin
                      ? Align(
                          alignment: const AlignmentDirectional(0, 1),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 38 + addHeight),
                            child: InkWell(
                              onTap: () {},
                              child: Container(
                                width: 76,
                                height: 61,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(40),
                                  // border: Border.all(
                                  //   color: Colors.white,
                                  //   width: 5,
                                  // ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                  AppInfo.isAdmin
                      ? Align(
                          alignment: const AlignmentDirectional(0, 1),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 41 + addHeight),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  pI = 4;
                                });
                                pageController.jumpToPage(4);
                              },
                              child: Container(
                                width: 66,
                                height: 51,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B58F4),
                                  borderRadius: BorderRadius.circular(45),
                                  // border: Border.all(
                                  //   color: Colors.white,
                                  //   width: 5,
                                  // ),
                                ),
                                child: const Align(
                                  alignment: AlignmentDirectional(0, 0),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            )
          : Container(
              width: MediaQuery.sizeOf(context).width,
              height: 100 + addHeight,
              child: Stack(
                children: [
                  Align(
                    alignment: const AlignmentDirectional(0, 1),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: 75 + addHeight,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(25, 0, 25, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 38, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [icons[0], icons[1]],
                                ),
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    38, 0, 0, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [icons[2], icons[3]],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppInfo.isAdmin
                      ? Align(
                          alignment: const AlignmentDirectional(0, 1),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 38 + addHeight),
                            child: InkWell(
                              onTap: () {},
                              child: Container(
                                width: 76,
                                height: 61,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(40),
                                  // border: Border.all(
                                  //   color: Colors.white,
                                  //   width: 5,
                                  // ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                  AppInfo.isAdmin
                      ? Align(
                          alignment: const AlignmentDirectional(0, 1),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0, 0, 0, 41 + addHeight),
                            child: InkWell(
                              onTap: () {
                                CreateSheet.getCreateSheet(context);
                              },
                              child: Container(
                                width: 66,
                                height: 51,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B58F4),
                                  borderRadius: BorderRadius.circular(45),
                                  // border: Border.all(
                                  //   color: Colors.white,
                                  //   width: 5,
                                  // ),
                                ),
                                child: const Align(
                                  alignment: AlignmentDirectional(0, 0),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),

      // bottomNavigationBar: Container(
      //   decoration: const BoxDecoration(
      //     borderRadius: BorderRadius.only(
      //         topRight: Radius.circular(0), topLeft: Radius.circular(0)),
      //     boxShadow: [
      //       BoxShadow(
      //           color: Color.fromARGB(18, 0, 0, 0),
      //           spreadRadius: 0,
      //           blurRadius: 10),
      //     ],
      //   ),
      //   child: ClipRRect(
      //     borderRadius: const BorderRadius.only(
      //       topLeft: Radius.circular(0.0),
      //       topRight: Radius.circular(0.0),
      //     ),
      //     child: BottomBarWithSheet(
      //       disableMainActionButton: true,
      //       controller: bottomBarController,
      //       mainActionButtonTheme: const MainActionButtonTheme(
      //         color: Color.fromARGB(255, 76, 56, 239),
      //       ),
      //       bottomBarTheme: BottomBarTheme(
      //         heightOpened: 630,
      //         heightClosed: height,
      //         mainButtonPosition: MainButtonPosition.middle,
      //         contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      //         itemIconColor: const Color.fromARGB(255, 159, 159, 159),
      //         itemIconSize: 22,
      //         selectedItemIconSize: 26,
      //         itemTextStyle: const TextStyle(
      //           fontFamily: 'Montserrat',
      //           fontWeight: FontWeight.w500,
      //           color: Color.fromARGB(255, 159, 159, 159),
      //           fontSize: 10.0,
      //         ),
      //         selectedItemTextStyle: const TextStyle(
      //           fontFamily: 'Montserrat',
      //           fontWeight: FontWeight.w500,
      //           color: Color.fromARGB(255, 0, 0, 0),
      //           fontSize: 12.0,
      //         ),
      //         selectedItemIconColor: const Color.fromARGB(255, 0, 0, 0),
      //         decoration: const BoxDecoration(
      //           color: Color.fromRGBO(241, 244, 248, 1),
      //           borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      //         ),
      //       ),
      //       onSelectItem: (index) {
      //         pageController.jumpToPage(index);
      //       },
      //       items: items,
      //     ),
      //   ),
      // ),
    );
  }
}
