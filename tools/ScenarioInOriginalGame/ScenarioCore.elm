module ScenarioCore exposing (Scenario, checkScenario, toModMem)

import MemoryLayout exposing (StateComponent(..), relativeAddressFor)
import ModMem exposing (ModMemCmd(..))
import OriginalGamePlayers exposing (PlayerId, allPlayers, playerIndex, playerName)
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


checkScenario : Scenario -> Result String Scenario
checkScenario scenario =
    let
        participatingCount : Int
        participatingCount =
            List.length scenario
    in
    if participatingCount < 2 then
        Err <| "Scenario must have at least 2 players, but had " ++ String.fromInt participatingCount ++ "."

    else
        let
            checkStep : ScenarioStep -> Result String Scenario -> Result String Scenario
            checkStep step checkedSoFar =
                case checkedSoFar of
                    Ok stepsSoFar ->
                        let
                            playerId : PlayerId
                            playerId =
                                Tuple.first step

                            seenPlayerIds : List PlayerId
                            seenPlayerIds =
                                List.map Tuple.first stepsSoFar
                        in
                        if List.member playerId seenPlayerIds then
                            Err <| playerName playerId ++ " specified more than once."

                        else if List.any (\seenPlayerId -> playerIndex seenPlayerId > playerIndex playerId) seenPlayerIds then
                            Err <| "Players must be specified in this order: " ++ (List.map playerName allPlayers |> String.join ", ") ++ "."

                        else
                            Ok (stepsSoFar ++ [ step ])

                    bad ->
                        bad
        in
        List.foldl checkStep (Ok []) scenario
