import gleam/dynamic/decode
import gleam/json

pub type Player {
  Player(name: String, strength: Int)
}

pub fn player_decoder() -> decode.Decoder(Player) {
  use name <- decode.field("name", decode.string)
  use strength <- decode.field("strength", decode.int)
  decode.success(Player(name:, strength:))
}

pub fn player_to_json(player: Player) -> json.Json {
  let Player(name:, strength:) = player
  json.object([#("name", json.string(name)), #("strength", json.int(strength))])
}