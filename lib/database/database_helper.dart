import 'package:game_wolf/domain/user.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';

class DatabaseHelper{

  static Database? _database;

  Future<Database> getDatabase() async {
    if(_database != null){
      return _database!;
    }

    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'wolf_database_sqlite.db');
    //Se abre la base de datos solo si no esta abierta
    _database = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _database!;
  }

  void _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT, 
          lastName TEXT,
          phone TEXT,
          numberSeat TEXT
        )''');
  }

  Future<void> insertUser(Database db, User user) async {
    try{
      await db.insert(
        'users',
        {'name': user.name, 'lastName': user.lastName, 'phone': user.phone, 'numberSeat': user.numberSeat},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    catch(e){
      print("Error inserting user : $e");
    }
  }

  Future<List<Map<String, dynamic>>> getUsers(Database db) async {
    return await db.query('users');
  }

  Future<void> updateUser(Database db, User user) async{
    try{
      await db.update(
        'users',
        {'name': user.name, 'lastName': user.lastName, 'phone': user.phone, 'numberSeat': user.numberSeat}, 
        where: 'id = ?',
        whereArgs: [user.id],     
      );
    } catch(e) {
      print("Error updating user: $e");
    }
  }

  Future<void> deleteUser(Database db, User user) async {
    try{
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch(e){
      print('Error deleting user');
    }
}
}