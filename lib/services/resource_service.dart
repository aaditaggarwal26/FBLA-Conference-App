import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource_model.dart';

class ResourceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all resources
  Stream<List<ResourceModel>> getResources() {
    return _firestore
        .collection('resources')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResourceModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get resources by category
  Stream<List<ResourceModel>> getResourcesByCategory(String category) {
    return _firestore
        .collection('resources')
        .where('category', isEqualTo: category)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResourceModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Create resource
  Future<void> createResource(ResourceModel resource) async {
    await _firestore.collection('resources').add(resource.toFirestore());
  }

  // Delete resource
  Future<void> deleteResource(String resourceId) async {
    await _firestore.collection('resources').doc(resourceId).delete();
  }

  // Get resource by ID
  Future<ResourceModel?> getResourceById(String id) async {
    try {
      final doc = await _firestore.collection('resources').doc(id).get();
      if (doc.exists) {
        return ResourceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
