import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app_info.dart';
import 'create_chat_sheet.dart';
import 'create_event_sheet.dart';
import 'create_packet.dart';
import 'create_task_sheet.dart';
import '../flutter_flow/flutter_flow_theme.dart';

class CreateScreen extends StatelessWidget {
  List<String> firstLast = AppInfo.currentUser.name.split(' ');

  CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f6f7),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Admin Panel',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Google Sans',
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontSize: 40,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                            ),
                            // const Padding(
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
                      Container(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(25, 29, 0, 0),
            child: Text(
              'Create',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
              children: [
                _buildMenuItem('Packets', Symbols.widgets, context),
                _buildMenuItem('Channels', Icons.chat_bubble, context),
                _buildMenuItem('Events', Icons.calendar_today, context),
                _buildMenuItem('Tasks', Icons.check_box, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD8DEFE),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF617AFF)),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3B68F4),
            ),
          ),
          onTap: () {
            Widget page;
            switch (title) {
              case "Events":
                page = const CreateEventWidget();
                break;
              case "Packets":
                page = const CreatePacketWidget();
                break;
              case "Tasks":
                page = const CreateTaskSheet();
                break;
              case "Channels":
                page = const CreateChatSheet();
                break;
              default:
                page = Container();
            }

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
          },
        ),
      ),
    );
  }
}
