module GUI.Controls exposing (showControls, showExtraControls)

import GUI.Buttons.Keyboard exposing (keyCodeRepresentation)
import GUI.Buttons.Mouse exposing (mouseButtonRepresentation)
import Input exposing (Button)
import Types.Player exposing (Player)


showControls : Player -> ( String, String )
showControls { controls } =
    let
        showFirst : List Button -> String
        showFirst =
            List.head >> Maybe.map showButton >> Maybe.withDefault "N/A"
    in
    Tuple.mapBoth showFirst showFirst controls


showExtraControls : Player -> String
showExtraControls { controls } =
    let
        ( left, right ) =
            controls

        allExtra : List Button
        allExtra =
            List.drop 1 left ++ List.drop 1 right
    in
    allExtra
        |> List.map showButton
        |> String.join " "


showButton : Button -> String
showButton button =
    let
        representation : String
        representation =
            case button of
                Input.Mouse n ->
                    mouseButtonRepresentation n

                Input.Key keyCode ->
                    keyCodeRepresentation keyCode

        charsToDrop : Int
        charsToDrop =
            String.length representation - maxLength
    in
    String.dropRight charsToDrop representation


{-| The purpose of this limit is to prevent unexpected layout breakage caused either by

  - an explicitly defined representation, or
  - a key code that we don't have a human-readable representation for.

7 characters is the maximum in the original game (L.Arrow, D.Arrow, L.Mouse, R.Mouse).

8 characters is the maximum that is guaranteed to fit to the left of "READY" in the lobby of the original game.

-}
maxLength : Int
maxLength =
    8
