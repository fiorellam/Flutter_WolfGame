import 'package:game_wolf/domain/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

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
          numberSeat TEXT,
          UNIQUE(name, lastname, phone)
        )''');
  }

  Future<bool> insertUser(Database db, User user) async {
    try{
      // Verificar si el usuario ya existe en la base de datos
      List<Map<String, dynamic>> existingUser = await db.query(
        'users',
        where: 'name = ? AND lastName = ? AND phone = ?',
        whereArgs: [user.name, user.lastName, user.phone],
      );
      // Si no existe, insertar el nuevo usuario
      if (existingUser.isEmpty) {
        await db.insert(
          'users',
          {'name': user.name, 'lastName': user.lastName, 'phone': user.phone, 'numberSeat': user.numberSeat},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return true;
      } else {
        print("El usuario con ese nombre, apellido y teléfono ya existe.");
        return false;
      }
    }
    catch(e){
      print("Error inserting user : $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUsers(Database db) async {
    return await db.query('users');
  }

  Future<bool> updateUser(Database db, User user) async{
    try{
      await db.update(
        'users',
        {'name': user.name, 'lastName': user.lastName, 'phone': user.phone, 'numberSeat': user.numberSeat}, 
        where: 'id = ?',
        whereArgs: [user.id],     
      );
      return true;
    } catch(e) {
      print("Error updating user: $e");
      return false;
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