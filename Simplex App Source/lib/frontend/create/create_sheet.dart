import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'create_chat_sheet.dart';
import 'create_event_sheet.dart';
import 'create_packet.dart';
import 'create_task_sheet.dart';

import '../flutter_flow/flutter_flow_theme.dart';

class CreateSheet {
  static void getCreateSheet(BuildContext context) {
    double add = 0.0;
    if (!kIsWeb && Platform.isIOS) {
      add += 10.0;
    }
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(1000.0),
              topRight: Radius.circular(1000.0)),
        ),
        backgroundColor: const Color(0xFFF5F6F7),
        context: context,
        builder: (context) {
          return Container(
            width: MediaQuery.sizeOf(context).width,
            height: 195 + add,
            child: Stack(
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).width,
                  height: 75 + add,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                      topLeft: Radius.circular(1000),
                      topRight: Radius.circular(1000),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 75, 0, 0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(0, 1),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 41 + add),
                    child: Container(
                      width: 66,
                      height: 51,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B58F4),
                        borderRadius: BorderRadius.circular(45),
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
                Align(
                  alignment: const AlignmentDirectional(-1, 1),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(34, 0, 0, 50 + add),
                    child: InkWell(
                      onTap: () {
                        getCreatePageSheet("Packet", context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 66,
                            height: 51,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBEEFE),
                              borderRadius: BorderRadius.circular(45),
                            ),
                            child: const Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Icon(
                                Symbols.widgets,
                                fill: 1.0,
                                color: Color(0xFF617AFF),
                                size: 24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 5, 0, 0),
                            child: Text(
                              'Packet',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Google Sans',
                                    color: const Color(0xFF617AFF),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(1, 1),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 34, 50 + add),
                    child: InkWell(
                      onTap: () {
                        getCreatePageSheet("Task", context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 66,
                            height: 51,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBEEFE),
                              borderRadius: BorderRadius.circular(45),
                            ),
                            child: const Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Icon(
                                Icons.check_box,
                                color: Color(0xFF617AFF),
                                size: 24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 5, 0, 0),
                            child: Text(
                              'Task',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Google Sans',
                                    color: const Color(0xFF617AFF),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(0, -1),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        0, 15 - 0.5 * add, 90, 0),
                    child: InkWell(
                      onTap: () {
                        getCreatePageSheet("Chat", context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 66,
                            height: 51,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBEEFE),
                              borderRadius: BorderRadius.circular(45),
                            ),
                            child: const Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Icon(
                                Icons.chat_bubble,
                                color: Color(0xFF617AFF),
                                size: 24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 5, 0, 0),
                            child: Text(
                              'Channels',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Google Sans',
                                    color: const Color(0xFF617AFF),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(0, -1),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        90, 15 - 0.5 * add, 0, 0),
                    child: InkWell(
                      onTap: () {
                        getCreatePageSheet("Event", context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 66,
                            height: 51,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBEEFE),
                              borderRadius: BorderRadius.circular(45),
                            ),
                            child: const Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Icon(
                                Icons.calendar_today,
                                color: Color(0xFF617AFF),
                                size: 24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 5, 0, 0),
                            child: Text(
                              'Event',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Google Sans',
                                    color: const Color(0xFF617AFF),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  static void getCreatePageSheet(String type, BuildContext context) {
    Navigator.pop(context);
    Widget page = Container();
    switch (type) {
      case "Event":
        page = const CreateEventWidget();
        break;
      case "Packet":
        page = const CreatePacketWidget();
        break;
      case "Task":
        page = const CreateTaskSheet();
        break;
      case "Chat":
        page = const CreateChatSheet();
        break;
      default:
        break;
    }

    if (page != null) {
      showModalBottomSheet(
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0)),
          ),
          backgroundColor: const Color(0xFFF5F6F7),
          context: context,
          builder: (context) {
            return page;
          });
    }
  }
}
