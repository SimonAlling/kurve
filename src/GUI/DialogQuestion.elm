module GUI.DialogQuestion exposing (DialogQuestion(..), showQuestion)


type DialogQuestion
    = ReallyQuit
    | ProceedToNextRound


showQuestion : DialogQuestion -> String
showQuestion question =
    case question of
        ReallyQuit ->
            "Really quit?"

        ProceedToNextRound ->
            "Next round?"
