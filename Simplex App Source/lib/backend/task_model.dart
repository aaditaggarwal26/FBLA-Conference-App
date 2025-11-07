part of 'models.dart';

/// [TaskModel] encapsulates fields of a Firebase Event Document found in the 'events' Collection
///
/// Instantiate [TaskModel] using a [DocumentSnapshot] with [TaskModel.fromDocumentSnapshot] to easily
/// read fields from the document. When an update to the document is required, use [toMap] to
/// quickly transform the object into a [Map] and then write to the [DocumentReference]
class TaskModel {
  /// the Firebase document id of this particular task
  final String id;

  /// the name of this task
  final String title;

  /// the description of this task
  final String description;

  /// date the task is due, stored in a YYYY-MM-DD format
  final DateTime dueDate;

  /// the time the task is due, stored in an HH:MM PM format
  /// Ex: '3:41 PM'

  /// **⚠️ UNDER CONSTRUCTION ⚠️**
  /// A list of all of the submissions
  /// This should be merged with users submitted, so [submissions] should be a
  /// [Map<String, Map<String, String>>] rather than a List<Map<String, String>>
  /// So that the map keys are users and the map values are the submission data
  final List<Map<String, String>> submissions;

  /// **⚠️ UNDER CONSTRUCTION ⚠️**
  /// See notes on above field
  final List<String> usersSubmitted;

  /// A list of the links associated with this task
  /// The first map key is the name of the link and the second map key is the
  /// URL itself
  final List<Map<String, String>> links;

  /// URL of image to be displayed with the task
  final String image;

  /// notes that show up on the tasks overview panel (details show up in the task menu itself)
  final String notes;

  final String chapterId;

  final bool isCompleted;

  TaskModel({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.submissions,
    required this.links,
    required this.image,
    required this.usersSubmitted,
    required this.notes,
    this.isCompleted = false,
  });

  /// Utility constructor to easily make a [TaskModel] from a [DocumentSnapshot]
  ///
  /// Queries the [DocumentSnapshot] for each field and instantiates [TaskModel] accordingly
  TaskModel.fromDocumentSnapshot(DocumentSnapshot<Object?> doc)
      : id = doc.id,
        title = doc.get('title') as String,
        description = doc.get('description') as String,
        dueDate = (doc.get('dueDate') as Timestamp).toDate().toLocal(),
        chapterId = doc.get('chapterId') as String,
        isCompleted = doc.get('isCompleted') as bool,
        submissions = (doc.get('submissions') as List<dynamic>)
            .map((submission) => Map<String, String>.from(submission))
            .toList(),
        usersSubmitted = (doc.get('usersSubmitted') as List).cast<String>(),
        links = (doc.get('links') as List<dynamic>)
            .map((link) => Map<String, String>.from(link))
            .toList(),
        image = doc.get('image') as String,
        notes = doc.get('notes') as String;

