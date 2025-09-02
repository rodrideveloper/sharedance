import 'package:shared_models/shared_models.dart';

abstract class ClassRepository {
  Stream<List<ClassModel>> getClassesStream();

  Future<List<ClassModel>> getActiveClasses();

  Stream<List<ClassModel>> getClassesByProfessor(String professorId);

  Future<ClassModel?> getClassById(String classId);

  Future<void> createClass(ClassModel classModel);

  Future<void> updateClass(ClassModel classModel);

  Future<void> deleteClass(String classId);

  Future<List<ClassModel>> getClassesForWeek(DateTime startDate);
}
