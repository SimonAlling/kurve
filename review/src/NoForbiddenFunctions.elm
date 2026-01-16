module NoForbiddenFunctions exposing (rule)

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Error, Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "NoForbiddenFunctions" contextCreator
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


type alias Context =
    { lookupTable : ModuleNameLookupTable }


contextCreator : Rule.ContextCreator () Context
contextCreator =
    Rule.initContextCreator
        (\lookupTable () -> { lookupTable = lookupTable })
        |> Rule.withModuleNameLookupTable


forbiddenFunctions : List ( ModuleName, String, { message : String, details : List String } )
forbiddenFunctions =
    [ "red", "yellow", "orange", "green", "pink", "blue", "white" ]
        |> List.map
            (\color ->
                ( [ "Color" ]
                , color
                , { message = "Do not use `Color." ++ color ++ "` in this project"
                  , details =
                        [ "Use `Colors." ++ color ++ "` instead. (Note the “s” in “Colors”.)"
                        ]
                  }
                )
            )


expressionVisitor : Node Expression -> Context -> ( List (Error {}), Context )
expressionVisitor node context =
    case Node.value node of
        Expression.FunctionOrValue _ valueName ->
            let
                errors =
                    forbiddenFunctions
                        |> List.filterMap
                            (\( targetModuleName, targetValueName, errorRecord ) ->
                                if
                                    (valueName == targetValueName)
                                        && (ModuleNameLookupTable.moduleNameFor context.lookupTable node == Just targetModuleName)
                                then
                                    Just (Rule.error errorRecord (Node.range node))

                                else
                                    Nothing
                            )
            in
            ( errors, context )

        _ ->
            ( [], context )
