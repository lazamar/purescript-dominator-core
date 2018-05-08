module Dominator.Core.Platform 
	(HtmlRef
	, ProgramContainer(..)
	, program
	) where

import Prelude
import Dominator.Core.Scheduler (Scheduler, scheduler)
import Dominator.Core.VirtualDom (DOM, Node, Renderer, normalRenderer)
import Dominator.Core.Cmd (Cmds)

import Data.Maybe (Maybe(Just, Nothing))
import Data.Foreign (Foreign)
import Data.Tuple (Tuple)
import Control.Monad.Eff (Eff)

type HtmlRef = Foreign 

data ProgramContainer
  = FullScreen
  | EmbedWithin HtmlRef

foreign import program_ :: ∀ msg model eff. 
	Maybe HtmlRef
 	-> Scheduler 
	-> Renderer
	-> (Tuple model (Cmds (dom :: DOM | eff) msg)) 			
	-> (msg -> model -> Tuple model (Cmds (dom :: DOM | eff) msg))	
	-> (model -> Node msg) 											
	-> Eff (dom :: DOM | eff) Unit

program :: ∀ msg model eff. 
	ProgramContainer
	-> (Tuple model (Cmds (dom :: DOM | eff) msg)) 			
	-> (msg -> model -> Tuple model (Cmds (dom :: DOM | eff) msg))	
	-> (model -> Node msg) 											
	-> Eff (dom :: DOM | eff) Unit
program container = 
  let
    maybeContainer = case container of
      FullScreen -> Nothing
      EmbedWithin el -> Just el
  in
  	program_ maybeContainer scheduler normalRenderer