  /// Utility method to easily make a [Map] from a [TaskModel]
  ///
  /// Invoke [toMap] when writing a [TaskModel] object to a task document in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
      'submissions': submissions,
      'usersSubmitted': usersSubmitted,
      'links': links,
      'image': image,
      'notes': notes,
      'type': 'task'
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      chapterId: map['chapterId'],
      title: map['title'],
      description: map['description'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'],
      submissions: (map['submissions'] as List<dynamic>)
          .map((submission) => Map<String, String>.from(submission))
          .toList(),
      usersSubmitted: (map['usersSubmitted'] as List).cast<String>(),
      links: (map['links'] as List<dynamic>)
          .map((link) => Map<String, String>.from(link))
          .toList(),
      image: map['image'],
      notes: map['notes'],
    );
  }

  /// Writes the provided [TaskModel] object to the database
  ///
  ///
  // static Future<void> writeTask(TaskModel task) async {
  //   final chapterRef =
  //       AppInfo.database.collection('chapters').doc(task.chapterId);

  //   await chapterRef.update({
  //     'tasks': FieldValue.arrayUnion([task.toMap()])
  //   });
  // }
  static Future<void> createTask(TaskModel task) async {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .add(task.toMap());
  }

  static Future<void> updateTasks() async {
    await TaskModel.getCurrentTasks().then(
      (value) {
        AppInfo.currentTasks = value;
      },
    );
  }

  /// Updates the specified task via [id] with the provided updates
  ///
  /// Firebase will attempt to merge the target data with the incoming data
  static Future<void> updateTaskById(
      String chapterId, String taskId, Map<String, dynamic> updates) async {
    final chapterRef = AppInfo.database.collection('chapters').doc(chapterId);

    final chapterDoc = await chapterRef.get();
    final tasks =
        List<Map<String, dynamic>>.from(chapterDoc.get('timedObjects'));

    final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex != -1) {
      tasks[taskIndex].addAll(updates);
      await chapterRef.update({'tasks': tasks});
    }
  }

  /// Deletes the specified task via [id] from the database
  ///
  ///
  static void removeTaskById(String id) {
    AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .doc(id)
        .delete();
  }

  /// Gets the specified task via [id] as a [TaskModel] object
  ///
  ///
  static Future<TaskModel> getTaskById(String id) async {
    DocumentSnapshot taskInfo = await AppInfo.database
        .collection("chapters")
        .doc(AppInfo.currentUser.currentChapter)
        .collection('timedObjects')
        .doc(id)
        .get();
    return TaskModel.fromDocumentSnapshot(taskInfo);
  }

  /// Gets the current tasks as a [List] of [TaskModel] objects
  ///
  ///
  static Future<List<TaskModel>> getCurrentTasks() async {
    final currentDate = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(currentDate);
    String currentChapter = AppInfo.currentUser.currentChapter;

    QuerySnapshot taskQuery = await AppInfo.database
        .collection("chapters")
        .doc(currentChapter)
        .collection('timedObjects')
        .where('type', isEqualTo: "task")
        .where('dueDate', isLessThanOrEqualTo: formattedDate)
        .orderBy('dueDate')
        .get();
    dv.log(taskQuery.docs.length.toString());

    return (taskQuery.docs as List<dynamic>?)
            // ?.where((task) =>
            //     (task.data() as Map<String, dynamic>)
            //         .containsKey("description") &&
            //     (task.data() as Map<String, dynamic>)['type'] == 'task')
            ?.map((event) => TaskModel.fromDocumentSnapshot(event))
            .toList() ??
        [];

    // List<TaskModel> currentTasks = [];

    // for (var chapterDoc in chaptersQuery.docs) {
    //   final tasks = List<Map<String, dynamic>>.from(chapterDoc.get('tasks'));

    //   currentTasks.addAll(tasks.where((task) {
    //     final dueDate = (task['dueDate'] as Timestamp).toDate();
    //     return dueDate.isAfter(currentDate);
    //   }).map((task) => TaskModel.fromMap(task)));
    // }

    // return currentTasks;
  }

  /// Gets the past tasks as a [List] of [TaskModel] objects
  ///
  ///
  static Future<List<TaskModel>> getPastTasks() async {
    final currentDate = DateTime.now().subtract(const Duration(days: 1));
    String formattedDate = DateFormat('MMMM d, yyyy').format(currentDate);
    String currentChapter = AppInfo.currentUser.currentChapter;

    QuerySnapshot taskQuery = await AppInfo.database
        .collection("chapters")
        .doc(currentChapter)
        .collection('timedObjects')
        .where('dueDate', isGreaterThan: formattedDate)
        .orderBy('dueDate')
        .get();
    dv.log(taskQuery.docs.length.toString());
    return (taskQuery.docs as List<dynamic>?)
            // ?.where((task) =>
            //     (task.data() as Map<String, dynamic>)
            //         .containsKey("description") &&
            //     (task.data() as Map<String, dynamic>)['type'] == 'task')
            ?.map((event) => TaskModel.fromDocumentSnapshot(event))
            .toList() ??
        [];
  }

  /// Updates the provided [task] with the provided submission details
  ///
  ///
  // static Future<void> completeTask(
  //     TaskModel task,
  //     String submissionText,
  //     String submissionImage,
  //     String pdf,
  //     String timestamp,
  //     String username) async {
  //   final chapterRef =
  //       FirebaseFirestore.instance.collection('chapters').doc(task.chapterId);

  //   return FirebaseFirestore.instance.runTransaction((transaction) async {
  //     final chapterDoc = await transaction.get(chapterRef);
  //     final tasks = List<Map<String, dynamic>>.from(chapterDoc.get('tasks'));

  //     final taskIndex = tasks.indexWhere((t) => t['id'] == task.id);
  //     if (taskIndex != -1) {
  //       final updatedTask = Map<String, dynamic>.from(tasks[taskIndex]);
  //       updatedTask['usersSubmitted'] = (updatedTask['usersSubmitted'] as List)
  //           .cast<String>()
  //         ..add(username);
  //       updatedTask['submissions'] =
  //           (updatedTask['submissions'] as List<dynamic>)
  //             ..add({
  //               "pdfURL": pdf,
  //               'imageURL': submissionImage,
  //               "text": submissionText,
  //               "timestamp": timestamp,
  //               "user": username
  //             });

  //       tasks[taskIndex] = updatedTask;

  //       transaction.update(chapterRef, {'tasks': tasks});
  //     }
  //   });
  // }
}
