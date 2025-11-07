import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_info.dart';
import '../../backend/models.dart';
import '../toast.dart';

import '../flutter_flow/flutter_flow_theme.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class ManageUsersWidget extends StatefulWidget {
  const ManageUsersWidget({super.key});

  @override
  State<ManageUsersWidget> createState() => _ManageUsersWidgetState();
}

class _ManageUsersWidgetState extends State<ManageUsersWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  FocusNode f = FocusNode();
  TextEditingController search = TextEditingController();
  bool dataLoaded = false;
  List<UserModel> users = [];
  List<String> execIds = [];

  _ManageUsersWidgetState() {
    _loadData();
  }

  void _loadData() async {
    DocumentSnapshot value = await FirebaseFirestore.instance
        .collection('chapters')
        .doc(AppInfo.currentUser.currentChapter)
        .get();

    execIds = (value.get('exec') as List).cast<String>();
    List<String> userIds = (value.get('users') as List).cast<String>();
    final List<DocumentSnapshot> results = [];
    for (int i = 0; i < userIds.length; i += 10) {
      final chunk =
          userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(querySnapshot.docs);
    }
    for (DocumentSnapshot d in results) {
      users.add(UserModel.fromDocumentSnapshot(d));
    }
    users.sort(
      (a, b) {
        return a.name.compareTo(b.name);
      },
    );
    dataLoaded = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    f.dispose();
    search.dispose();
    super.dispose();
  }

  List<Widget> getWidgetsFromSearch() {
    String txt = search.text;
    List<Widget> items = [];
    Iterable<UserModel> newUsers;
    if (txt.isNotEmpty) {
      newUsers = users.where(
        (element) {
          return element.name.toLowerCase().startsWith(txt.toLowerCase());
        },
      );
    } else {
      newUsers = users;
    }

    for (UserModel u in newUsers) {
      List<String> firstLast = u.name.split(' ');
      String initials = firstLast[0][0] + firstLast[1][0];
      items.addAll([
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(15, 0, 18, 0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 7, 0),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Align(
                          alignment: const AlignmentDirectional(0, 0),
                          child: Text(
                            initials,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Google Sans',
                                  color: Colors.white,
                                  fontSize: 11,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: false,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: AutoSizeText(
                        u.name,
                        maxLines: 1,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Google Sans',
                              color: Colors.black,
                              fontSize: 15,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                              useGoogleFonts: false,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  if (execIds.contains(u.id)) {
                    Toasts.toast("Cannot remove an administrator.", true);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('chapters')
                        .doc(AppInfo.currentUser.currentChapter)
                        .update({
                      'users': FieldValue.arrayRemove([u.id])
                    });
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(u.id)
                        .update({
                      'chapters': FieldValue.arrayRemove(
                          [AppInfo.currentUser.currentChapter]),
                      'currentChapter': ""
                    });
                    Toasts.toast("User removed!", false);
                    users.removeWhere(
                      (element) {
                        return element.id == u.id;
                      },
                    );
                    setState(() {});
                  }
                },
                child: const Icon(
                  Icons.delete_forever_sharp,
                  color: Color(0xFFA10202),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 1.5,
          color: Color(0x5BA7A7A7),
        ),
      ]);
    }

    if (items.isEmpty) {
      items.add(Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(15, 0, 18, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Align(
                      alignment: const AlignmentDirectional(0, 0),
                      child: AutoSizeText(
                        'No users found with the inputted search query.',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Google Sans',
                              color: Colors.black,
                              fontSize: 15,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                              useGoogleFonts: false,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F7),
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
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
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Opacity(
                            opacity: 0.6,
                            child: Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 0, 2),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF333333),
                                size: 14,
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: 0.6,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  4, 0, 0, 0),
                              child: Text(
                                'Back',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Google Sans',
                                      color: const Color(0xFF333333),
                                      fontSize: 17,
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
                                  'Manage Users',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Google Sans',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontSize: 32,
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
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 30, 0, 0),
                      child: dataLoaded
                          ? Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F1F1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 15, 0, 12),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(15, 0, 0, 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Text(
                                                  'User List',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'Google Sans',
                                                        color: Colors.black,
                                                        fontSize: 20,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        useGoogleFonts: false,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(15, 0, 15, 0),
                                            child: TextFormField(
                                              onChanged: (val) {
                                                setState(() {});
                                              },
                                              controller: search,
                                              focusNode: f,
                                              autofocus: false,
                                              obscureText: false,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText: 'Search...',
                                                hintStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .override(
                                                          fontFamily:
                                                              'Google Sans',
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts: false,
                                                        ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: const BorderSide(
                                                    color: Color(0x00000000),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: const BorderSide(
                                                    color: Color(0x00000000),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                filled: true,
                                                fillColor:
                                                    const Color(0xFFE7E7E7),
                                                prefixIcon: const Icon(
                                                  Icons.search_sharp,
                                                ),
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'Google Sans',
                                                        letterSpacing: 0.0,
                                                        useGoogleFonts: false,
                                                      ),
                                              cursorColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                            ),
                                          ),
                                          const Divider(
                                            thickness: 1.5,
                                            color: Color(0x5BA7A7A7),
                                          ),
                                          for (Widget item
                                              in getWidgetsFromSearch())
                                            (item),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                  CircularProgressIndicator(color: Colors.black)
                                ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
