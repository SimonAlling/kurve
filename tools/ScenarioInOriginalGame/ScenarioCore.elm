module ScenarioCore exposing (Scenario, toModMem)

import MemoryLayout exposing (StateComponent(..), relativeAddressFor)
import ModMem exposing (ModMemCmd(..))
import OriginalGamePlayers exposing (PlayerId)
import ScenarioComments exposing (setStateComponentComment)


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
    [ setX x playerId
    , setY y playerId
    , setDirection direction playerId
    ]


setX : Float -> PlayerId -> ModMemCmd
setX x playerId =
    ModifyMemory
        (setStateComponentComment X playerId)
        (relativeAddressFor playerId X)
        x


setY : Float -> PlayerId -> ModMemCmd
setY y playerId =
    ModifyMemory
        (setStateComponentComment Y playerId)
        (relativeAddressFor playerId Y)
        y


setDirection : Float -> PlayerId -> ModMemCmd
setDirection direction playerId =
    ModifyMemory
        (setStateComponentComment Dir playerId)
        (relativeAddressFor playerId Dir)
        direction
