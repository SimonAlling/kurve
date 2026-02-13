module IsGameOver exposing (isGameOver)

import Dict
import Players exposing (ParticipatingPlayers)
import Types.Score exposing (Score(..), isAtLeast)


isGameOver : ParticipatingPlayers () -> Bool
isGameOver participatingPlayers =
    let
        numberOfPlayers : Int
        numberOfPlayers =
            Dict.size participatingPlayers

        targetScore : Score
        targetScore =
            Score ((numberOfPlayers - 1) * 10)

        someoneHasReachedTargetScore : Bool
        someoneHasReachedTargetScore =
            not <|
                Dict.isEmpty <|
                    Dict.filter (always (tripleSecond >> isAtLeast targetScore)) participatingPlayers
    in
    numberOfPlayers > 1 && someoneHasReachedTargetScore


tripleSecond : ( a, b, c ) -> b
tripleSecond ( _, b, _ ) =
    b
