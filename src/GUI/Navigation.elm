module GUI.Navigation exposing (replayNavigation)

import Colors
import GUI.Text
import Html exposing (Html, div, p)
import Html.Attributes as Attr


replayNavigation : Html msg
replayNavigation =
    div [ Attr.class "replayNavigation" ]
        (replayButtonsAndDescriptions
            |> List.map
                (\buttonAndDescription ->
                    p
                        []
                        (GUI.Text.string
                            (GUI.Text.Size 1)
                            Colors.white
                            (replayNavigationLine buttonAndDescription)
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


replayNavigationLine : ( String, String ) -> String
replayNavigationLine ( button, description ) =
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
