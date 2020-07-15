module Components.CodeInteractiveElm exposing (..)

import Html exposing (..)
import Html.Attributes exposing (attribute, class)
import Html.Events as Events
import Json.Decode as Decode
import Language.Common as Common
import Language.InteractiveElm exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Result.Extra as Result
import Svg exposing (Svg, svg)
import TypedSvg.Attributes as SvgA
import TypedSvg.Attributes.InPx as SvgPx
import TypedSvg.Core as Svg
import TypedSvg.Types as Svg


type alias Model =
    { expression : Expression }


type Msg
    = ToggleExpression (List Int)


interpret : Expression -> Svg msg
interpret =
    cata interpretAlg


interpretAlg : ExpressionF (Svg msg) -> Svg msg
interpretAlg expression =
    case expression of
        Superimposed active _ _ expressions _ ->
            if active then
                expressions.elements
                    |> List.map .expression
                    |> List.reverse
                    |> Svg.g []

            else
                Svg.g [] []

        Moved active _ _ x _ y _ e _ ->
            if active then
                Svg.g
                    [ SvgA.transform [ Svg.Translate (toFloat x) (toFloat y) ] ]
                    [ e ]

            else
                e

        Filled active _ _ color _ e _ ->
            Svg.g [ SvgA.fill (Svg.Paint (Common.colorToRGB color)) ]
                [ e ]

        Outlined active _ _ color _ e _ ->
            Svg.g
                [ SvgA.stroke (Svg.Paint (Common.colorToRGB color))
                , SvgPx.strokeWidth 8
                , SvgA.fill Svg.PaintNone
                ]
                [ e ]

        Circle active _ _ r _ ->
            if active then
                Svg.circle
                    [ SvgPx.r (toFloat r) ]
                    []

            else
                Svg.g [] []

        Rectangle active _ _ wInt _ hInt _ ->
            if active then
                let
                    w =
                        toFloat wInt

                    h =
                        toFloat hInt
                in
                Svg.rect
                    [ SvgPx.width w
                    , SvgPx.height h
                    , SvgPx.x (-w / 2)
                    , SvgPx.y (-h / 2)
                    , SvgA.transform [ Svg.Translate (w / 2) (h / 2) ]
                    ]
                    []

            else
                Svg.g [] []


type Type
    = Stencil
    | Picture


type Context
    = Top
    | InCallTo String Context


type alias TypeError =
    { expectedType : Type
    , actualType : Type
    , context : Context
    }


typeCheck : Expression -> List TypeError
typeCheck expression =
    cata typeCheckAlg expression Top Picture


typeCheckAlg : ExpressionF (Context -> Type -> List TypeError) -> Context -> Type -> List TypeError
typeCheckAlg constructor context expectedType =
    let
        checkType typeOfThis =
            if typeOfThis /= expectedType then
                [ { expectedType = expectedType
                  , actualType = typeOfThis
                  , context = context
                  }
                ]

            else
                []
    in
    case constructor of
        Superimposed active _ _ expressionList _ ->
            if active then
                List.concatMap
                    (\expectType ->
                        expectType
                            (InCallTo "list argument"
                                (InCallTo "superimposed" context)
                            )
                            expectedType
                    )
                    (expressionListToList expressionList)
                    ++ checkType Picture

            else
                []

        Moved active _ _ x _ y _ e _ ->
            if active then
                e (InCallTo "moved" context) Picture
                    ++ checkType Picture

            else
                e context expectedType

        Filled active _ _ col _ shape _ ->
            if active then
                shape (InCallTo "filled" context) Stencil
                    ++ checkType Picture

            else
                shape context expectedType

        Outlined active _ _ col _ shape _ ->
            if active then
                shape (InCallTo "outlined" context) Stencil
                    ++ checkType Picture

            else
                shape context expectedType

        Circle _ _ _ r _ ->
            checkType Stencil

        Rectangle _ _ _ w _ h _ ->
            checkType Stencil



-- INIT


init : String -> Result String Model
init code =
    code
        |> parse
        |> Result.map
            (\result -> { expression = result })



-- UPDATE


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleExpression path ->
            { model
                | expression =
                    indexedCata (toggleExpression path) [] model.expression
            }


toggleExpression : List Int -> List Int -> ExpressionF Expression -> Expression
toggleExpression togglePath currentPath constructor =
    let
        toggleActive active =
            xor active (togglePath == currentPath)
    in
    Expression (mapActive toggleActive constructor)



-- VIEW


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


