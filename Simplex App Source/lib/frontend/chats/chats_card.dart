import 'package:flutter/material.dart';
import 'package:simplex_chapter_x/app_info.dart';

import '../../backend/models.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../toast.dart';

class ChatsCard extends StatelessWidget {
  final AnnouncementModel a;
  final void Function() onPress;
  final void Function() onTap;

  const ChatsCard(
      {super.key, required this.a, required this.onPress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Map<String, String> announcement;
    String? initials;
    String? msg;
    if (a.msgs.isNotEmpty) {
      announcement = a.msgs.last;
      initials = announcement['senderName']!.split(" ").first[0] +
          announcement['senderName']!.split(" ").last[0];
      msg = announcement['text']!;
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 15),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                onTap();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: a.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(18, 0, 25, 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 12, 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BROADCAST CHANNEL',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Google Sans',
                                            color: const Color(0xAFFFFFFF),
                                            fontSize: 13,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            useGoogleFonts: false,
                                          ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 5, 0, 0),
                                      child: Text(
                                        a.name,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Google Sans',
                                              color: Colors.white,
                                              fontSize: 20,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              useGoogleFonts: false,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            a.id != AppInfo.currentUser.currentChapter
                                ? Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 10, 0, 0),
                                    child: InkWell(
                                      onTap: () {
                                        if (AppInfo.currentUser.topicsSubscribed
                                            .contains(a.id)) {
                                          AppInfo.currentUser
                                              .removeSubscribedTopic(a.id);
                                          a.unsubscribeNotif();
                                        } else {
                                          AppInfo.currentUser
                                              .addSubscribedTopic(a.id);
                                          a.subscribeNotif();
                                          Toasts.toast(
                                              'Joined Channel!', false);
                                        }
                                        onPress();
                                      },
                                      child: Container(
                                        width: 29,
                                        height: 29,
                                        decoration: const BoxDecoration(
                                          color: Color(0x4C000000),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Align(
                                          alignment:
                                              const AlignmentDirectional(0, 0),
                                          child: Icon(
                                            AppInfo.currentUser.topicsSubscribed
                                                    .contains(a.id)
                                                ? Icons.remove
                                                : Icons.add,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                      const Divider(
                        thickness: 2,
                        color: Color(0x0EFFFFFF),
                      ),
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(18, 3, 30, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 12, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    a.msgs.isNotEmpty
                                        ? Container(
                                            width: 25,
                                            height: 25,
                                            decoration: const BoxDecoration(
                                              color: Color(0x4EFFFFFF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Align(
                                              alignment:
                                                  const AlignmentDirectional(
                                                      0, 0),
                                              child: Text(
                                                initials!,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'Google Sans',
                                                          color: const Color(
                                                              0xFFF9F1FF),
                                                          fontSize: 11,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ),
                                          )
                                        : Container(),
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(8, 0, 0, 0),
                                        child: Text(
                                          a.msgs.isNotEmpty
                                              ? msg!
                                              : "No messages sent",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Google Sans',
                                                color: a.msgs.isEmpty ||
                                                        !AppInfo.currentUser
                                                            .topicsSubscribed
                                                            .contains(a.id)
                                                    ? const Color.fromARGB(
                                                        207, 255, 255, 255)
                                                    : Colors.white,
                                                fontSize: 15,
                                                letterSpacing: 0.0,
                                                useGoogleFonts: false,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
