module ScenarioCore exposing (Scenario, toModMem)

import MemoryLayout exposing (PlayerProp(..), relativeAddressFor)
import ModMem exposing (ModMemCmd(..))
import OriginalGamePlayers exposing (PlayerId)


type alias Scenario =
    List ScenarioStep


type alias ScenarioStep =
    ( PlayerId, PlayerState )


type alias PlayerState =
    { x : Float, y : Float, direction : Float }


toModMem : Scenario -> List ModMemCmd
toModMem =
    List.concatMap stepToModMem


stepToModMem : ScenarioStep -> List ModMemCmd
stepToModMem ( playerId, { x, y, direction } ) =
    List.concat
        [ setX x playerId
        , setY y playerId
        , setDirection direction playerId
        ]


setX : Float -> PlayerId -> List ModMemCmd
setX x playerId =
    [ ModifyMemory
        (relativeAddressFor playerId X)
        x
    ]


setY : Float -> PlayerId -> List ModMemCmd
setY y playerId =
    [ ModifyMemory
        (relativeAddressFor playerId Y)
        y
    ]


setDirection : Float -> PlayerId -> List ModMemCmd
setDirection direction playerId =
    [ ModifyMemory
        (relativeAddressFor playerId Dir)
        direction
    ]
