module Round exposing (Kurves, Round, RoundInitialState, initialStateForReplaying, modifyAlive, modifyDead, modifyKurves, roundIsOver, scores)

import Dict exposing (Dict)
import Random
import Set exposing (Set)
import Types.Kurve as Kurve exposing (Kurve)
import Types.PlayerId exposing (PlayerId)
import Types.Score exposing (Score(..))
import World exposing (Pixel)


type alias Round =
    { kurves : Kurves
    , occupiedPixels : Set Pixel
    , initialState : RoundInitialState
    , seed : Random.Seed
    }


type alias Kurves =
    { alive : List Kurve
    , dead : List Kurve
    }


type alias RoundInitialState =
    { seedAfterSpawn : Random.Seed
    , spawnedKurves : List Kurve
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
            round.initialState

        theKurves : List Kurve
        theKurves =
            round.kurves.alive ++ round.kurves.dead
    in
    { initialState | spawnedKurves = theKurves |> List.map Kurve.reset |> sortKurves }


scores : Round -> Dict PlayerId Score
scores { kurves } =
    let
        scoresOfDead : List ( Score, Kurve )
        scoresOfDead =
            List.indexedMap (Score >> Tuple.pair) (List.reverse kurves.dead)

        scoresOfAlive : List ( Score, Kurve )
        scoresOfAlive =
            List.map (Tuple.pair (Score <| List.length kurves.dead)) kurves.alive
    in
    scoresOfDead ++ scoresOfAlive |> List.foldl (\( score, kurve ) -> Dict.insert kurve.id score) Dict.empty


sortKurves : List Kurve -> List Kurve
sortKurves =
    List.sortBy .id
