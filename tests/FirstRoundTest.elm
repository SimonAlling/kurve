module FirstRoundTest exposing (theTest)

import Colors
import Effect exposing (Effect(..))
import Expect
import Input exposing (Button(..))
import List exposing (repeat)
import Main exposing (Model, Msg(..), init)
import Test
import TestHelpers exposing (getNumberOfSpawnTicks)
import TestHelpers.EndToEnd exposing (endToEndTest)
import TestHelpers.PlayerInput exposing (pressAndRelease)
import Types.FrameTime exposing (FrameTime)


theTest : Test.Test
theTest =
    let
        ( _, actualEffects ) =
            endToEndTest initialModel (messages (getNumberOfSpawnTicks initialModel.config.spawn))
    in
    Test.test "How the first round starts" <|
        \_ ->
            actualEffects
                |> Expect.equalLists expectedEffects


initialModel : Model
initialModel =
    init () |> Tuple.first


messages : Int -> List Msg
messages numberOfSpawnTicks =
    List.concat
        [ -- User proceeds to lobby:
          pressAndRelease (Key "Space")

        -- Green joins:
        , pressAndRelease (Key "ArrowLeft")

        -- Game is started:
        , pressAndRelease (Key "Space")

        -- Kurve spawns:
        , repeat numberOfSpawnTicks SpawnTick

        -- Kurve moves for a while, preferably until it has created at least one hole:
        , repeat 240 (AnimationFrame frameDeltaInMs)
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
        { bodyDrawing = []
        , headDrawing = []
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
        { bodyDrawing = [ ( Colors.green, { x = 308, y = 169 } ) ]
        , headDrawing = [ ( Colors.green, { x = 308, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 309, y = 169 } ) ]
        , headDrawing = [ ( Colors.green, { x = 309, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 310, y = 169 } ) ]
        , headDrawing = [ ( Colors.green, { x = 310, y = 169 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 311, y = 168 } ) ]
        , headDrawing = [ ( Colors.green, { x = 311, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 312, y = 168 } ) ]
        , headDrawing = [ ( Colors.green, { x = 312, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 313, y = 168 } ) ]
        , headDrawing = [ ( Colors.green, { x = 313, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 314, y = 168 } ) ]
        , headDrawing = [ ( Colors.green, { x = 314, y = 168 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 315, y = 167 } ) ]
        , headDrawing = [ ( Colors.green, { x = 315, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 316, y = 167 } ) ]
        , headDrawing = [ ( Colors.green, { x = 316, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 317, y = 167 } ) ]
        , headDrawing = [ ( Colors.green, { x = 317, y = 167 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 318, y = 167 } ) ]
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
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 329, y = 164 } ) ]
        , headDrawing = [ ( Colors.green, { x = 329, y = 164 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 330, y = 164 } ) ]
        , headDrawing = [ ( Colors.green, { x = 330, y = 164 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 331, y = 164 } ) ]
        , headDrawing = [ ( Colors.green, { x = 331, y = 164 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 332, y = 164 } ) ]
        , headDrawing = [ ( Colors.green, { x = 332, y = 164 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 333, y = 163 } ) ]
        , headDrawing = [ ( Colors.green, { x = 333, y = 163 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 334, y = 163 } ) ]
        , headDrawing = [ ( Colors.green, { x = 334, y = 163 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 335, y = 163 } ) ]
        , headDrawing = [ ( Colors.green, { x = 335, y = 163 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 336, y = 163 } ) ]
        , headDrawing = [ ( Colors.green, { x = 336, y = 163 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 337, y = 162 } ) ]
        , headDrawing = [ ( Colors.green, { x = 337, y = 162 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 338, y = 162 } ) ]
        , headDrawing = [ ( Colors.green, { x = 338, y = 162 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 339, y = 162 } ) ]
        , headDrawing = [ ( Colors.green, { x = 339, y = 162 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 340, y = 162 } ) ]
        , headDrawing = [ ( Colors.green, { x = 340, y = 162 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 341, y = 162 } ) ]
        , headDrawing = [ ( Colors.green, { x = 341, y = 162 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 341, y = 161 } ) ]
        , headDrawing = [ ( Colors.green, { x = 341, y = 161 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 342, y = 161 } ) ]
        , headDrawing = [ ( Colors.green, { x = 342, y = 161 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 343, y = 161 } ) ]
        , headDrawing = [ ( Colors.green, { x = 343, y = 161 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 344, y = 161 } ) ]
        , headDrawing = [ ( Colors.green, { x = 344, y = 161 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 345, y = 160 } ) ]
        , headDrawing = [ ( Colors.green, { x = 345, y = 160 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 346, y = 160 } ) ]
        , headDrawing = [ ( Colors.green, { x = 346, y = 160 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 347, y = 160 } ) ]
        , headDrawing = [ ( Colors.green, { x = 347, y = 160 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 348, y = 160 } ) ]
        , headDrawing = [ ( Colors.green, { x = 348, y = 160 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 349, y = 159 } ) ]
        , headDrawing = [ ( Colors.green, { x = 349, y = 159 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 350, y = 159 } ) ]
        , headDrawing = [ ( Colors.green, { x = 350, y = 159 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 351, y = 159 } ) ]
        , headDrawing = [ ( Colors.green, { x = 351, y = 159 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 352, y = 159 } ) ]
        , headDrawing = [ ( Colors.green, { x = 352, y = 159 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 353, y = 159 } ) ]
        , headDrawing = [ ( Colors.green, { x = 353, y = 159 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 354, y = 158 } ) ]
        , headDrawing = [ ( Colors.green, { x = 354, y = 158 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 355, y = 158 } ) ]
        , headDrawing = [ ( Colors.green, { x = 355, y = 158 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 356, y = 158 } ) ]
        , headDrawing = [ ( Colors.green, { x = 356, y = 158 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 357, y = 158 } ) ]
        , headDrawing = [ ( Colors.green, { x = 357, y = 158 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 358, y = 157 } ) ]
        , headDrawing = [ ( Colors.green, { x = 358, y = 157 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 359, y = 157 } ) ]
        , headDrawing = [ ( Colors.green, { x = 359, y = 157 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 360, y = 157 } ) ]
        , headDrawing = [ ( Colors.green, { x = 360, y = 157 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 361, y = 157 } ) ]
        , headDrawing = [ ( Colors.green, { x = 361, y = 157 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 362, y = 156 } ) ]
        , headDrawing = [ ( Colors.green, { x = 362, y = 156 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 363, y = 156 } ) ]
        , headDrawing = [ ( Colors.green, { x = 363, y = 156 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 364, y = 156 } ) ]
        , headDrawing = [ ( Colors.green, { x = 364, y = 156 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 365, y = 156 } ) ]
        , headDrawing = [ ( Colors.green, { x = 365, y = 156 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 366, y = 156 } ) ]
        , headDrawing = [ ( Colors.green, { x = 366, y = 156 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 367, y = 155 } ) ]
        , headDrawing = [ ( Colors.green, { x = 367, y = 155 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 368, y = 155 } ) ]
        , headDrawing = [ ( Colors.green, { x = 368, y = 155 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 369, y = 155 } ) ]
        , headDrawing = [ ( Colors.green, { x = 369, y = 155 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 370, y = 155 } ) ]
        , headDrawing = [ ( Colors.green, { x = 370, y = 155 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 371, y = 154 } ) ]
        , headDrawing = [ ( Colors.green, { x = 371, y = 154 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 372, y = 154 } ) ]
        , headDrawing = [ ( Colors.green, { x = 372, y = 154 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 373, y = 154 } ) ]
        , headDrawing = [ ( Colors.green, { x = 373, y = 154 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 374, y = 154 } ) ]
        , headDrawing = [ ( Colors.green, { x = 374, y = 154 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 375, y = 154 } ) ]
        , headDrawing = [ ( Colors.green, { x = 375, y = 154 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 376, y = 153 } ) ]
        , headDrawing = [ ( Colors.green, { x = 376, y = 153 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 377, y = 153 } ) ]
        , headDrawing = [ ( Colors.green, { x = 377, y = 153 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 378, y = 153 } ) ]
        , headDrawing = [ ( Colors.green, { x = 378, y = 153 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 378, y = 153 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 379, y = 152 } ) ]
        , headDrawing = [ ( Colors.green, { x = 379, y = 152 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 380, y = 152 } ) ]
        , headDrawing = [ ( Colors.green, { x = 380, y = 152 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 381, y = 152 } ) ]
        , headDrawing = [ ( Colors.green, { x = 381, y = 152 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 382, y = 152 } ) ]
        , headDrawing = [ ( Colors.green, { x = 382, y = 152 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 383, y = 151 } ) ]
        , headDrawing = [ ( Colors.green, { x = 383, y = 151 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 384, y = 151 } ) ]
        , headDrawing = [ ( Colors.green, { x = 384, y = 151 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 385, y = 151 } ) ]
        , headDrawing = [ ( Colors.green, { x = 385, y = 151 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 386, y = 151 } ) ]
        , headDrawing = [ ( Colors.green, { x = 386, y = 151 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 387, y = 151 } ) ]
        , headDrawing = [ ( Colors.green, { x = 387, y = 151 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 388, y = 150 } ) ]
        , headDrawing = [ ( Colors.green, { x = 388, y = 150 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 389, y = 150 } ) ]
        , headDrawing = [ ( Colors.green, { x = 389, y = 150 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 390, y = 150 } ) ]
        , headDrawing = [ ( Colors.green, { x = 390, y = 150 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 391, y = 150 } ) ]
        , headDrawing = [ ( Colors.green, { x = 391, y = 150 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 392, y = 149 } ) ]
        , headDrawing = [ ( Colors.green, { x = 392, y = 149 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 393, y = 149 } ) ]
        , headDrawing = [ ( Colors.green, { x = 393, y = 149 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 394, y = 149 } ) ]
        , headDrawing = [ ( Colors.green, { x = 394, y = 149 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 395, y = 149 } ) ]
        , headDrawing = [ ( Colors.green, { x = 395, y = 149 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 396, y = 149 } ) ]
        , headDrawing = [ ( Colors.green, { x = 396, y = 149 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 397, y = 148 } ) ]
        , headDrawing = [ ( Colors.green, { x = 397, y = 148 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 398, y = 148 } ) ]
        , headDrawing = [ ( Colors.green, { x = 398, y = 148 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 399, y = 148 } ) ]
        , headDrawing = [ ( Colors.green, { x = 399, y = 148 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 400, y = 148 } ) ]
        , headDrawing = [ ( Colors.green, { x = 400, y = 148 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 401, y = 147 } ) ]
        , headDrawing = [ ( Colors.green, { x = 401, y = 147 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 402, y = 147 } ) ]
        , headDrawing = [ ( Colors.green, { x = 402, y = 147 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 403, y = 147 } ) ]
        , headDrawing = [ ( Colors.green, { x = 403, y = 147 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 404, y = 147 } ) ]
        , headDrawing = [ ( Colors.green, { x = 404, y = 147 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 405, y = 146 } ) ]
        , headDrawing = [ ( Colors.green, { x = 405, y = 146 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 406, y = 146 } ) ]
        , headDrawing = [ ( Colors.green, { x = 406, y = 146 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 407, y = 146 } ) ]
        , headDrawing = [ ( Colors.green, { x = 407, y = 146 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 408, y = 146 } ) ]
        , headDrawing = [ ( Colors.green, { x = 408, y = 146 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 409, y = 146 } ) ]
        , headDrawing = [ ( Colors.green, { x = 409, y = 146 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 410, y = 145 } ) ]
        , headDrawing = [ ( Colors.green, { x = 410, y = 145 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 411, y = 145 } ) ]
        , headDrawing = [ ( Colors.green, { x = 411, y = 145 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 412, y = 145 } ) ]
        , headDrawing = [ ( Colors.green, { x = 412, y = 145 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 413, y = 145 } ) ]
        , headDrawing = [ ( Colors.green, { x = 413, y = 145 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 414, y = 144 } ) ]
        , headDrawing = [ ( Colors.green, { x = 414, y = 144 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 415, y = 144 } ) ]
        , headDrawing = [ ( Colors.green, { x = 415, y = 144 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 415, y = 144 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 416, y = 144 } ) ]
        , headDrawing = [ ( Colors.green, { x = 416, y = 144 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 417, y = 143 } ) ]
        , headDrawing = [ ( Colors.green, { x = 417, y = 143 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 418, y = 143 } ) ]
        , headDrawing = [ ( Colors.green, { x = 418, y = 143 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 419, y = 143 } ) ]
        , headDrawing = [ ( Colors.green, { x = 419, y = 143 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 420, y = 143 } ) ]
        , headDrawing = [ ( Colors.green, { x = 420, y = 143 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 421, y = 143 } ) ]
        , headDrawing = [ ( Colors.green, { x = 421, y = 143 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 422, y = 142 } ) ]
        , headDrawing = [ ( Colors.green, { x = 422, y = 142 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 423, y = 142 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 424, y = 142 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 425, y = 142 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 426, y = 141 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 427, y = 141 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 428, y = 141 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 429, y = 141 } ) ]
        }
    , DrawSomething
        { bodyDrawing = []
        , headDrawing = [ ( Colors.green, { x = 430, y = 141 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 431, y = 140 } ) ]
        , headDrawing = [ ( Colors.green, { x = 431, y = 140 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 432, y = 140 } ) ]
        , headDrawing = [ ( Colors.green, { x = 432, y = 140 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 433, y = 140 } ) ]
        , headDrawing = [ ( Colors.green, { x = 433, y = 140 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 434, y = 140 } ) ]
        , headDrawing = [ ( Colors.green, { x = 434, y = 140 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 435, y = 139 } ) ]
        , headDrawing = [ ( Colors.green, { x = 435, y = 139 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 436, y = 139 } ) ]
        , headDrawing = [ ( Colors.green, { x = 436, y = 139 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 437, y = 139 } ) ]
        , headDrawing = [ ( Colors.green, { x = 437, y = 139 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 438, y = 139 } ) ]
        , headDrawing = [ ( Colors.green, { x = 438, y = 139 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 439, y = 138 } ) ]
        , headDrawing = [ ( Colors.green, { x = 439, y = 138 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 440, y = 138 } ) ]
        , headDrawing = [ ( Colors.green, { x = 440, y = 138 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 441, y = 138 } ) ]
        , headDrawing = [ ( Colors.green, { x = 441, y = 138 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 442, y = 138 } ) ]
        , headDrawing = [ ( Colors.green, { x = 442, y = 138 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 443, y = 138 } ) ]
        , headDrawing = [ ( Colors.green, { x = 443, y = 138 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 444, y = 137 } ) ]
        , headDrawing = [ ( Colors.green, { x = 444, y = 137 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 445, y = 137 } ) ]
        , headDrawing = [ ( Colors.green, { x = 445, y = 137 } ) ]
        }
    ]


frameDeltaInMs : FrameTime
frameDeltaInMs =
    1000 / toFloat refreshRate


refreshRate : Int
refreshRate =
    60
