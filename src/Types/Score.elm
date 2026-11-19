module Types.Score exposing
    ( Score(..)
    , increment
    , isAtLeast
    )


type Score
    = Score Int


isAtLeast : Score -> Score -> Bool
isAtLeast (Score threshold) (Score s) =
    s >= threshold


increment : Score -> Score
increment (Score s) =
    Score (s + 1)