view : Model -> Html Msg
view model =
    div [ class "mt-4" ]
        [ div [ class "bg-gruv-gray-10 relative" ]
            (case typeCheck model.expression of
                [] ->
                    [ svg
                        [ SvgA.width (Svg.Percent 100)
                        , SvgA.viewBox 0 0 500 200
                        ]
                        [ interpret model.expression ]
                    ]

                errors ->
                    [ svg
                        [ SvgA.width (Svg.Percent 100)
                        , SvgA.viewBox 0 0 500 200
                        ]
                        []
                    , div
                        [ classes
                            [ "absolute w-full h-full top-0"
                            , "bg-gruv-gray-0 opacity-50"
                            , "text-gruv-gray-12 font-code"
                            , "p-4 whitespace-pre"
                            ]
                        ]
                        (let
                            contextDescription context =
                                case context of
                                    Top ->
                                        "at the top level of the expression"

                                    InCallTo sth _ ->
                                        "in a " ++ sth

                            typeToString typ =
                                case typ of
                                    Picture ->
                                        "Picture"

                                    Stencil ->
                                        "Stencil"

                            renderError { expectedType, actualType, context } =
                                [ text "Expected type: "
                                , text (typeToString expectedType)
                                , text "\n"
                                , text "  Actual type: "
                                , text (typeToString actualType)
                                , text "\n"
                                , text (contextDescription context)
                                , text "\n\n"
                                ]
                         in
                         text "The code has a type error:\n"
                            :: List.concatMap renderError errors
                        )
                    ]
            )
        , pre
            [ classes
                [ "py-6 px-8"
                , "overflow-y-auto"
                , "select-none"
                , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
                ]
            ]
            [ code []
                (viewExpression model.expression)
            ]
        ]


reverseExpressionList : ExpressionList a -> ExpressionList a
reverseExpressionList list =
    let
        prefixes =
            List.map .prefix list.elements

        expressions =
            List.map .expression list.elements
    in
    { list
        | elements = List.map2 ListElement prefixes (List.reverse expressions)
    }


viewExpression : Expression -> List (Html Msg)
viewExpression expression =
    indexedCata viewExpressionAlg [] expression True


viewExpressionAlg : List Int -> ExpressionF (Bool -> List (Html Msg)) -> Bool -> List (Html Msg)
viewExpressionAlg path expression parentActive =
    case expression of
        Superimposed active t0 t1 list t2 ->
            List.concat
                [ [ viewOther (active && parentActive) t0
                  , viewFunctionName path (active && parentActive) "superimposed"
                  , text t1
                  ]
                , list
                    -- |> reverseExpressionList
                    |> viewExpressionList (active && parentActive)
                , [ viewOther (active && parentActive) t2 ]
                ]

        Moved active t0 t1 x t2 y t3 e t4 ->
            List.concat
                [ [ viewOther (active && parentActive) t0
                  , viewFunctionName path (active && parentActive) "moved"
                  , text t1
                  , viewIntLiteral (active && parentActive) x
                  , text t2
                  , viewIntLiteral (active && parentActive) y
                  , text t3
                  ]
                , e parentActive
                , [ viewOther (active && parentActive) t4 ]
                ]

        Filled active t0 t1 col t2 shape t3 ->
            List.concat
                [ [ viewOther (active && parentActive) t0
                  , viewFunctionName path (active && parentActive) "filled"
                  , text t1
                  , viewColorLiteral (active && parentActive) col
                  , text t2
                  ]
                , shape parentActive
                , [ viewOther (active && parentActive) t3 ]
                ]

        Outlined active t0 t1 col t2 shape t3 ->
            List.concat
                [ [ viewOther (active && parentActive) t0
                  , viewFunctionName path (active && parentActive) "outlined"
                  , text t1
                  , viewColorLiteral (active && parentActive) col
                  , text t2
                  ]
                , shape parentActive
                , [ viewOther (active && parentActive) t3 ]
                ]

        Circle active t0 t1 r t2 ->
            if active then
                [ viewOther parentActive t0
                , viewFunctionName path parentActive "circle"
                , text t1
                , viewIntLiteral parentActive r
                , viewOther parentActive t2
                ]

            else
                [ viewFunctionName path parentActive "emptyStencil" ]

        Rectangle active t0 t1 w t2 h t3 ->
            if active then
                [ viewOther parentActive t0
                , viewFunctionName path parentActive "rectangle"
                , text t1
                , viewIntLiteral parentActive w
                , text t2
                , viewIntLiteral parentActive h
                , viewOther parentActive t3
                ]

            else
                [ viewFunctionName path parentActive "emptyStencil" ]


viewFunctionName : List Int -> Bool -> String -> Html Msg
viewFunctionName path active name =
    span
        [ if active then
            class "hover:bg-gruv-gray-3 cursor-pointer"

          else
            class "hover:bg-gruv-gray-3 cursor-pointer text-gruv-gray-6"
        , Events.onClick (ToggleExpression path)
        ]
        [ text name ]


viewOther : Bool -> String -> Html msg
viewOther active content =
    span
        (if active then
            []

         else
            [ class "text-gruv-gray-6" ]
        )
        [ text content ]


viewIntLiteral : Bool -> Int -> Html Msg
viewIntLiteral active i =
    span
        (if active then
            [ class "text-gruv-blue-l" ]

         else
            [ class "text-gruv-gray-6" ]
        )
        [ text (String.fromInt i) ]


viewColorLiteral : Bool -> Common.Color -> Html Msg
viewColorLiteral active col =
    span
        (if active then
            [ class "text-gruv-green-l" ]

         else
            [ class "text-gruv-gray-6" ]
        )
        [ text ("\"" ++ Common.colorName col ++ "\"") ]


viewExpressionList : Bool -> ExpressionList (Bool -> List (Html Msg)) -> List (Html Msg)
viewExpressionList active { elements, tail } =
    List.concatMap (viewListItem active) elements
        ++ [ viewOther active tail ]


viewListItem : Bool -> { prefix : String, expression : Bool -> List (Html Msg) } -> List (Html Msg)
viewListItem active { prefix, expression } =
    viewOther active prefix :: expression active
