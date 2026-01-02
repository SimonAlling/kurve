module TestHelpers.ListLength exposing
    ( expectAtLeast
    , expectExactly
    )

import Expect


type LengthCriterion
    = Exactly Int
    | AtLeast Int


expectExactly : Int -> String -> List a -> Expect.Expectation
expectExactly =
    Exactly >> expectLength


expectAtLeast : Int -> String -> List a -> Expect.Expectation
expectAtLeast =
    AtLeast >> expectLength


expectLength : LengthCriterion -> String -> List a -> Expect.Expectation
expectLength criterion descriptionOfItems xs =
    let
        actualLength : Int
        actualLength =
            List.length xs

        ( checkLength, expectationDescription ) =
            case criterion of
                Exactly n ->
                    ( Expect.equal n, "exactly " ++ String.fromInt n ++ " element" ++ pluralEnding n )

                AtLeast n ->
                    ( Expect.atLeast n, "at least " ++ String.fromInt n ++ " element" ++ pluralEnding n )

        pluralEnding : Int -> String
        pluralEnding n =
            if n == 1 then
                ""

            else
                "s"
    in
    actualLength
        |> checkLength
        |> Expect.onFail ("Expected list of " ++ descriptionOfItems ++ " to have " ++ expectationDescription ++ ", but it had " ++ String.fromInt actualLength ++ ".")
