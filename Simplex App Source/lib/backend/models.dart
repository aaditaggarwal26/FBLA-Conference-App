/// Data models to simplify interaction with Firebase Firestore API
///
/// # Overview
/// This library provides data model classes with utility methods
/// to abstract complexity in interaction with the Firestore Cloud Database
/// through a simplified interface.
///
///
/// # Models
/// The following data are connected to the following models:
///   * **Users** - [UserModel]
///   * **Events** - [EventModel]
///   * **Competitive Events** - [CompEventModel]
///   * **Announcements** - [AnnouncementModel]
///   * **Tasks** - [TaskModel]
///   * **Packets** - [PacketModel]
///   * **Chatrooms** - [ChatroomModel]
///
/// ## Users
/// [UserModel] contains basic data to store about the user.
///
/// ## Events
///
///
/// ## Competitive Events
/// ### **⚠️ THIS NEEDS TO BE RE-IMPLEMENTED ⚠️** ###
///
/// ## Announcements
///
/// ## Tasks
///
/// ## Packets
///
/// ## Chatrooms
/// ### **⚠️ THIS NEEDS TO BE RE-IMPLEMENTED ⚠️** ###
///
/// # Common API
/// Each class comes with a [fromDocumentSnapshot] named constructor and a
/// [toMap] instance method to easily convert from Firebase [QuerySnapshot] to
/// models and from models to [Map] when writing the data to the database
/// Example Usage:
/// ```dart
///   // Converting from DocumentSnapshot to Model
///   DocumentSnapshot doc = await database.collection('users').doc(id).get();
///   UserModel user = UserModel.fromDocumentSnapshot(doc);
///
///   // Converting from Model to Map and writing to databse
///   database.collection('users').doc(id).set(user.toMap());
///
/// ```
///
/// Each class also comes with its own share of static methods for get and
/// set operations following the below conventions:
///   * get - self-explanatory, a 'get' operation which fetches data\
///     Example: [UserModel.getUserById]
///   * write - **COMPLETELY OVERWRITES** target data, a 'set' operation\
///     Example: [UserModel.writeUser]
///   * update - merges target data with incoming data, a 'set' operation\
///     Example: [AnnouncementModel.updateAnnouncementById]
///   * delte - deletes the provided document, a 'set' operation\
///     newline Example [AnnouncementModel.deleteAnnouncementById]
///
/// # Development Notes
/// Please try to keep backend code as organized as possible. We want to avoid a
/// repeat of the monstrous API.dart.. group related functionality in files (Ex:
/// all User functionality is grouped together in the [UserModel] class)
///
///
/// ### Head Dev
/// @TBD
library models;

// import 'dart:ffi';
import 'dart:developer' as dv;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../app_info.dart';
import 'dart:async';

import '../main.dart';

part 'user_model.dart';
part 'event_model.dart';
part 'comp_model.dart';
part 'announcement_model.dart';
part 'task_model.dart';
part 'packet_model.dart';
part 'chatroom_model.dart';
part 'chapter_model.dart';
