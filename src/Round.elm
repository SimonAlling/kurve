module Round exposing (Kurves, Round, RoundHistory, RoundInitialState, initialStateForReplaying, modifyAlive, modifyDead, modifyKurves, roundIsOver)

import Random
import Set exposing (Set)
import Types.Kurve as Kurve exposing (Kurve)
import World exposing (Pixel)


type alias Round =
    { kurves : Kurves
    , occupiedPixels : Set Pixel
    , history : RoundHistory
    , seed : Random.Seed
    }


type alias Kurves =
    { alive : List Kurve
    , dead : List Kurve
    }


type alias RoundHistory =
    { initialState : RoundInitialState
    }


type alias RoundInitialState =
    { seedAfterSpawn : Random.Seed
    , spawnedKurves : List Kurve
    , pressedButtons : Set String
    }


modifyKurves : (Kurves -> Kurves) -> Round -> Round
modifyKurves f round =
    { round | kurves = f round.kurves }


modifyAlive : (List Kurve -> List Kurve) -> Kurves -> Kurves
modifyAlive f kurves =
    { kurves | alive = f kurves.alive }


modifyDead : (List Kurve -> List Kurve) -> Kurves -> Kurves
modifyDead f kurves =
    { kurves | dead = f kurves.dead }


roundIsOver : Kurves -> Bool
roundIsOver kurves =
    let
        someoneHasWonInMultiPlayer : Bool
        someoneHasWonInMultiPlayer =
            List.length kurves.alive == 1 && not (List.isEmpty kurves.dead)

        playerHasDiedInSinglePlayer : Bool
        playerHasDiedInSinglePlayer =
            List.isEmpty kurves.alive
    in
    someoneHasWonInMultiPlayer || playerHasDiedInSinglePlayer


initialStateForReplaying : Round -> RoundInitialState
initialStateForReplaying round =
    let
        initialState : RoundInitialState
        initialState =
            round.history.initialState

        theKurves : List Kurve
        theKurves =
            round.kurves.alive ++ round.kurves.dead
    in
    { initialState | spawnedKurves = theKurves |> List.map Kurve.reset |> sortKurves }


sortKurves : List Kurve -> List Kurve
sortKurves =
    List.sortBy .id
