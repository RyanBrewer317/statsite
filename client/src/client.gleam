import gleam/http/response.{type Response}
import gleam/int
import gleam/option.{type Option}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp
import shared/stats.{type Player, Player}
import gleam/json
import plinth/browser/document
import gleam/result
import plinth/browser/element as plinth_element

pub fn main() {
  let initial_items =
    document.query_selector("#model")
    |> result.map(plinth_element.inner_text)
    |> result.try(fn(json) {
      json.parse(json, stats.player_decoder())
      |> result.replace_error(Nil)
    })
    |> result.lazy_unwrap(fn() { panic })

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", initial_items)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(player: Player, new_strength: Int, saving: Bool, error: Option(String))
}

fn init(player) -> #(Model, Effect(Message)) {
  let model = Model(player:, new_strength: 0, saving: False, error: option.None)

  #(model, effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Message {
  ServerSavedStats(Result(Response(String), rsvp.Error(String)))
  UserSetStrength
  UserTypedNewStrength(String)
  UserSavedStats
}

fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    ServerSavedStats(Ok(_)) -> #(
      Model(..model, saving: False, error: option.None),
      effect.none(),
    )

    ServerSavedStats(Error(_)) -> #(
      Model(..model, saving: False, error: option.Some("Failed to save stats")),
      effect.none(),
    )

    UserSetStrength -> {
      let player = Player(..model.player, strength: model.new_strength)

      #(Model(..model, player:, new_strength: 0), effect.none())
    }

    UserTypedNewStrength(s) -> {
      let assert Ok(i) = int.parse(s)
      #(Model(..model, new_strength: i), effect.none())
    }

    UserSavedStats -> #(Model(..model, saving: True), save_stats(model.player))
  }
}

fn save_stats(player: Player) -> Effect(Message) {
  let body = stats.player_to_json(player)
  let url = "/api/signup"

  rsvp.post(url, body, rsvp.expect_ok_response(ServerSavedStats))
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Message) {
  let styles = [
    #("max-width", "30ch"),
    #("margin", "0 auto"),
    #("display", "flex"),
    #("flex-direction", "column"),
    #("gap", "1em"),
  ]

  html.div([attribute.styles(styles)], [
    html.h1([], [html.text("Stats")]),
    view_player(model.player),
    view_new_strength(model.new_strength),
    html.div([], [
      html.button(
        [event.on_click(UserSavedStats), attribute.disabled(model.saving)],
        [
          html.text(case model.saving {
            True -> "Saving..."
            False -> "Save"
          }),
        ],
      ),
    ]),
    case model.error {
      option.None -> element.none()
      option.Some(error) ->
        html.div([attribute.style("color", "red")], [html.text(error)])
    },
  ])
}

fn view_new_strength(new_strength: Int) -> Element(Message) {
  html.div([], [
    html.input([
      attribute.placeholder("Enter new strength"),
      attribute.value(int.to_string(new_strength)),
      event.on_input(UserTypedNewStrength),
    ]),
    html.button([event.on_click(UserSetStrength)], [html.text("set")]),
  ])
}

fn view_player(player: Player) -> Element(Message) {
  html.p([], [
    element.text(player.name <> " - " <> int.to_string(player.strength)),
  ])
}
