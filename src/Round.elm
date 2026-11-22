module Round exposing
    ( FinishedRound(..)
    , Kurves
    , Round
    , RoundInitialState
    , initScores
    , initialStateForReplaying
    , mapAliveKurves
    , roundIsOver
    , unpackFinished
    , updateScores
    )

import Dict exposing (Dict)
import Random
import Types.Kurve as Kurve exposing (Kurve)
import Types.PlayerId exposing (PlayerId)
import Types.Score as Score exposing (Score(..))
import World exposing (OccupiedPixels)


type alias Round =
    { kurves : Kurves
    , roundScores : Dict PlayerId Score
    , occupiedPixels : OccupiedPixels
    , initialState : RoundInitialState
    }


type FinishedRound
    = Finished Round


unpackFinished : FinishedRound -> Round
unpackFinished (Finished round) =
    round


type alias Kurves =
    { alive : List Kurve
    , dead : List Kurve
    }


type alias RoundInitialState =
    { seedAfterSpawn : Random.Seed
    , spawnedKurves : List Kurve
    }


mapAliveKurves : (Kurve -> Kurve) -> Round -> Round
mapAliveKurves f ({ kurves } as round) =
    { round | kurves = { kurves | alive = List.map f kurves.alive } }


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


initialStateForReplaying : FinishedRound -> RoundInitialState
initialStateForReplaying (Finished round) =
    let
        initialState : RoundInitialState
        initialState =
            round.initialState

        theKurves : List Kurve
        theKurves =
            round.kurves.alive ++ round.kurves.dead
    in
    { initialState | spawnedKurves = theKurves |> List.map Kurve.reset |> sortKurves }


sortKurves : List Kurve -> List Kurve
sortKurves =
    List.sortBy .id


initScores : List Kurve -> Dict PlayerId Score
initScores spawnedKurves =
    List.foldl (\kurve scores -> Dict.insert kurve.id (Score 0) scores) Dict.empty spawnedKurves


updateScores : List Kurve -> Dict PlayerId Score -> Dict PlayerId Score
updateScores deadIncludingWhoJustDied roundScores =
    let
        deadIds : List PlayerId
        deadIds =
            List.map .id deadIncludingWhoJustDied

        awardPointIfStillAlive : PlayerId -> Score -> Score
        awardPointIfStillAlive id score =
            if List.member id deadIds then
                score

            else
                Score.increment score
    in
    roundScores |> Dict.map awardPointIfStillAlive
