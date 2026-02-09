module Events exposing (Prevention(..), eventsElement)

import Html exposing (Html)
import Html.Events
import Input exposing (Button(..), ButtonDirection(..))
import Json.Decode as Decode exposing (Decoder)


type Prevention
    = PreventDefault
    | AllowDefaultExcept (List Button)


eventsElement : Prevention -> (ButtonDirection -> Button -> msg) -> Html msg
eventsElement prevention makeMsg =
    let
        on : String -> Decoder Button -> ButtonDirection -> Html.Attribute msg
        on eventName decoder buttonDirection =
            Html.Events.preventDefaultOn
                eventName
                (decoder |> Decode.map (\button -> ( makeMsg buttonDirection button, shouldPreventDefault prevention button )))
    in
    Html.node
        "window-events-workaround"
        [ on "keydown" keyDecoder Down
        , on "keyup" keyDecoder Up
        , on "mousedown" mouseButtonDecoder Down
        , on "mouseup" mouseButtonDecoder Up
        ]
        []


keyDecoder : Decoder Button
keyDecoder =
    Decode.field "code" Decode.string
        |> Decode.map Key


mouseButtonDecoder : Decoder Button
mouseButtonDecoder =
    Decode.field "button" Decode.int
        |> Decode.map Mouse


shouldPreventDefault : Prevention -> Button -> Bool
shouldPreventDefault prevention button =
    case prevention of
        PreventDefault ->
            True

        AllowDefaultExcept buttons ->
            List.member button buttons
