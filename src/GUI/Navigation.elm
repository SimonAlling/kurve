module GUI.Navigation exposing (ButtonAndDescription, maxButtonLength, showEntry)


type alias ButtonAndDescription =
    ( String, String )


showEntry : Int -> ButtonAndDescription -> String
showEntry firstColumnWidth ( button, description ) =
    String.padRight (firstColumnWidth + columnSpacing) ' ' button
        ++ description


columnSpacing : Int
columnSpacing =
    2


maxButtonLength : List ButtonAndDescription -> Int
maxButtonLength buttonsAndDescriptions =
    buttonsAndDescriptions
        |> List.map (Tuple.first >> String.length)
        |> List.maximum
        |> Maybe.withDefault 0
