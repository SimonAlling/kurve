module Types.PlayerStatus exposing (PlayerStatus(..))

import Types.Score exposing (Score)


type PlayerStatus
    = Participating Score
    | NotParticipating
