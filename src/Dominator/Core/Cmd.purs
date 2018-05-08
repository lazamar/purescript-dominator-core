module Dominator.Core.Cmd where

import Prelude

import Control.Monad.Cont.Trans (ContT(ContT))
import Control.Monad.Eff (Eff, kind Effect)
import Control.Monad.Eff.Exception (Error)
import Control.Monad.Aff (Aff, runAff_)

import Data.Either (Either(Right, Left))

--| A Cmd represents an asynchronous task to be executed.
--| 
--| The result of a Cmd will be sent to the update function
--| so you can use it to modify your model.
type Cmd eff b = ContT Unit (Eff eff) b

--| Dominator's update function should return an Array of Cmd. 
--| `Cmds` serve as a shorthand for that.
type Cmds eff b = Array (Cmd eff b)

--| Use `makeCmd` to use your effectful foreign function as a Cmd. 
makeCmd :: ∀ a eff. ((a -> Eff eff Unit) -> Eff eff Unit) -> Cmd eff a
makeCmd = ContT

--| Transform an Aff directly into a Cmd. Because Aff may fail, you need
--| to handle the possibility of Error.
fromAff :: ∀ eff a. Aff eff a -> Cmd eff (Either Error a)
fromAff aff = makeCmd $ flip runAff_ $ aff 

--| Transform an Aff into a Cmd handling success and error in separate
--| functions.
runAff :: ∀ eff a msg. (Error -> msg) -> (a -> msg) -> Aff eff a -> Cmd eff msg
runAff onError onSuccess aff = do
	e <- fromAff aff
	case e of
		Right v -> pure $ onSuccess v
		Left v -> pure $ onError v