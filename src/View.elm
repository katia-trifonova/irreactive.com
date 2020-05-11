module View exposing (..)

import Date
import Html exposing (..)
import Html.Attributes exposing (attribute, class, disabled, for, height, href, id, method, name, placeholder, required, src, style, type_, value, width)
import Html.Events as Events
import Metadata exposing (Metadata)
import Pages exposing (images, pages)
import Pages.ImagePath as ImagePath
import Pages.PagePath as PagePath exposing (PagePath)


body : List (Attribute msg) -> List (Html msg) -> Html msg
body attributes children =
    div
        (class "flex flex-col min-h-screen text-base bg-gruv-gray-12" :: attributes)
        children


middle : List (Html msg) -> Html msg
middle children =
    main_ [ class "flex flex-col flex-grow h-full px-5" ]
        children



-- HEADER


header : PagePath Pages.PathKey -> Html msg
header currentPath =
    nav [ class "flex flex-row w-full bg-gruv-gray-12" ]
        [ a
            [ class "flex flex-col"
            , href (PagePath.toString pages.index)
            ]
            [ span
                [ classes
                    [ "font-title font-semibold text-3xl text-gruv-orange-d"
                    , "px-3 mx-auto"
                    ]
                ]
                [ text "Irreactive" ]
            , div [ class "h-1 mr-1 bg-gruv-gray-10" ] []
            ]
        , a
            [ class "flex-grow flex flex-col"
            , href (PagePath.toString pages.index)
            ]
            [ span
                [ class "font-body italic text-base m-auto text-gruv-gray-4" ]
                [ text "Posts" ]
            , div
                [ classes
                    [ "h-1 mx-1"
                    , if currentPath == pages.index then
                        "bg-gruv-orange-m"

                      else
                        "bg-gruv-gray-10"
                    ]
                ]
                []
            ]
        , a
            [ class "flex-grow flex flex-col"
            , href (PagePath.toString pages.about)
            ]
            [ span
                [ class "font-body italic text-base m-auto text-gruv-gray-4" ]
                [ text "About" ]
            , div
                [ classes
                    [ "h-1 ml-1"
                    , if currentPath == pages.about then
                        "bg-gruv-orange-m"

                      else
                        "bg-gruv-gray-10"
                    ]
                ]
                []
            ]
        ]



-- ARTICLE LIST


articleList : List (Attribute msg) -> List (Html msg) -> Html msg
articleList attributes children =
    ul (class "flex flex-col mb-12 container desktop:mx-auto" :: attributes) children


postPreview : ( PagePath Pages.PathKey, Metadata.ArticleMetadata ) -> Html msg
postPreview ( postPath, post ) =
    li [ class "w-full mx-auto mt-12" ]
        [ articleMetadata post
        , h2 [ class "font-title text-4xl text-gruv-gray-4 text-center leading-tight" ]
            [ a [ href (PagePath.toString postPath) ]
                [ text post.title ]
            ]
        , p [ class "text-gruv-gray-4 text-justify mt-2" ]
            [ a [ href (PagePath.toString postPath) ]
                [ text post.description ]
            ]
        , p [ class "font-title text-xl text-gruv-blue-d block text-center mt-2" ]
            [ a
                [ href (PagePath.toString postPath)
                , class "visited:text-gruv-purple-d"
                ]
                [ text "Read More ..." ]
            ]
        , hr [ style "height" "2px", class "max-w-xs bg-gruv-gray-9 mx-auto mt-12" ] []
        ]


articleMetadata : Metadata.ArticleMetadata -> Html msg
articleMetadata { published } =
    time [ class "text-gruv-gray-4 italic text-base-sm text-center block" ]
        [ text (Date.format "MMMM ddd, yyyy" published) ]



-- FOOTER


blogFooter :
    { onSubmit : msg
    , onInput : String -> msg
    , model : String
    , errorText : String
    , submitSuccess : Bool
    }
    -> Html msg
blogFooter { onSubmit, onInput, model, errorText, submitSuccess } =
    footer [ class "flex flex-col bg-gruv-gray-0 p-5" ]
        [ form
            [ name "email-subscription"
            , method "POST"
            , attribute "data-netlify" "true"
            , Events.onSubmit onSubmit
            , class "container desktop:mx-auto"
            ]
            [ p []
                [ label [ for "email", class "font-code text-gruv-gray-11" ]
                    [ text "Get an "
                    , span [ class "text-gruv-orange-l" ] [ text "E-Mail" ]
                    , text " for every new Post:"
                    ]
                ]
            , p [ class "flex flex-row mt-2" ]
                [ input
                    [ classes
                        [ "bg-gruv-gray-3"
                        , "border-2 border-r-0 border-gruv-gray-5 rounded-l-md"
                        , "font-code text-gruv-gray-11"
                        , "flex-shrink flex-grow min-w-0 py-auto py-1 px-2"
                        , "focus:border-gruv-gray-7"
                        ]
                    , style "transform" "translate(0, -4px)"
                    , style "box-shadow" "0 4px 0 0 rgba(102,92,84,1)"
                    , id "email"
                    , type_ "email"
                    , name "email"
                    , placeholder "your e-mail"
                    , Events.onInput onInput
                    , value model
                    ]
                    []
                , button
                    [ classes [ "call-to-action inline flex-shrink-0 px-4 py-2 font-semibold tracking-widest" ]
                    , type_ "submit"
                    ]
                    [ text "Get Notified" ]
                ]
            , p
                [ classes
                    [ "font-code text-gruv-yellow-l mt-2"
                    , when (String.isEmpty errorText) "hidden"
                    ]
                ]
                [ text errorText ]
            , p
                [ classes
                    [ "font-code mt-2"
                    , unless submitSuccess "hidden"
                    ]
                , style "color" "#49d27e"
                ]
                [ text "Thanks for subscribing!" ]
            ]
        ]



-- ABOUT ME


aboutMe : Html msg
aboutMe =
    article [ class "flex flex-col flex-grow h-full px-5 mb-12 desktop:mx-auto desktop:px-0 container" ]
        [ img
            [ src (ImagePath.toString images.me)
            , width 200
            , height 200
            , class "rounded-lg my-6 mx-auto"
            ]
            []
        , p [ class "text-gruv-gray-6" ]
            [ text "Hi, I’m Philipp." ]
        , p [ class "mt-4 text-gruv-gray-6" ]
            [ text "I’m passionate about user interfaces and functional programming" ]
        , p [ class "mt-4 text-gruv-gray-6" ]
            [ text "This blog is an attempt at sharing the research work I’m trying to create around graphics APIs, rethought from the bottom up in a purely functional way." ]
        , p [ class "mt-4 text-gruv-gray-6" ]
            [ text "If you would like to reach out to me, send me a (direct) message over twitter "
            , textLink "https://twitter.com/matheusdev23" "@matheusdev23"
            , text "."
            ]
        , p [ class "mt-4 text-gruv-gray-6" ]
            [ text "If you want to get notified about new blog posts, follow me on twitter or use the E-Mail form below." ]
        , p [ class "mt-4 text-gruv-gray-6" ]
            [ text "Wondering about the technology behind this blog? Read "
            , textLink (PagePath.toString pages.buildingABlogWithElmPages) "the release post"
            , text "!"
            ]
        ]



-- UTILITIES


textLink : String -> String -> Html msg
textLink destination content =
    a
        [ class "text-gruv-blue-d visited:text-gruv-purple-d"
        , href destination
        ]
        [ text content ]


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


when : Bool -> String -> String
when condition classNames =
    if condition then
        classNames

    else
        ""


unless : Bool -> String -> String
unless condition =
    when (not condition)
