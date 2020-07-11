{- |
Module      :  ELynx.Data.Tree.SumStat
Description :  Summary statistics for phylogenetic trees
Copyright   :  (c) Dominik Schrempf 2018
License     :  GPL-3.0-or-later

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Thu May 17 14:05:45 2018.

TODO: Move this to the simulate command file? Somehow this does not belong in
the library.

-}

module ELynx.Data.Tree.SumStat
  ( BrLnNChildren
  , NChildSumStat
  , toNChildSumStat
  , formatNChildSumStat
  )
where

import qualified Data.ByteString.Builder       as L
import qualified Data.ByteString.Lazy.Char8    as L
import           Data.Tree
import           ELynx.Data.Tree.MeasurableTree

-- | Pair of branch length with number of extant children.
type BrLnNChildren = (BranchLength, Int)

-- | Possible summary statistic of phylogenetic trees. A list of tuples
-- (BranchLength, NumberOfExtantChildrenBelowThisBranch).
type NChildSumStat = [BrLnNChildren]

-- | Format the summary statistics in the following form:
-- @
--    nLeaves1 branchLength1
--    nLeaves2 branchLength2
--    ....
formatNChildSumStat :: NChildSumStat -> L.ByteString
formatNChildSumStat s =
  L.toLazyByteString . mconcat $ map formatNChildSumStatLine s

formatNChildSumStatLine :: BrLnNChildren -> L.Builder
formatNChildSumStatLine (l, n) =
  L.intDec n <> L.char8 ' ' <> L.doubleDec l <> L.char8 '\n'

-- | Compute NChilSumStat for a phylogenetic tree.
toNChildSumStat :: Measurable a => Tree a -> NChildSumStat
toNChildSumStat (Node lbl []) = [(getLen lbl, 1)]
toNChildSumStat (Node lbl ts) = (getLen lbl, sumCh) : concat nChSS
 where
  nChSS = map toNChildSumStat ts
  sumCh = sum $ map (snd . head) nChSS
