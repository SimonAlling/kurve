module Round exposing (Players, Round, RoundHistory, RoundInitialState, initialStateForReplaying, modifyAlive, modifyDead, modifyPlayers, roundIsOver)

import Random
import Set exposing (Set)
import Types.Player as Player exposing (Player)
import World exposing (Pixel)


type alias Round =
    { players : Players
    , occupiedPixels : Set Pixel
    , history : RoundHistory
    , seed : Random.Seed
    }


type alias Players =
    { alive : List Player
    , dead : List Player
    }


type alias RoundHistory =
    { initialState : RoundInitialState
    }


type alias RoundInitialState =
    { seedAfterSpawn : Random.Seed
    , spawnedPlayers : List Player
    , pressedButtons : Set String
    }


modifyPlayers : (Players -> Players) -> Round -> Round
modifyPlayers f round =
    { round | players = f round.players }


modifyAlive : (List Player -> List Player) -> Players -> Players
modifyAlive f players =
    { players | alive = f players.alive }


modifyDead : (List Player -> List Player) -> Players -> Players
modifyDead f players =
    { players | dead = f players.dead }


roundIsOver : Players -> Bool
roundIsOver players =
    let
        someoneHasWonInMultiPlayer : Bool
        someoneHasWonInMultiPlayer =
            List.length players.alive == 1 && not (List.isEmpty players.dead)

        playerHasDiedInSinglePlayer : Bool
        playerHasDiedInSinglePlayer =
            List.isEmpty players.alive
    in
    someoneHasWonInMultiPlayer || playerHasDiedInSinglePlayer


initialStateForReplaying : Round -> RoundInitialState
initialStateForReplaying round =
    let
        initialState : RoundInitialState
        initialState =
            round.history.initialState

        thePlayers : List Player
        thePlayers =
            round.players.alive ++ round.players.dead
    in
    { initialState | spawnedPlayers = thePlayers |> List.map Player.reset |> sortPlayers }


sortPlayers : List Player -> List Player
sortPlayers =
    List.sortBy .id
