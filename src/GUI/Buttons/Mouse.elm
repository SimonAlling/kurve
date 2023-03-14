module GUI.Buttons.Mouse exposing (mouseButtonRepresentation)


mouseButtonRepresentation : Int -> String
mouseButtonRepresentation n =
    case n of
        0 ->
            -- From the original game.
            "L.Mouse"

        1 ->
            "M.Mouse"

        2 ->
            -- From the original game.
            "R.Mouse"

        _ ->
            "Mouse " ++ String.fromInt n
