module GUI.Fonts exposing (Font(..), bgiDefault8x8, bgiStroked28x43)


type Font
    = Font { width : Int, height : Int, resourceName : String }


bgiDefault8x8 : Font
bgiDefault8x8 =
    Font { width = 8, height = 8, resourceName = "bgi-default-8x8" }


bgiStroked28x43 : Font
bgiStroked28x43 =
    Font { width = 28, height = 43, resourceName = "bgi-stroked" }
