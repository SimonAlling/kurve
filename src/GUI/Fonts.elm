module GUI.Fonts exposing (Font(..), height)


type Font
    = BGIDefault
    | BGIStroked


height : Font -> Int
height font =
    case font of
        BGIDefault ->
            8

        BGIStroked ->
            65
