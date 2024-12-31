import 'package:game_wolf/domain/user.dart';
import 'package:game_wolf/domain/player.dart';

class UserPlayerMapper{
  //Metodo para convertir un objeto User en un objeto Player
  static Player userToPlayer(User user){
    return Player(
      id: DateTime.now().millisecondsSinceEpoch, //ID unico
      name: user.name,
      lastName: user.lastName,
      phone: user.phone,
      role: "Aldeano",
      state: "vivo" //Estado inicial
    );
  }

  //Metodo para convertir un objeto Player en un objeto User 
  static User playerToUser(Player player){
    return User(
      id: player.id,
      name: player.name,
      lastName: player.lastName,
      phone: player.phone
    );
  }
}