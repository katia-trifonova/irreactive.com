module Main exposing (main)

import App exposing (..)
import Color
import Date
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Index
import MarkdownDocument
import Metadata exposing (Metadata)
import Pages exposing (images, pages)
import Pages.Directory as Directory exposing (Directory)
import Pages.ImagePath as ImagePath
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath as PagePath exposing (PagePath)
import Pages.Platform
import Pages.StaticHttp as StaticHttp
import Palette


manifest : Manifest.Config Pages.PathKey
manifest =
    { backgroundColor = Just Color.white
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = siteName ++ " - " ++ siteTagline
    , iarcRatingId = Nothing
    , name = siteName
    , themeColor = Just Color.white
    , startUrl = pages.index
    , shortName = Just siteName
    , sourceIcon = images.iconPng
    }


main : Pages.Platform.Program Model Msg Metadata (Model -> Html Msg)
main =
    Pages.Platform.application
        { init = \_ -> init
        , view =
            \siteMetadata page ->
                StaticHttp.succeed
                    { view = \model -> pageView model siteMetadata page
                    , head = head page.frontmatter
                    }
        , update = update
        , subscriptions = subscriptions
        , documents = [ MarkdownDocument.document ]
        , onPageChange = \_ -> NoOp
        , manifest = manifest
        , canonicalSiteUrl = canonicalSiteUrl
        , internals = Pages.internals
        , generateFiles = \_ -> []
        }


pageView :
    Model
    -> List ( PagePath Pages.PathKey, Metadata )
    -> { path : PagePath Pages.PathKey, frontmatter : Metadata }
    -> (Model -> Html Msg)
    -> { title : String, body : Html Msg }
pageView model siteMetadata page viewForPage =
    let
        renderGithubEditLink path =
            Html.section [ Attr.class "edit-on-github" ]
                [ Html.text "Found a typo? "
                , Html.a
                    [ Attr.style "text-decoration" "underline"
                    , Attr.style "color" Palette.color.primary
                    , Attr.href (githubRepo ++ "/edit/master/content" ++ PagePath.toString path ++ ".md")
                    ]
                    [ Html.text "Edit this page GitHub." ]
                ]
    in
    case page.frontmatter of
        Metadata.Page metadata ->
            { title = metadata.title
            , body =
                Html.div [ Attr.class "main-content" ]
                    [ header page.path
                    , viewForPage model
                    ]
            }

        Metadata.Article metadata ->
            { title = metadata.title
            , body =
                Html.div [ Attr.class "main-content" ]
                    [ header page.path
                    , Html.article []
                        [ Html.h1 [ Attr.class "post-title" ] [ Html.text metadata.title ]
                        , Html.section [ Attr.class "header" ]
                            [ Html.section [ Attr.class "meta" ]
                                [ Html.text metadata.author
                                , Html.text " • "
                                , Html.time [] [ Html.text (metadata.published |> Date.format "MMMM ddd, yyyy") ]
                                ]
                            , Html.img
                                [ Attr.src (ImagePath.toString metadata.image)
                                , Attr.alt "Post cover photo"
                                ]
                                []
                            ]
                        , viewForPage model
                        ]
                    , renderGithubEditLink page.path
                    , footer model
                    ]
            }

        Metadata.BlogIndex ->
            { title = siteName
            , body =
                Html.div [ Attr.class "main-content" ]
                    [ header page.path
                    , Index.view siteMetadata
                    , footer model
                    ]
            }


header : PagePath Pages.PathKey -> Html msg
header currentPath =
    Html.nav []
        [ Html.a [ Attr.href "/", Attr.class "blog-title" ]
            [ Html.text siteName
            ]
        , navigationLink currentPath
            pages.blog.directory
            "All Posts"
            [ Attr.class "all-posts" ]
        ]


footer : Model -> Html Msg
footer model =
    Html.footer []
        [ Html.form
            [ Attr.name "email-subscription"
            , Attr.method "POST"
            , Attr.attribute "data-netlify" "true"
            , Events.onSubmit SubmitEmailSubscription
            ]
            [ Html.p []
                [ Html.label [ Attr.for "email" ]
                    [ Html.text "Get an E-Mail for every new Post:" ]
                ]
            , Html.p [ Attr.class "inputs" ]
                [ Html.input
                    [ Attr.type_ "email"
                    , Attr.name "email"
                    , Attr.placeholder "your email address"
                    , Events.onInput SubscribeEmailAddressChange
                    , Attr.value model.subscriptionEmail
                    ]
                    []
                , Html.button [ Attr.type_ "submit" ] [ Html.text "Get Notified" ]
                ]
            ]
        ]


navigationLink :
    PagePath Pages.PathKey
    -> Directory Pages.PathKey Directory.WithIndex
    -> String
    -> List (Html.Attribute msg)
    -> Html msg
navigationLink currentPath linkDirectory displayName attributes =
    let
        isLinkToCurrentPage =
            currentPath |> Directory.includes linkDirectory
    in
    Html.a
        (Attr.href (linkDirectory |> Directory.indexPath |> PagePath.toString)
            :: (if isLinkToCurrentPage then
                    attributes

                else
                    Attr.style "text-decoration" "underline"
                        :: Attr.style "color" Palette.color.primary
                        :: attributes
               )
        )
        [ Html.text displayName ]


{-| <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
<https://htmlhead.dev>
<https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
<https://ogp.me/>
-}
head : Metadata -> List (Head.Tag Pages.PathKey)
head metadata =
    case metadata of
        Metadata.Page meta ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = images.iconPng
                    , alt = siteName ++ " logo"
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = siteTagline
                , locale = Nothing
                , title = meta.title
                }
                |> Seo.website

        Metadata.Article meta ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = meta.image
                    , alt = meta.description
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = meta.description
                , locale = Nothing
                , title = meta.title
                }
                |> Seo.article
                    { tags = []
                    , section = Nothing
                    , publishedTime = Just (Date.toIsoString meta.published)
                    , modifiedTime = Nothing
                    , expirationTime = Nothing
                    }

        Metadata.BlogIndex ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = images.iconPng
                    , alt = siteName ++ " logo"
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = siteTagline
                , locale = Nothing
                , title = siteName ++ " - all posts"
                }
                |> Seo.website


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://TODO.netlify.com/"


githubRepo : String
githubRepo =
    "https://github.com/matheus23/website"



{- I don't think I need this
   githubRepoLink : Html msg
   githubRepoLink =
       Html.a
           [ Attr.href githubRepo ]
           [ Html.img
               [ Attr.src (ImagePath.toString Pages.images.github)
               , Attr.style "width" "22px"
               , Attr.alt "GitHub repository"
               ]
               []
           ]
-}
