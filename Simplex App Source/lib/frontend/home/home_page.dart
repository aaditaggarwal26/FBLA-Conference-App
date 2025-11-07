import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../events/show_events.dart';
import '../profile/profile_page.dart';

import '../flutter_flow/flutter_flow_theme.dart';
import '../select_chapter/chapter_select.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  List<String> firstLast = AppInfo.currentUser.name.split(' ');
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime startDate = DateTime.now().toLocal();
  DateTime endDate = DateTime.now().toLocal();
  String logo = "";
  String name = "";

  @override
  void initState() {
    // AppInfo.loadData();

    setState(() {
      startDate = DateTime(startDate.year, startDate.month, startDate.day);

      endDate = startDate.add(const Duration(days: 365));

      endDate =
          DateTime(endDate.year, endDate.month, endDate.day + 1, 23, 59, 59);
    });

    AppInfo.database
        .collection('chapters')
        .doc(AppInfo.currentUser.currentChapter)
        .get()
        .then(
      (value) {
        setState(() {
          logo = value.get('logo') as String;
          name = value.get('name') as String;
        });
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFf5f6f7),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Stack(
              children: [
                Align(
                  alignment: const AlignmentDirectional(0, 0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: 231.77,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: Image.asset(
                          'assets/images/454531818_520016530728357_6259979388890006873_n.png',
                        ).image,
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(24, 65, 24, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 0, 4, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    // Navigator.pushAndRemoveUntil(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //       builder: (context) =>
                                    //           const ChapterSelectWidget()),
                                    //   (route) =>
                                    //       false, // This condition removes all previous routes
                                    // );
                                    await _firestore
                                        .collection('users')
                                        .doc(AppInfo.currentUser.id)
                                        .update({
                                      'currentChapter': "",
                                    });
                                    AppInfo.currentUser.currentChapter = "";

                                    AppInfo.isAdmin = false;
                                    AppInfo.isOwner = false;

                                    Navigator.of(context).pushAndRemoveUntil(
                                      PageRouteBuilder(
                                        transitionDuration:
                                            const Duration(milliseconds: 200),
                                        reverseTransitionDuration:
                                            const Duration(milliseconds: 200),
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            const ChapterSelectWidget(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          const begin = Offset(-1.0, 0.0);
                                          const end = Offset.zero;
                                          final tween =
                                              Tween(begin: begin, end: end);
                                          final offsetAnimation =
                                              animation.drive(tween);

                                          return SlideTransition(
                                            position: offsetAnimation,
                                            child: child,
                                          );
                                        },
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Opacity(
                                        opacity: 0.6,
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0, 0, 0, 2),
                                          child: Icon(
                                            Icons.arrow_back_ios_new,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                      Opacity(
                                        opacity: 0.6,
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(4, 0, 0, 0),
                                          child: Text(
                                            'Exit',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Google Sans',
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                  useGoogleFonts: false,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Profile.showProfilePage(context);
                                  },
                                  child: Container(
                                    width: 33,
                                    height: 33,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF526BF4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF051989),
                                        width: 1,
                                      ),
                                    ),
                                    child: Align(
                                      alignment:
                                          const AlignmentDirectional(0, 0),
                                      child: Text(
                                        firstLast[0][0] + firstLast[1][0],
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          color: Colors.white,
                                          fontSize: 13,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 42, 0, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                logo == ''
                                    ? Container(
                                        color: Colors.transparent, height: 22)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(0),
                                        child: CachedNetworkImage(
                                          imageUrl: logo,
                                          height: 22,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 13, 0, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  name,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Google Sans',
                                        color: Colors.white,
                                        fontSize: 15,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        useGoogleFonts: false,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 221, 0, 0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F6F7),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 70),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Padding(
                          //   padding: const EdgeInsetsDirectional.fromSTEB(
                          //       0, 25, 0, 10),
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.max,
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     children: [
                          //       Row(
                          //         mainAxisSize: MainAxisSize.max,
                          //         children: [
                          //           Text(
                          //             'UPDATES',
                          //             style: FlutterFlowTheme.of(context)
                          //                 .bodyMedium
                          //                 .override(
                          //                   fontFamily: 'Google Sans',
                          //                   color: const Color(0xFF333333),
                          //                   fontSize: 18,
                          //                   letterSpacing: 0.0,
                          //                   fontWeight: FontWeight.bold,
                          //                   useGoogleFonts: false,
                          //                 ),
                          //           ),
                          //           Padding(
                          //             padding:
                          //                 const EdgeInsetsDirectional.fromSTEB(
                          //                     8, 0, 0, 0),
                          //             child: Container(
                          //               width: 6,
                          //               height: 6,
                          //               decoration: const BoxDecoration(
                          //                 color: Color(0xFFD90000),
                          //                 shape: BoxShape.circle,
                          //               ),
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //       Padding(
                          //         padding: const EdgeInsetsDirectional.fromSTEB(
                          //             0, 0, 10, 0),
                          //         child: Text(
                          //           'See All',
                          //           style: FlutterFlowTheme.of(context)
                          //               .bodyMedium
                          //               .override(
                          //                 fontFamily: 'Google Sans',
                          //                 color: const Color(0xFF3B58F4),
                          //                 fontSize: 12,
                          //                 letterSpacing: 0.0,
                          //                 fontWeight: FontWeight.bold,
                          //                 useGoogleFonts: false,
                          //               ),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // Column(
                          //   mainAxisSize: MainAxisSize.max,
                          //   children: [
                          //     Padding(
                          //       padding: const EdgeInsetsDirectional.fromSTEB(
                          //           0, 0, 0, 10),
                          //       child: Row(
                          //         mainAxisSize: MainAxisSize.max,
                          //         children: [
                          //           Expanded(
                          //             child: Container(
                          //               decoration: BoxDecoration(
                          //                 color: const Color(0xFFEEEFEF),
                          //                 borderRadius:
                          //                     BorderRadius.circular(12),
                          //               ),
                          //               child: Padding(
                          //                 padding: const EdgeInsetsDirectional
                          //                     .fromSTEB(17, 15, 18, 15),
                          //                 child: Row(
                          //                   mainAxisSize: MainAxisSize.max,
                          //                   mainAxisAlignment:
                          //                       MainAxisAlignment.spaceBetween,
                          //                   children: [
                          //                     Flexible(
                          //                       child: Row(
                          //                         mainAxisSize:
                          //                             MainAxisSize.max,
                          //                         children: [
                          //                           Container(
                          //                             width: 39,
                          //                             height: 39,
                          //                             child: Stack(
                          //                               alignment:
                          //                                   const AlignmentDirectional(
                          //                                       1, 1),
                          //                               children: [
                          //                                 Align(
                          //                                   alignment:
                          //                                       const AlignmentDirectional(
                          //                                           0, 0),
                          //                                   child: Container(
                          //                                     width: 39,
                          //                                     height: 39,
                          //                                     decoration:
                          //                                         const BoxDecoration(
                          //                                       color: Color(
                          //                                           0xFF3952D3),
                          //                                       shape: BoxShape
                          //                                           .circle,
                          //                                     ),
                          //                                     child: const Icon(
                          //                                       Icons.bolt,
                          //                                       color: Colors
                          //                                           .white,
                          //                                       size: 24,
                          //                                     ),
                          //                                   ),
                          //                                 ),
                          //                               ],
                          //                             ),
                          //                           ),
                          //                           Expanded(
                          //                             child: Padding(
                          //                               padding:
                          //                                   const EdgeInsetsDirectional
                          //                                       .fromSTEB(
                          //                                       10, 0, 8, 0),
                          //                               child: Column(
                          //                                 mainAxisSize:
                          //                                     MainAxisSize.max,
                          //                                 crossAxisAlignment:
                          //                                     CrossAxisAlignment
                          //                                         .start,
                          //                                 children: [
                          //                                   Padding(
                          //                                     padding:
                          //                                         const EdgeInsetsDirectional
                          //                                             .fromSTEB(
                          //                                             0,
                          //                                             0,
                          //                                             0,
                          //                                             3),
                          //                                     child: RichText(
                          //                                       textScaler: MediaQuery.of(
                          //                                               context)
                          //                                           .textScaler,
                          //                                       text: TextSpan(
                          //                                         children: const [
                          //                                           TextSpan(
                          //                                             text:
                          //                                                 'OPPORTUNITY',
                          //                                             style:
                          //                                                 TextStyle(),
                          //                                           )
                          //                                         ],
                          //                                         style: FlutterFlowTheme.of(
                          //                                                 context)
                          //                                             .bodyMedium
                          //                                             .override(
                          //                                               fontFamily:
                          //                                                   'Google Sans',
                          //                                               color: const Color(
                          //                                                   0xFF3952D3),
                          //                                               fontSize:
                          //                                                   12,
                          //                                               letterSpacing:
                          //                                                   0.0,
                          //                                               fontWeight:
                          //                                                   FontWeight.bold,
                          //                                               useGoogleFonts:
                          //                                                   false,
                          //                                             ),
                          //                                       ),
                          //                                       maxLines: 1,
                          //                                       overflow:
                          //                                           TextOverflow
                          //                                               .ellipsis,
                          //                                     ),
                          //                                   ),
                          //                                   RichText(
                          //                                     textScaler:
                          //                                         MediaQuery.of(
                          //                                                 context)
                          //                                             .textScaler,
                          //                                     text:
                          //                                         const TextSpan(
                          //                                       children: [
                          //                                         TextSpan(
                          //                                           text:
                          //                                               'Calling all graphic designers!',
                          //                                           style:
                          //                                               TextStyle(
                          //                                             color: Color(
                          //                                                 0xFF333333),
                          //                                             fontWeight:
                          //                                                 FontWeight
                          //                                                     .w500,
                          //                                             fontSize:
                          //                                                 15,
                          //                                           ),
                          //                                         )
                          //                                       ],
                          //                                       style:
                          //                                           TextStyle(
                          //                                         fontFamily:
                          //                                             'Google Sans',
                          //                                         color: Color(
                          //                                             0xFF333333),
                          //                                         fontWeight:
                          //                                             FontWeight
                          //                                                 .w500,
                          //                                         fontSize: 14,
                          //                                       ),
                          //                                     ),
                          //                                     maxLines: 2,
                          //                                   ),
                          //                                 ],
                          //                               ),
                          //                             ),
                          //                           ),
                          //                         ],
                          //                       ),
                          //                     ),
                          //                     const Icon(
                          //                       Icons.arrow_forward_ios,
                          //                       color: Color(0xFFC8C8C8),
                          //                       size: 12,
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //     Padding(
                          //       padding: const EdgeInsetsDirectional.fromSTEB(
                          //           0, 0, 0, 10),
                          //       child: Row(
                          //         mainAxisSize: MainAxisSize.max,
                          //         children: [
                          //           Expanded(
                          //             child: Container(
                          //               decoration: BoxDecoration(
                          //                 color: const Color(0xFFEEEFEF),
                          //                 borderRadius:
                          //                     BorderRadius.circular(12),
                          //               ),
                          //               child: Padding(
                          //                 padding: const EdgeInsetsDirectional
                          //                     .fromSTEB(17, 15, 18, 15),
                          //                 child: Row(
                          //                   mainAxisSize: MainAxisSize.max,
                          //                   mainAxisAlignment:
                          //                       MainAxisAlignment.spaceBetween,
                          //                   children: [
                          //                     Flexible(
                          //                       child: Row(
                          //                         mainAxisSize:
                          //                             MainAxisSize.max,
                          //                         children: [
                          //                           Container(
                          //                             width: 39,
                          //                             height: 39,
                          //                             child: Stack(
                          //                               alignment:
                          //                                   const AlignmentDirectional(
                          //                                       1, 1),
                          //                               children: [
                          //                                 Container(
                          //                                   width: 39,
                          //                                   height: 39,
                          //                                   decoration:
                          //                                       const BoxDecoration(
                          //                                     color: Color(
                          //                                         0xFFFF0000),
                          //                                     shape: BoxShape
                          //                                         .circle,
                          //                                   ),
                          //                                 ),
                          //                                 Padding(
                          //                                   padding:
                          //                                       const EdgeInsetsDirectional
                          //                                           .fromSTEB(
                          //                                           0, 0, 1, 0),
                          //                                   child: Container(
                          //                                     width: 14,
                          //                                     height: 14,
                          //                                     decoration:
                          //                                         const BoxDecoration(
                          //                                       color: Color(
                          //                                           0xFF2D9E6F),
                          //                                       shape: BoxShape
                          //                                           .circle,
                          //                                     ),
                          //                                     child:
                          //                                         const Align(
                          //                                       alignment:
                          //                                           AlignmentDirectional(
                          //                                               0, 0),
                          //                                       child: Icon(
                          //                                         Icons
                          //                                             .chat_bubble_rounded,
                          //                                         color: Colors
                          //                                             .white,
                          //                                         size: 7.5,
                          //                                       ),
                          //                                     ),
                          //                                   ),
                          //                                 ),
                          //                               ],
                          //                             ),
                          //                           ),
                          //                           Expanded(
                          //                             child: Padding(
                          //                               padding:
                          //                                   const EdgeInsetsDirectional
                          //                                       .fromSTEB(
                          //                                       10, 0, 8, 0),
                          //                               child: Column(
                          //                                 mainAxisSize:
                          //                                     MainAxisSize.max,
                          //                                 crossAxisAlignment:
                          //                                     CrossAxisAlignment
                          //                                         .start,
                          //                                 children: [
                          //                                   Padding(
                          //                                     padding:
                          //                                         const EdgeInsetsDirectional
                          //                                             .fromSTEB(
                          //                                             0,
                          //                                             0,
                          //                                             0,
                          //                                             3),
                          //                                     child: RichText(
                          //                                       textScaler: MediaQuery.of(
                          //                                               context)
                          //                                           .textScaler,
                          //                                       text: TextSpan(
                          //                                         children: const [
                          //                                           TextSpan(
                          //                                             text:
                          //                                                 'ANNOUNCEMENT | ',
                          //                                             style:
                          //                                                 TextStyle(),
                          //                                           ),
                          //                                           TextSpan(
                          //                                             text:
                          //                                                 'FBLA SBLC',
                          //                                             style:
                          //                                                 TextStyle(
                          //                                               fontFamily:
                          //                                                   'Google Sans',
                          //                                               fontWeight:
                          //                                                   FontWeight.w500,
                          //                                               fontStyle:
                          //                                                   FontStyle.italic,
                          //                                             ),
                          //                                           )
                          //                                         ],
                          //                                         style: FlutterFlowTheme.of(
                          //                                                 context)
                          //                                             .bodyMedium
                          //                                             .override(
                          //                                               fontFamily:
                          //                                                   'Google Sans',
                          //                                               color: const Color(
                          //                                                   0xFF2D9E6F),
                          //                                               fontSize:
                          //                                                   12,
                          //                                               letterSpacing:
                          //                                                   0.0,
                          //                                               fontWeight:
                          //                                                   FontWeight.bold,
                          //                                               useGoogleFonts:
                          //                                                   false,
                          //                                             ),
                          //                                       ),
                          //                                       maxLines: 1,
                          //                                       overflow:
                          //                                           TextOverflow
                          //                                               .ellipsis,
                          //                                     ),
                          //                                   ),
                          //                                   RichText(
                          //                                     textScaler:
                          //                                         MediaQuery.of(
                          //                                                 context)
                          //                                             .textScaler,
                          //                                     text:
                          //                                         const TextSpan(
                          //                                       children: [
                          //                                         TextSpan(
                          //                                           text:
                          //                                               'Koushik: ',
                          //                                           style:
                          //                                               TextStyle(
                          //                                             fontFamily:
                          //                                                 'Google Sans',
                          //                                             color: Color(
                          //                                                 0xFF333333),
                          //                                             fontWeight:
                          //                                                 FontWeight
                          //                                                     .bold,
                          //                                             fontSize:
                          //                                                 14,
                          //                                           ),
                          //                                         ),
                          //                                         TextSpan(
                          //                                           text:
                          //                                               'Please turn in your NLC forms by tomorrow night!',
                          //                                           style:
                          //                                               TextStyle(),
                          //                                         )
                          //                                       ],
                          //                                       style:
                          //                                           TextStyle(
                          //                                         fontFamily:
                          //                                             'Google Sans',
                          //                                         color: Color(
                          //                                             0xFF333333),
                          //                                         fontWeight:
                          //                                             FontWeight
                          //                                                 .w500,
                          //                                         fontSize: 14,
                          //                                       ),
                          //                                     ),
                          //                                     maxLines: 2,
                          //                                   ),
                          //                                 ],
                          //                               ),
                          //                             ),
                          //                           ),
                          //                         ],
                          //                       ),
                          //                     ),
                          //                     const Icon(
                          //                       Icons.arrow_forward_ios,
                          //                       color: Color(0xFFC8C8C8),
                          //                       size: 12,
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 25, 0, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'Upcoming',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Google Sans',
                                            color: const Color(0xFF333333),
                                            fontSize: 18,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            useGoogleFonts: false,
                                          ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              8, 0, 0, 0),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFD90000),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 12, 0, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0, 0, 0, 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                // TODO: remove or replace endDate
                                                ShowEvents(
                                                    startDate: startDate,
                                                    endDate: endDate)
                                              ]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }
}
