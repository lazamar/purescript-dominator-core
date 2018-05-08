module Dominator.Core.VirtualDom 
  ( DOM
  , Node
  , Renderer, normalRenderer
  , text, node
  , Property, property, attribute, attributeNS
  , style
  , on, onWithOptions, Options, defaultOptions
  , lazy, lazy2, lazy3
  , keyedNode
  ) where

import Prelude

import Control.Monad.Except (runExcept)
import Control.Monad.Eff (kind Effect)

import Data.List (List, fromFoldable)
import Data.Tuple (Tuple)
import Data.Foreign (Foreign, F, MultipleErrors)
import Data.Either (Either)


-- Define DOM effect type
foreign import data DOM :: Effect

{-| A Renderer takes care of dom and virtual dom updates
-}
data Renderer = Renderer

foreign import normalRenderer :: Renderer

{-| An immutable chunk of data representing a DOM node.
  This can be HTML or SVG.
-}
data Node msg = Node

{-| This function is useful when nesting components with [the Dominator
Architecture](https://github.com/evancz/elm-architecture-tutorial/). It lets
you transform the messages produced by a subtree.

Say you have a node named `button` that produces `()` values when it is
clicked. To get your model updating properly, you will probably want to tag
this `()` value like this:

    type Msg = Click | ...

    update msg model =
      case msg of
        Click ->
          ...

    view model =
      map (\_ -> Click) button

So now all the events produced by `button` will be transformed to be of type
`Msg` so they can be handled by your update function!
-}
foreign import nodeMap :: ∀ a msg. (a -> msg) -> Node a -> Node msg
instance functorNode :: Functor Node where
  map = nodeMap 

type Html msg = Node msg

{-| Create a DOM node with a tag name, a list of HTML properties that can
include styles and event listeners, a list of CSS properties like `color`, and
a list of child nodes.

    import Json.Encode as Json

    hello : Node msg
    hello =
      node "div" [] [ text "Hello!" ]

    greeting : Node msg
    greeting =
      node "div"
        [ property "id" (Json.string "greeting") ]
        [ text "Hello!" ]
-}
foreign import node_ :: ∀ msg. String -> List (Property msg) -> List (Node msg) -> Node msg

node :: ∀ msg. String -> Array (Property msg) -> Array (Node msg) -> Node msg
node s p c =
  node_ s (fromFoldable p) (fromFoldable c)

{-| Just put plain text in the DOM. It will escape the string so that it appears
exactly as you specify.

    text "Hello World!"
-}

foreign import text :: ∀ msg. String -> Node msg


-- -- PROPERTIES


{-| When using HTML and JS, there are two ways to specify parts of a DOM node.

  1. Attributes &mdash; You can set things in HTML itself. So the `class`
     in `<div class="greeting"></div>` is called an *attribute*.

  2. Properties &mdash; You can also set things in JS. So the `className`
     in `div.className = 'greeting'` is called a *property*.

So the `class` attribute corresponds to the `className` property. At first
glance, perhaps this distinction is defensible, but it gets much crazier.
*There is not always a one-to-one mapping between attributes and properties!*
Yes, that is a true fact. Sometimes an attribute exists, but there is no
corresponding property. Sometimes changing an attribute does not change the
underlying property. For example, as of this writing, the `webkit-playsinline`
attribute can be used in HTML, but there is no corresponding property!
-}

data Property msg = Property

{-| Transform the messages produced by a `Property`.
-}
foreign import mapProperty :: ∀ a b. (a -> b) -> Property a -> Property b

instance functorProperty :: Functor Property where
  map = mapProperty

{-| Create arbitrary *properties*.

    import JavaScript.Encode as Json

    greeting : Html
    greeting =
        node "div" [ property "className" (Json.string "greeting") ] [
          text "Hello!"
        ]

Notice that you must give the *property* name, so we use `className` as it
would be in JavaScript, not `class` as it would appear in HTML.
-}
foreign import property :: ∀ msg. String -> Foreign -> Property msg


{-| Create arbitrary HTML *attributes*. Maps onto JavaScript’s `setAttribute`
function under the hood.

    greeting : Html
    greeting =
        node "div" [ attribute "class" "greeting" ] [
          text "Hello!"
        ]

Notice that you must give the *attribute* name, so we use `class` as it would
be in HTML, not `className` as it would appear in JS.
-}
foreign import attribute :: ∀ msg. String -> String -> Property msg


{-| Would you believe that there is another way to do this?! This corresponds
to JavaScript's `setAttributeNS` function under the hood. It is doing pretty
much the same thing as `attribute` but you are able to have "namespaced"
attributes. This is used in some SVG stuff at least.
-}
foreign import attributeNS :: ∀ msg. String -> String -> String -> Property msg




{-| Specify a list of styles.

    myStyle : Property msg
    myStyle =
      style
        [ ("backgroundColor", "red")
        , ("height", "90px")
        , ("width", "100%")
        ]

    greeting : Node msg
    greeting =
      node "div" [ myStyle ] [ text "Hello!" ]
-}
foreign import style :: ∀ msg. List (Tuple String String) -> Property msg

-- -- EVENTS

{- In PureScript a Json value is represented using the Foreign type.
  We define an alias named Decoder for any function that takes a 
  Foreign an transforms it into an F a.
-}
type Decoder a = Foreign -> F a

{-| Create a custom event listener.

    import Json.Decode as Json

    onClick : msg -> Property msg
    onClick msg =
      on "click" (Json.succeed msg)

You first specify the name of the event in the same format as with JavaScript’s
`addEventListener`. Next you give a JSON decoder, which lets you pull
information out of the event object. If the decoder succeeds, it will produce
a message and route it to your `update` function.
-}
on :: ∀ msg. String -> Decoder msg -> Property msg
on eventName decoder =
  onWithOptions eventName defaultOptions decoder


runDecoder :: ∀ msg. Decoder msg -> Foreign -> Either MultipleErrors msg
runDecoder dec val = runExcept $ dec val

{-| Same as `on` but you can set a few options.
-}

type FullDecoder a = Foreign -> Either MultipleErrors a

onWithOptions :: ∀ msg. String -> Options -> Decoder msg -> Property msg
onWithOptions s o d =
  onWithOptions_ s o (runDecoder d)

foreign import onWithOptions_ :: ∀ msg. String -> Options -> FullDecoder msg -> Property msg


{-| Options for an event listener. If `stopPropagation` is true, it means the
event stops traveling through the DOM so it will not trigger any other event
listeners. If `preventDefault` is true, any built-in browser behavior related
to the event is prevented. For example, this is used with touch events when you
want to treat them as gestures of your own, not as scrolls.
-}
type Options =
  { stopPropagation :: Boolean
  , preventDefault :: Boolean
  }


{-| Everything is `False` by default.

    defaultOptions =
        { stopPropagation = False
        , preventDefault = False
        }
-}
defaultOptions :: Options
defaultOptions =
  { stopPropagation : false
  , preventDefault : false
  }



-- -- OPTIMIZATION


{-| A performance optimization that delays the building of virtual DOM nodes.

Calling `(view model)` will definitely build some virtual DOM, perhaps a lot of
it. Calling `(lazy view model)` delays the call until later. During diffing, we
can check to see if `model` is referentially equal to the previous value used,
and if so, we just stop. No need to build up the tree structure and diff it,
we know if the input to `view` is the same, the output must be the same!
-}
foreign import lazy :: ∀ a msg. (a -> Node msg) -> a -> Node msg


{-| Same as `lazy` but checks on two arguments.
-}
foreign import lazy2 :: ∀ a b msg. (a -> b -> Node msg) -> a -> b -> Node msg


{-| Same as `lazy` but checks on three arguments.
-}
foreign import lazy3 :: ∀ a b c msg. (a -> b -> c -> Node msg) -> a -> b -> c -> Node msg


{-| Works just like `node`, but you add a unique identifier to each child
node. You want this when you have a list of nodes that is changing: adding
nodes, removing nodes, etc. In these cases, the unique identifiers help make
the DOM modifications more efficient.
-}
foreign import keyedNode_ :: ∀ msg. String -> List (Property msg) -> List ( Tuple String (Node msg) ) -> Node msg

keyedNode :: ∀ msg. String -> Array (Property msg) -> Array ( Tuple String (Node msg) ) -> Node msg
keyedNode s p n = 
  keyedNode_ s (fromFoldable p) (fromFoldable n)


