-- |
-- Module      :  Bench
-- Description :  Various benchmarks
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Mon Dec 16 13:33:27 2019.
module Main where

import Criterion.Main
import qualified Data.ByteString.Char8 as BS
import ELynx.Tools
import ELynx.Tree

treeFileMany :: FilePath
treeFileMany = "data/Many.trees"

getManyTrees :: IO (Forest Phylo BS.ByteString)
getManyTrees = parseFileWith (someNewick Standard) treeFileMany

main :: IO ()
main = do
  ts <- getManyTrees
  defaultMain
    [bgroup "bipartition" [bench "manyTrees" $ nf (map bipartitions) ts]]
