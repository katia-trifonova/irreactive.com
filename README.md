# Irreactive

## Structure

* `content/` contains markdown files that describe blog posts
* `images/` contains media that gets optimized by `elm-pages`, including images for the blog posts
* `src/` contains the source code of the html-generator for the webpage (what turns the markdown files to html)
* `gen/` contains generated source files from `elm-pages`
* `elm-markdown/` is my fork of `elm-markdown`, so I can depend on my own bugfixes for it.






# elm-pages-starter

[![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/dillonkearns/elm-pages-starter)

This is an example repo to get you up and running with `elm-pages`.

The entrypoint file is `index.js`. That file imports `src/Main.elm`. The `content` folder is turned into your static pages. The rest is mostly determined by logic in the Elm code! Learn more with the resources below.

## Setup Instructions
Click "Use this template" on this Github page to fork the repo.

Or git clone it:

```
git clone git@github.com:dillonkearns/elm-pages-starter.git
```

Then install and run the dev server

```
cd elm-pages-starter
npm install
npm start # starts a local dev server using `elm-pages develop`
```

From there you can tweak the `content` folder or change the `src/Main.elm` file.


## Learn more about `elm-pages`

- Documentation site: https://elm-pages.com
- [Elm Package docs](https://package.elm-lang.org/packages/dillonkearns/elm-pages/latest/)
- [`elm-pages` blog](https://elm-pages.com/blog)
