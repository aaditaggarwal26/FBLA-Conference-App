import 'task_page.dart';
import 'packets_page.dart';
import 'calendar_page.dart';

import '../../app_info.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

import '../profile/profile_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> firstLast = AppInfo.currentUser.name.split(' ');
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F7),
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 1,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F7),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 65, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 6, 0, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Gallery',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Google Sans',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontSize: 40,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        useGoogleFonts: false,
                                      ),
                                ),
                                // Padding(
                                //   padding: EdgeInsetsDirectional.fromSTEB(
                                //       15, 0, 0, 0),
                                //   child: Icon(
                                //     Icons.help_outline,
                                //     color: Color(0xFF98989D),
                                //     size: 17,
                                //   ),
                                // ),
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
                                alignment: const AlignmentDirectional(0, 0),
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
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        /*
                        // Padding(
                        //   padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                        //   child: Container(
                        //     width: MediaQuery.sizeOf(context).width * 0.905,
                        //     height: 130,
                        //     child: Stack(
                        //       children: [
                        //         Align(
                        //           alignment: AlignmentDirectional(0, 0),
                        //           child: Container(
                        //             width: MediaQuery.sizeOf(context).width *
                        //                 0.905,
                        //             height: 130,
                        //             decoration: BoxDecoration(
                        //               color: FlutterFlowTheme.of(context)
                        //                   .secondaryBackground,
                        //               image: DecorationImage(
                        //                 fit: BoxFit.cover,
                        //                 image: Image.asset(
                        //                   'assets/images/calendarbg.png',
                        //                 ).image,
                        //               ),
                        //               boxShadow: [
                        //                 BoxShadow(
                        //                   blurRadius: 3,
                        //                   color: Color(0x16000000),
                        //                   offset: Offset(
                        //                     0,
                        //                     3,
                        //                   ),
                        //                 )
                        //               ],
                        //               borderRadius: BorderRadius.circular(12),
                        //               border: Border.all(
                        //                 color: Color(0xFF4C3339),
                        //                 width: 1.5,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //         Align(
                        //           alignment: AlignmentDirectional(0, 0),
                        //           child: Container(
                        //             width: MediaQuery.sizeOf(context).width *
                        //                 0.905,
                        //             height: 130,
                        //             decoration: BoxDecoration(
                        //               gradient: LinearGradient(
                        //                 colors: [
                        //                   Color(0x004C3339),
                        //                   Color(0xFF685037)
                        //                 ],
                        //                 stops: [0, 1],
                        //                 begin: AlignmentDirectional(0, -1),
                        //                 end: AlignmentDirectional(0, 1),
                        //               ),
                        //               borderRadius: BorderRadius.circular(12),
                        //               border: Border.all(
                        //                 width: 0,
                        //               ),
                        //             ),
                        //             child: Padding(
                        //               padding: EdgeInsetsDirectional.fromSTEB(
                        //                   22, 0, 0, 0),
                        //               child: Column(
                        //                 mainAxisSize: MainAxisSize.max,
                        //                 mainAxisAlignment:
                        //                     MainAxisAlignment.end,
                        //                 children: [
                        //                   Row(
                        //                     mainAxisSize: MainAxisSize.max,
                        //                     children: [
                        //                       Text(
                        //                         'Calendar',
                        //                         style:
                        //                             FlutterFlowTheme.of(context)
                        //                                 .bodyMedium
                        //                                 .override(
                        //                                   fontFamily:
                        //                                       'Google Sans',
                        //                                   color: Colors.white,
                        //                                   fontSize: 28,
                        //                                   letterSpacing: 0.0,
                        //                                   fontWeight:
                        //                                       FontWeight.bold,
                        //                                   useGoogleFonts: false,
                        //                                 ),
                        //                       ),
                        //                     ],
                        //                   ),
                        //                   Padding(
                        //                     padding:
                        //                         EdgeInsetsDirectional.fromSTEB(
                        //                             0, 5, 0, 20),
                        //                     child: Row(
                        //                       mainAxisSize: MainAxisSize.max,
                        //                       children: [
                        //                         Text(
                        //                           'Keep track of all upcoming events.',
                        //                           style: FlutterFlowTheme.of(
                        //                                   context)
                        //                               .bodyMedium
                        //                               .override(
                        //                                 fontFamily:
                        //                                     'Google Sans',
                        //                                 color:
                        //                                     Color(0xCDFFDDBD),
                        //                                 fontSize: 15,
                        //                                 letterSpacing: 0.0,
                        //                                 useGoogleFonts: false,
                        //                               ),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        */
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: Container(
                            width: MediaQuery.sizeOf(context).width * 0.905,
                            height: 130,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: const AlignmentDirectional(0, 0),
                                  child: Container(
                                    width: MediaQuery.sizeOf(context).width *
                                        0.905,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: Image.asset(
                                          'assets/images/calendarbg.png',
                                        ).image,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 3,
                                          color: Color(0x16000000),
                                          offset: Offset(
                                            0,
                                            3,
                                          ),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF9F9268),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: const AlignmentDirectional(0, 0),
                                  child: Container(
                                    width: MediaQuery.sizeOf(context).width *
                                        0.905,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0x004C3339),
                                          Color.fromARGB(255, 159, 126, 104)
                                        ],
                                        stops: [0, 1],
                                        begin: AlignmentDirectional(0, -1),
                                        end: AlignmentDirectional(0, 1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        width: 0,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CalendarPage(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(22, 0, 0, 0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Text(
                                                  'Calendar',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'Google Sans',
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        useGoogleFonts: false,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(0, 5, 0, 20),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    'Keep track of all upcoming events.',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'Google Sans',
                                                          color: const Color(
                                                              0xFFEDDFAD),
                                                          fontSize: 15,
                                                          letterSpacing: 0.0,
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: Container(
                            width: MediaQuery.sizeOf(context).width * 0.905,
                            height: 130,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: const AlignmentDirectional(0, 0),
                                  child: Container(
                                    width: MediaQuery.sizeOf(context).width *
                                        0.905,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: Image.asset(
                                          'assets/images/tasksbg.png',
                                        ).image,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 3,
                                          color: Color(0x16000000),
                                          offset: Offset(
                                            0,
                                            3,
                                          ),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF9F9268),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: const AlignmentDirectional(0, 0),
                                  child: Container(
                                    width: MediaQuery.sizeOf(context).width *
                                        0.905,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0x004C3339),
                                          Color(0xFF9F9268)
                                        ],
                                        stops: [0, 1],
                                        begin: AlignmentDirectional(0, -1),
                                        end: AlignmentDirectional(0, 1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        width: 0,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return const TaskPage();
                                            },
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(22, 0, 0, 0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Text(
                                                  'Tasks',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'Google Sans',
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        useGoogleFonts: false,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(0, 5, 0, 20),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    'Complete and keep track of tasks!',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'Google Sans',
                                                          color: const Color(
                                                              0xFFEDDFAD),
                                                          fontSize: 15,
                                                          letterSpacing: 0.0,
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PacketsPage(),
                                ),
                              );
                            },
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.905,
                              height: 130,
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: const AlignmentDirectional(0, 0),
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.905,
                                      height: 163,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: Image.asset(
                                            'assets/images/PacketsBG.png',
                                          ).image,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            blurRadius: 3,
                                            color: Color(0x16000000),
                                            offset: Offset(
                                              0,
                                              3,
                                            ),
                                          )
                                        ],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF4C3339),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: const AlignmentDirectional(0, 0),
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.905,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0x004C3339),
                                            Color(0xFF4C3339)
                                          ],
                                          stops: [0, 1],
                                          begin: AlignmentDirectional(0, -1),
                                          end: AlignmentDirectional(0, 1),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          width: 0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(22, 0, 0, 0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Text(
                                                  'Packets',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'Google Sans',
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        useGoogleFonts: false,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(0, 5, 0, 20),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    'View resources available to you!',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'Google Sans',
                                                          color: const Color(
                                                              0xB3FFE7EC),
                                                          fontSize: 15,
                                                          letterSpacing: 0.0,
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
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Padding(
                        //   padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                        //   child: Container(
                        //     width: MediaQuery.sizeOf(context).width * 0.905,
                        //     height: 130,
                        //     child: Stack(
                        //       children: [
                        //         Align(
                        //           alignment: AlignmentDirectional(0, 0),
                        //           child: Container(
                        //             width: MediaQuery.sizeOf(context).width *
                        //                 0.905,
                        //             height: 130,
                        //             decoration: BoxDecoration(
                        //               color: FlutterFlowTheme.of(context)
                        //                   .secondaryBackground,
                        //               image: DecorationImage(
                        //                 fit: BoxFit.cover,
                        //                 image: Image.asset(
                        //                   'assets/images/QuicklinksBG.png',
                        //                 ).image,
                        //               ),
                        //               boxShadow: [
                        //                 BoxShadow(
                        //                   blurRadius: 3,
                        //                   color: Color(0x16000000),
                        //                   offset: Offset(
                        //                     0,
                        //                     3,
                        //                   ),
                        //                 )
                        //               ],
                        //               borderRadius: BorderRadius.circular(12),
                        //               border: Border.all(
                        //                 color: Color(0xFF021633),
                        //                 width: 1.5,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //         Align(
                        //           alignment: AlignmentDirectional(0, 0),
                        //           child: Container(
                        //             width: MediaQuery.sizeOf(context).width *
                        //                 0.905,
                        //             height: 130,
                        //             decoration: BoxDecoration(
                        //               gradient: LinearGradient(
                        //                 colors: [
                        //                   Color(0x004C3339),
                        //                   Color(0xE9021633)
                        //                 ],
                        //                 stops: [0, 1],
                        //                 begin: AlignmentDirectional(0, -1),
                        //                 end: AlignmentDirectional(0, 1),
                        //               ),
                        //               borderRadius: BorderRadius.circular(12),
                        //               border: Border.all(
                        //                 width: 0,
                        //               ),
                        //             ),
                        //             child: Padding(
                        //               padding: EdgeInsetsDirectional.fromSTEB(
                        //                   22, 0, 0, 0),
                        //               child: Column(
                        //                 mainAxisSize: MainAxisSize.max,
                        //                 mainAxisAlignment:
                        //                     MainAxisAlignment.end,
                        //                 children: [
                        //                   Row(
                        //                     mainAxisSize: MainAxisSize.max,
                        //                     children: [
                        //                       Text(
                        //                         'Quicklinks',
                        //                         style:
                        //                             FlutterFlowTheme.of(context)
                        //                                 .bodyMedium
                        //                                 .override(
                        //                                   fontFamily:
                        //                                       'Google Sans',
                        //                                   color: Colors.white,
                        //                                   fontSize: 28,
                        //                                   letterSpacing: 0.0,
                        //                                   fontWeight:
                        //                                       FontWeight.bold,
                        //                                   useGoogleFonts: false,
                        //                                 ),
                        //                       ),
                        //                     ],
                        //                   ),
                        //                   Padding(
                        //                     padding:
                        //                         EdgeInsetsDirectional.fromSTEB(
                        //                             0, 5, 0, 20),
                        //                     child: Row(
                        //                       mainAxisSize: MainAxisSize.max,
                        //                       children: [
                        //                         Text(
                        //                           'Explore external links for information!',
                        //                           style: FlutterFlowTheme.of(
                        //                                   context)
                        //                               .bodyMedium
                        //                               .override(
                        //                                 fontFamily:
                        //                                     'Google Sans',
                        //                                 color:
                        //                                     Color(0xFFABCCE4),
                        //                                 fontSize: 15,
                        //                                 letterSpacing: 0.0,
                        //                                 useGoogleFonts: false,
                        //                               ),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
