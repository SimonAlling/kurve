module FirstRoundTest exposing (theTest)

import Colors
import Effect exposing (Effect(..))
import Expect
import Input exposing (Button(..))
import List exposing (repeat)
import Main exposing (Model, Msg(..), init)
import Test
import TestHelpers.EndToEnd exposing (endToEndTest)
import TestHelpers.PlayerInput exposing (pressAndRelease)
import Types.FrameTime exposing (FrameTime)


theTest : Test.Test
theTest =
    let
        ( _, actualEffects ) =
            endToEndTest initialModel messages
    in
    Test.test "How the first round starts" <|
        \_ ->
            actualEffects
                |> Expect.equalLists expectedEffects


initialModel : Model
initialModel =
    init () |> Tuple.first


messages : List Msg
messages =
    List.concat
        [ -- User proceeds to lobby:
          pressAndRelease (Key "Space")

        -- Green joins:
        , pressAndRelease (Key "ArrowLeft")

        -- Game is started:
        , pressAndRelease (Key "Space")

        -- Kurve spawns:
        , repeat 7 SpawnTick

        -- Kurve moves for a while, preferably until it has created at least one hole:
        , repeat 120 (AnimationFrame frameDeltaInMs)
        ]


{-| This isn't necessarily the only acceptable way for the first round to start, but with the effects exhaustively listed like this, every single change in observable behavior will be explicit in the diff.
-}
expectedEffects : List Effect
expectedEffects =
    [ DoNothing
    , DoNothing
    , DoNothing
    , DoNothing
    , ClearEverything
    , DoNothing
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = []
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 211, y = 192 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = []
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 211, y = 192 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = []
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 211, y = 192 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 211, y = 192 } ) ]
        , headDrawing = []
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 212, y = 192 } ) ]
        , headDrawing = [ ( Colors.green, { x = 212, y = 192 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 213, y = 191 } ) ]
        , headDrawing = [ ( Colors.green, { x = 213, y = 191 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 214, y = 191 } ) ]
        , headDrawing = [ ( Colors.green, { x = 214, y = 191 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 215, y = 191 } ) ]
        , headDrawing = [ ( Colors.green, { x = 215, y = 191 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 216, y = 191 } ) ]
        , headDrawing = [ ( Colors.green, { x = 216, y = 191 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 217, y = 190 } ) ]
        , headDrawing = [ ( Colors.green, { x = 217, y = 190 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 218, y = 190 } ) ]
        , headDrawing = [ ( Colors.green, { x = 218, y = 190 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 219, y = 190 } ) ]
        , headDrawing = [ ( Colors.green, { x = 219, y = 190 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 220, y = 190 } ) ]
        , headDrawing = [ ( Colors.green, { x = 220, y = 190 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 221, y = 190 } ) ]
        , headDrawing = [ ( Colors.green, { x = 221, y = 190 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 222, y = 189 } ) ]
        , headDrawing = [ ( Colors.green, { x = 222, y = 189 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 223, y = 189 } ) ]
        , headDrawing = [ ( Colors.green, { x = 223, y = 189 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 224, y = 189 } ) ]
        , headDrawing = [ ( Colors.green, { x = 224, y = 189 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 225, y = 189 } ) ]
        , headDrawing = [ ( Colors.green, { x = 225, y = 189 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 226, y = 188 } ) ]
        , headDrawing = [ ( Colors.green, { x = 226, y = 188 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 227, y = 188 } ) ]
        , headDrawing = [ ( Colors.green, { x = 227, y = 188 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 228, y = 188 } ) ]
        , headDrawing = [ ( Colors.green, { x = 228, y = 188 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 229, y = 188 } ) ]
        , headDrawing = [ ( Colors.green, { x = 229, y = 188 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 230, y = 188 } ) ]
        , headDrawing = [ ( Colors.green, { x = 230, y = 188 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 230, y = 187 } ) ]
        , headDrawing = [ ( Colors.green, { x = 230, y = 187 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 231, y = 187 } ) ]
        , headDrawing = [ ( Colors.green, { x = 231, y = 187 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 232, y = 187 } ) ]
        , headDrawing = [ ( Colors.green, { x = 232, y = 187 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 233, y = 187 } ) ]
        , headDrawing = [ ( Colors.green, { x = 233, y = 187 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 234, y = 186 } ) ]
        , headDrawing = [ ( Colors.green, { x = 234, y = 186 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 235, y = 186 } ) ]
        , headDrawing = [ ( Colors.green, { x = 235, y = 186 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 236, y = 186 } ) ]
        , headDrawing = [ ( Colors.green, { x = 236, y = 186 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 237, y = 186 } ) ]
        , headDrawing = [ ( Colors.green, { x = 237, y = 186 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 238, y = 185 } ) ]
        , headDrawing = [ ( Colors.green, { x = 238, y = 185 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 239, y = 185 } ) ]
        , headDrawing = [ ( Colors.green, { x = 239, y = 185 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 240, y = 185 } ) ]
        , headDrawing = [ ( Colors.green, { x = 240, y = 185 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 241, y = 185 } ) ]
        , headDrawing = [ ( Colors.green, { x = 241, y = 185 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 242, y = 185 } ) ]
        , headDrawing = [ ( Colors.green, { x = 242, y = 185 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 243, y = 184 } ) ]
        , headDrawing = [ ( Colors.green, { x = 243, y = 184 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 244, y = 184 } ) ]
        , headDrawing = [ ( Colors.green, { x = 244, y = 184 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 245, y = 184 } ) ]
        , headDrawing = [ ( Colors.green, { x = 245, y = 184 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 246, y = 184 } ) ]
        , headDrawing = [ ( Colors.green, { x = 246, y = 184 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 247, y = 183 } ) ]
        , headDrawing = [ ( Colors.green, { x = 247, y = 183 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 248, y = 183 } ) ]
        , headDrawing = [ ( Colors.green, { x = 248, y = 183 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 249, y = 183 } ) ]
        , headDrawing = [ ( Colors.green, { x = 249, y = 183 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 250, y = 183 } ) ]
        , headDrawing = [ ( Colors.green, { x = 250, y = 183 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 251, y = 182 } ) ]
        , headDrawing = [ ( Colors.green, { x = 251, y = 182 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 252, y = 182 } ) ]
        , headDrawing = [ ( Colors.green, { x = 252, y = 182 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 253, y = 182 } ) ]
        , headDrawing = [ ( Colors.green, { x = 253, y = 182 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 254, y = 182 } ) ]
        , headDrawing = [ ( Colors.green, { x = 254, y = 182 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 255, y = 182 } ) ]
        , headDrawing = [ ( Colors.green, { x = 255, y = 182 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 256, y = 181 } ) ]
        , headDrawing = [ ( Colors.green, { x = 256, y = 181 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 257, y = 181 } ) ]
        , headDrawing = [ ( Colors.green, { x = 257, y = 181 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 258, y = 181 } ) ]
        , headDrawing = [ ( Colors.green, { x = 258, y = 181 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 259, y = 181 } ) ]
        , headDrawing = [ ( Colors.green, { x = 259, y = 181 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 260, y = 180 } ) ]
        , headDrawing = [ ( Colors.green, { x = 260, y = 180 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 261, y = 180 } ) ]
        , headDrawing = [ ( Colors.green, { x = 261, y = 180 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 262, y = 180 } ) ]
        , headDrawing = [ ( Colors.green, { x = 262, y = 180 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 263, y = 180 } ) ]
        , headDrawing = [ ( Colors.green, { x = 263, y = 180 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 264, y = 180 } ) ]
        , headDrawing = [ ( Colors.green, { x = 264, y = 180 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 265, y = 179 } ) ]
        , headDrawing = [ ( Colors.green, { x = 265, y = 179 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 266, y = 179 } ) ]
        , headDrawing = [ ( Colors.green, { x = 266, y = 179 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 267, y = 179 } ) ]
        , headDrawing = [ ( Colors.green, { x = 267, y = 179 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 267, y = 179 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 268, y = 178 } ) ]
        , headDrawing = [ ( Colors.green, { x = 268, y = 178 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 269, y = 178 } ) ]
        , headDrawing = [ ( Colors.green, { x = 269, y = 178 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 270, y = 178 } ) ]
        , headDrawing = [ ( Colors.green, { x = 270, y = 178 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 271, y = 178 } ) ]
        , headDrawing = [ ( Colors.green, { x = 271, y = 178 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 272, y = 177 } ) ]
        , headDrawing = [ ( Colors.green, { x = 272, y = 177 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 273, y = 177 } ) ]
        , headDrawing = [ ( Colors.green, { x = 273, y = 177 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 274, y = 177 } ) ]
        , headDrawing = [ ( Colors.green, { x = 274, y = 177 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 275, y = 177 } ) ]
        , headDrawing = [ ( Colors.green, { x = 275, y = 177 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 276, y = 177 } ) ]
        , headDrawing = [ ( Colors.green, { x = 276, y = 177 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 277, y = 176 } ) ]
        , headDrawing = [ ( Colors.green, { x = 277, y = 176 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 278, y = 176 } ) ]
        , headDrawing = [ ( Colors.green, { x = 278, y = 176 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 279, y = 176 } ) ]
        , headDrawing = [ ( Colors.green, { x = 279, y = 176 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 280, y = 176 } ) ]
        , headDrawing = [ ( Colors.green, { x = 280, y = 176 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 281, y = 175 } ) ]
        , headDrawing = [ ( Colors.green, { x = 281, y = 175 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 282, y = 175 } ) ]
        , headDrawing = [ ( Colors.green, { x = 282, y = 175 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 283, y = 175 } ) ]
        , headDrawing = [ ( Colors.green, { x = 283, y = 175 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 284, y = 175 } ) ]
        , headDrawing = [ ( Colors.green, { x = 284, y = 175 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 285, y = 175 } ) ]
        , headDrawing = [ ( Colors.green, { x = 285, y = 175 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 286, y = 174 } ) ]
        , headDrawing = [ ( Colors.green, { x = 286, y = 174 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 287, y = 174 } ) ]
        , headDrawing = [ ( Colors.green, { x = 287, y = 174 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 288, y = 174 } ) ]
        , headDrawing = [ ( Colors.green, { x = 288, y = 174 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 289, y = 174 } ) ]
        , headDrawing = [ ( Colors.green, { x = 289, y = 174 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 290, y = 173 } ) ]
        , headDrawing = [ ( Colors.green, { x = 290, y = 173 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 291, y = 173 } ) ]
        , headDrawing = [ ( Colors.green, { x = 291, y = 173 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 292, y = 173 } ) ]
        , headDrawing = [ ( Colors.green, { x = 292, y = 173 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 293, y = 173 } ) ]
        , headDrawing = [ ( Colors.green, { x = 293, y = 173 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 294, y = 172 } ) ]
        , headDrawing = [ ( Colors.green, { x = 294, y = 172 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 295, y = 172 } ) ]
        , headDrawing = [ ( Colors.green, { x = 295, y = 172 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 296, y = 172 } ) ]
        , headDrawing = [ ( Colors.green, { x = 296, y = 172 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 297, y = 172 } ) ]
        , headDrawing = [ ( Colors.green, { x = 297, y = 172 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 298, y = 172 } ) ]
        , headDrawing = [ ( Colors.green, { x = 298, y = 172 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 299, y = 171 } ) ]
        , headDrawing = [ ( Colors.green, { x = 299, y = 171 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 300, y = 171 } ) ]
        , headDrawing = [ ( Colors.green, { x = 300, y = 171 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 301, y = 171 } ) ]
        , headDrawing = [ ( Colors.green, { x = 301, y = 171 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 302, y = 171 } ) ]
        , headDrawing = [ ( Colors.green, { x = 302, y = 171 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 303, y = 170 } ) ]
        , headDrawing = [ ( Colors.green, { x = 303, y = 170 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 304, y = 170 } ) ]
        , headDrawing = [ ( Colors.green, { x = 304, y = 170 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 304, y = 170 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 305, y = 170 } ) ]
        , headDrawing = [ ( Colors.green, { x = 305, y = 170 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 306, y = 169 } ) ]
        , headDrawing = [ ( Colors.green, { x = 306, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 307, y = 169 } ) ]
        , headDrawing = [ ( Colors.green, { x = 307, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 308, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 309, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 310, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 311, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 312, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 313, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 314, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 315, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 316, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 317, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 318, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 319, y = 167 } ) ]
        , headDrawing = [ ( Colors.green, { x = 319, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 320, y = 166 } ) ]
        , headDrawing = [ ( Colors.green, { x = 320, y = 166 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 321, y = 166 } ) ]
        , headDrawing = [ ( Colors.green, { x = 321, y = 166 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 322, y = 166 } ) ]
        , headDrawing = [ ( Colors.green, { x = 322, y = 166 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 323, y = 166 } ) ]
        , headDrawing = [ ( Colors.green, { x = 323, y = 166 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 324, y = 165 } ) ]
        , headDrawing = [ ( Colors.green, { x = 324, y = 165 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 325, y = 165 } ) ]
        , headDrawing = [ ( Colors.green, { x = 325, y = 165 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 326, y = 165 } ) ]
        , headDrawing = [ ( Colors.green, { x = 326, y = 165 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 327, y = 165 } ) ]
        , headDrawing = [ ( Colors.green, { x = 327, y = 165 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 328, y = 164 } ) ]
        , headDrawing = [ ( Colors.green, { x = 328, y = 164 } ) ]
        }
    ]


frameDeltaInMs : FrameTime
frameDeltaInMs =
    1000 / toFloat refreshRate


refreshRate : Int
refreshRate =
    60
