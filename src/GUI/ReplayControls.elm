module GUI.ReplayControls exposing (replayControls)

import Colors
import GUI.Text
import Html exposing (Html, div, p)
import Html.Attributes as Attr


replayControls : Html msg
replayControls =
    div [ Attr.class "replayControls" ]
        (replayButtonsAndDescriptions
            |> List.map
                (\buttonAndDescription ->
                    p
                        []
                        (GUI.Text.string
                            (GUI.Text.Size 1)
                            Colors.white
                            (replayControlLine buttonAndDescription)
                        )
                )
        )


replayButtonsAndDescriptions : List ( String, String )
replayButtonsAndDescriptions =
    [ ( "Space", "Pause" )
    , ( "L.Arrow", "Back" )
    , ( "R.Arrow", "Forward" )
    , ( "E", "Step" )
    , ( "R", "Restart" )
    ]


replayControlLine : ( String, String ) -> String
replayControlLine ( button, description ) =
    button
        ++ String.repeat (maxButtonLength - String.length button + columnSpacing) " "
        ++ description


columnSpacing : Int
columnSpacing =
    2


maxButtonLength : Int
maxButtonLength =
    replayButtonsAndDescriptions
        |> List.map (Tuple.first >> String.length)
        |> List.maximum
        |> Maybe.withDefault 0
