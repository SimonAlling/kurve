module ReplayTest exposing (theTest)

import App exposing (AppState(..))
import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Expect
import Game exposing (ActiveGameState(..), GameState(..), LiveOrReplay(..), PausedOrNot(..), prepareReplayRound)
import Input exposing (Button(..))
import List exposing (repeat)
import Main exposing (Model, Msg(..))
import Players exposing (initialPlayers)
import Round exposing (Round)
import Set
import Test
import TestHelpers exposing (playOutRound)
import TestHelpers.EndToEnd exposing (endToEndTest)
import TestHelpers.PlayerInput exposing (pressAndRelease)
import TestScenarioHelpers exposing (roundWith)
import TestScenarios.ReplayStraightVerticalLine
import Types.FrameTime exposing (FrameTime)
import Types.Tick as Tick


theTest : Test.Test
theTest =
    let
        ( _, actualEffects ) =
            endToEndTest initialModel messages
    in
    Test.test "Replay seeking (straight line)" <|
        \_ ->
            actualEffects
                |> Expect.equalLists expectedEffects


config : Config
config =
    TestScenarios.ReplayStraightVerticalLine.config


initialModel : Model
initialModel =
    let
        ( _, finishedRound ) =
            playOutRound config (roundWith TestScenarios.ReplayStraightVerticalLine.spawnedKurves)
    in
    { pressedButtons = Set.empty
    , appState = InGame (Active (Replay finishedRound) NotPaused (Moving 0 Tick.genesis initialRound))
    , config = config
    , players = initialPlayers
    }


initialRound : Round
initialRound =
    prepareReplayRound config.world (roundWith TestScenarios.ReplayStraightVerticalLine.spawnedKurves)


messages : List Msg
messages =
    List.concat
        [ -- A short while passes by:
          repeat 10 (AnimationFrame frameDeltaInMs)

        -- User skips forward:
        , pressAndRelease (Key "ArrowRight")

        -- User waits for a second:
        , repeat 60 (AnimationFrame frameDeltaInMs)

        -- User rewinds twice in quick succession:
        , pressAndRelease (Key "ArrowLeft")
        , repeat 10 (AnimationFrame frameDeltaInMs)
        , pressAndRelease (Key "ArrowLeft")

        -- A short while passes by:
        , repeat 10 (AnimationFrame frameDeltaInMs)

        -- We deliberately stop here to keep the list of expected effects moderately sized.
        ]


