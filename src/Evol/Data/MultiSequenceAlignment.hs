{- |
Module      :  Evol.Data.MultiSequenceAlignment
Description :  Multi sequence alignment related types and functions.
Copyright   :  (c) Dominik Schrempf 2018
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Thu Oct  4 18:40:18 2018.

-}


module Evol.Data.MultiSequenceAlignment
  ( MultiSequenceAlignment (..)
  , showSummaryMSA
  , join
  ) where

import           Evol.Data.Alphabet
import           Evol.Data.Sequence

-- | A collection of names sequences with a specific length (i.e., the number of sites).
data MultiSequenceAlignment i a = MSA { msaSequences  :: [Sequence i a]
                                      , msaNSequences :: Int
                                      , msaLength     :: Int}

instance (Show i, Show a) => Show (MultiSequenceAlignment i a) where
  show MSA{msaSequences=xs} = unlines $ (showSequenceId "Name" ++ "Sequence") : map show xs

showSummaryMSA :: (Show i, Show a, Alphabet a) => MultiSequenceAlignment i a -> String
showSummaryMSA MSA{msaSequences=xs} = summarizeSequenceListHeader "List" xs ++ summarizeSequenceListBody xs

join :: MultiSequenceAlignment i a -> MultiSequenceAlignment i a -> Maybe (MultiSequenceAlignment i a)
join
  MSA{msaSequences=xs, msaNSequences=nex, msaLength=nix}
  MSA{msaSequences=ys, msaNSequences=ney, msaLength=niy}
  | nix == niy = Just $ MSA (xs ++ ys) (nex + ney) nix
  | otherwise  = Nothing