expectedEffects : List Effect
expectedEffects =
    [ DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 101 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 101 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 102 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 102 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 103 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 103 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 104 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 104 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 105 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 105 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 106 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 106 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 107 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 107 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 108 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 108 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 109 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 109 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 110 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 110 } ) ]
        }
    , DrawSomething
        { bodyDrawing =
            [ ( Colors.green, { x = 100, y = 111 } )
            , ( Colors.green, { x = 100, y = 112 } )
            , ( Colors.green, { x = 100, y = 113 } )
            , ( Colors.green, { x = 100, y = 114 } )
            , ( Colors.green, { x = 100, y = 115 } )
            , ( Colors.green, { x = 100, y = 116 } )
            , ( Colors.green, { x = 100, y = 117 } )
            , ( Colors.green, { x = 100, y = 118 } )
            , ( Colors.green, { x = 100, y = 119 } )
            , ( Colors.green, { x = 100, y = 120 } )
            , ( Colors.green, { x = 100, y = 121 } )
            , ( Colors.green, { x = 100, y = 122 } )
            , ( Colors.green, { x = 100, y = 123 } )
            , ( Colors.green, { x = 100, y = 124 } )
            , ( Colors.green, { x = 100, y = 125 } )
            , ( Colors.green, { x = 100, y = 126 } )
            , ( Colors.green, { x = 100, y = 127 } )
            , ( Colors.green, { x = 100, y = 128 } )
            , ( Colors.green, { x = 100, y = 129 } )
            , ( Colors.green, { x = 100, y = 130 } )
            , ( Colors.green, { x = 100, y = 131 } )
            , ( Colors.green, { x = 100, y = 132 } )
            , ( Colors.green, { x = 100, y = 133 } )
            , ( Colors.green, { x = 100, y = 134 } )
            , ( Colors.green, { x = 100, y = 135 } )
            , ( Colors.green, { x = 100, y = 136 } )
            , ( Colors.green, { x = 100, y = 137 } )
            , ( Colors.green, { x = 100, y = 138 } )
            , ( Colors.green, { x = 100, y = 139 } )
            , ( Colors.green, { x = 100, y = 140 } )
            , ( Colors.green, { x = 100, y = 141 } )
            , ( Colors.green, { x = 100, y = 142 } )
            , ( Colors.green, { x = 100, y = 143 } )
            , ( Colors.green, { x = 100, y = 144 } )
            , ( Colors.green, { x = 100, y = 145 } )
            , ( Colors.green, { x = 100, y = 146 } )
            , ( Colors.green, { x = 100, y = 147 } )
            , ( Colors.green, { x = 100, y = 148 } )
            , ( Colors.green, { x = 100, y = 149 } )
            , ( Colors.green, { x = 100, y = 150 } )
            , ( Colors.green, { x = 100, y = 151 } )
            , ( Colors.green, { x = 100, y = 152 } )
            , ( Colors.green, { x = 100, y = 153 } )
            , ( Colors.green, { x = 100, y = 154 } )
            , ( Colors.green, { x = 100, y = 155 } )
            , ( Colors.green, { x = 100, y = 156 } )
            , ( Colors.green, { x = 100, y = 157 } )
            , ( Colors.green, { x = 100, y = 158 } )
            , ( Colors.green, { x = 100, y = 159 } )
            , ( Colors.green, { x = 100, y = 160 } )
            , ( Colors.green, { x = 100, y = 161 } )
            , ( Colors.green, { x = 100, y = 162 } )
            , ( Colors.green, { x = 100, y = 163 } )
            , ( Colors.green, { x = 100, y = 164 } )
            , ( Colors.green, { x = 100, y = 165 } )
            , ( Colors.green, { x = 100, y = 166 } )
            , ( Colors.green, { x = 100, y = 167 } )
            , ( Colors.green, { x = 100, y = 168 } )
            , ( Colors.green, { x = 100, y = 169 } )
            , ( Colors.green, { x = 100, y = 170 } )
            ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 170 } ) ]
        }
    , DoNothing
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 171 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 171 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 172 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 172 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 173 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 173 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 174 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 174 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 175 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 175 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 176 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 176 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 177 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 177 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 178 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 178 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 179 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 179 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 180 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 180 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 181 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 181 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 182 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 182 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 183 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 183 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 184 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 184 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 185 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 185 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 186 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 186 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 187 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 187 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 188 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 188 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 189 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 189 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 190 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 190 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 191 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 191 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 192 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 192 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 193 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 193 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 194 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 194 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 195 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 195 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 196 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 196 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 197 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 197 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 198 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 198 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 199 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 199 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 200 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 200 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 201 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 201 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 202 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 202 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 203 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 203 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 204 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 204 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 205 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 205 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 206 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 206 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 207 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 207 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 208 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 208 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 209 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 209 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 210 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 210 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 211 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 211 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 212 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 212 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 213 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 213 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 214 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 214 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 215 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 215 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 216 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 216 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 217 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 217 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 218 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 218 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 219 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 219 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 220 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 220 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 221 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 221 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 222 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 222 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 223 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 223 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 224 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 224 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 225 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 225 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 226 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 226 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 227 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 227 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 228 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 228 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 229 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 229 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 230 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 230 } ) ]
        }
    , ClearAndThenDraw
        { bodyDrawing =
            [ ( Colors.green, { x = 100, y = 100 } )
            , ( Colors.green, { x = 100, y = 101 } )
            , ( Colors.green, { x = 100, y = 102 } )
            , ( Colors.green, { x = 100, y = 103 } )
            , ( Colors.green, { x = 100, y = 104 } )
            , ( Colors.green, { x = 100, y = 105 } )
            , ( Colors.green, { x = 100, y = 106 } )
            , ( Colors.green, { x = 100, y = 107 } )
            , ( Colors.green, { x = 100, y = 108 } )
            , ( Colors.green, { x = 100, y = 109 } )
            , ( Colors.green, { x = 100, y = 110 } )
            , ( Colors.green, { x = 100, y = 111 } )
            , ( Colors.green, { x = 100, y = 112 } )
            , ( Colors.green, { x = 100, y = 113 } )
            , ( Colors.green, { x = 100, y = 114 } )
            , ( Colors.green, { x = 100, y = 115 } )
            , ( Colors.green, { x = 100, y = 116 } )
            , ( Colors.green, { x = 100, y = 117 } )
            , ( Colors.green, { x = 100, y = 118 } )
            , ( Colors.green, { x = 100, y = 119 } )
            , ( Colors.green, { x = 100, y = 120 } )
            , ( Colors.green, { x = 100, y = 121 } )
            , ( Colors.green, { x = 100, y = 122 } )
            , ( Colors.green, { x = 100, y = 123 } )
            , ( Colors.green, { x = 100, y = 124 } )
            , ( Colors.green, { x = 100, y = 125 } )
            , ( Colors.green, { x = 100, y = 126 } )
            , ( Colors.green, { x = 100, y = 127 } )
            , ( Colors.green, { x = 100, y = 128 } )
            , ( Colors.green, { x = 100, y = 129 } )
            , ( Colors.green, { x = 100, y = 130 } )
            , ( Colors.green, { x = 100, y = 131 } )
            , ( Colors.green, { x = 100, y = 132 } )
            , ( Colors.green, { x = 100, y = 133 } )
            , ( Colors.green, { x = 100, y = 134 } )
            , ( Colors.green, { x = 100, y = 135 } )
            , ( Colors.green, { x = 100, y = 136 } )
            , ( Colors.green, { x = 100, y = 137 } )
            , ( Colors.green, { x = 100, y = 138 } )
            , ( Colors.green, { x = 100, y = 139 } )
            , ( Colors.green, { x = 100, y = 140 } )
            , ( Colors.green, { x = 100, y = 141 } )
            , ( Colors.green, { x = 100, y = 142 } )
            , ( Colors.green, { x = 100, y = 143 } )
            , ( Colors.green, { x = 100, y = 144 } )
            , ( Colors.green, { x = 100, y = 145 } )
            , ( Colors.green, { x = 100, y = 146 } )
            , ( Colors.green, { x = 100, y = 147 } )
            , ( Colors.green, { x = 100, y = 148 } )
            , ( Colors.green, { x = 100, y = 149 } )
            , ( Colors.green, { x = 100, y = 150 } )
            , ( Colors.green, { x = 100, y = 151 } )
            , ( Colors.green, { x = 100, y = 152 } )
            , ( Colors.green, { x = 100, y = 153 } )
            , ( Colors.green, { x = 100, y = 154 } )
            , ( Colors.green, { x = 100, y = 155 } )
            , ( Colors.green, { x = 100, y = 156 } )
            , ( Colors.green, { x = 100, y = 157 } )
            , ( Colors.green, { x = 100, y = 158 } )
            , ( Colors.green, { x = 100, y = 159 } )
            , ( Colors.green, { x = 100, y = 160 } )
            , ( Colors.green, { x = 100, y = 161 } )
            , ( Colors.green, { x = 100, y = 162 } )
            , ( Colors.green, { x = 100, y = 163 } )
            , ( Colors.green, { x = 100, y = 164 } )
            , ( Colors.green, { x = 100, y = 165 } )
            , ( Colors.green, { x = 100, y = 166 } )
            , ( Colors.green, { x = 100, y = 167 } )
            , ( Colors.green, { x = 100, y = 168 } )
            , ( Colors.green, { x = 100, y = 169 } )
            , ( Colors.green, { x = 100, y = 170 } )
            ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 170 } ) ]
        }
    , DoNothing
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 171 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 171 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 172 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 172 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 173 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 173 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 174 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 174 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 175 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 175 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 176 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 176 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 177 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 177 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 178 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 178 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 179 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 179 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 180 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 180 } ) ]
        }
    , ClearAndThenDraw
        { bodyDrawing =
            [ ( Colors.green, { x = 100, y = 100 } )
            , ( Colors.green, { x = 100, y = 101 } )
            , ( Colors.green, { x = 100, y = 102 } )
            , ( Colors.green, { x = 100, y = 103 } )
            , ( Colors.green, { x = 100, y = 104 } )
            , ( Colors.green, { x = 100, y = 105 } )
            , ( Colors.green, { x = 100, y = 106 } )
            , ( Colors.green, { x = 100, y = 107 } )
            , ( Colors.green, { x = 100, y = 108 } )
            , ( Colors.green, { x = 100, y = 109 } )
            , ( Colors.green, { x = 100, y = 110 } )
            , ( Colors.green, { x = 100, y = 111 } )
            , ( Colors.green, { x = 100, y = 112 } )
            , ( Colors.green, { x = 100, y = 113 } )
            , ( Colors.green, { x = 100, y = 114 } )
            , ( Colors.green, { x = 100, y = 115 } )
            , ( Colors.green, { x = 100, y = 116 } )
            , ( Colors.green, { x = 100, y = 117 } )
            , ( Colors.green, { x = 100, y = 118 } )
            , ( Colors.green, { x = 100, y = 119 } )
            ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 119 } ) ]
        }
    , DoNothing
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 120 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 120 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 121 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 121 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 122 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 122 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 123 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 123 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 124 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 124 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 125 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 125 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 126 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 126 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 127 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 127 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 128 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 128 } ) ]
        }
    , DrawSomething
        { bodyDrawing = [ ( Colors.green, { x = 100, y = 129 } ) ]
        , headDrawing = [ ( Colors.green, { x = 100, y = 129 } ) ]
        }
    ]


frameDeltaInMs : FrameTime
frameDeltaInMs =
    1000 / toFloat refreshRate


refreshRate : Int
refreshRate =
    60
