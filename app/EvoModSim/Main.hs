{- |
Module      :  Main
Description :  Simulate multiple sequence alignments
Copyright   :  (c) Dominik Schrempf 2019
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

TODO: Rate heterogeneity with Gamma distribution.

Creation date: Mon Jan 28 14:12:52 2019.

-}

module Main where

import           Control.Monad
import           Control.Monad.Primitive
import qualified Data.ByteString.Lazy.Char8                     as B
import           Data.Tree
import qualified Data.Vector                                    as V
import           Numeric.LinearAlgebra
import           System.Random.MWC

import           ArgParseSim
import           ParsePhyloModel

import           EvoMod.ArgParse
import           EvoMod.Data.Alphabet.Alphabet
import           EvoMod.Data.MarkovProcess.EDMModel
import           EvoMod.Data.MarkovProcess.MixtureModel
import           EvoMod.Data.MarkovProcess.PhyloModel
-- import           EvoMod.Data.MarkovProcess.RateMatrix
import           EvoMod.Data.MarkovProcess.SubstitutionModel
import           EvoMod.Data.Sequence.MultiSequenceAlignment
import           EvoMod.Data.Sequence.Sequence
import           EvoMod.Data.Tree.MeasurableTree
import           EvoMod.Data.Tree.NamedTree
import           EvoMod.Data.Tree.Tree
import           EvoMod.Export.Sequence.Fasta
import           EvoMod.Import.MarkovProcess.EDMModelPhylobayes hiding (Parser)
import           EvoMod.Import.Tree.Newick                      hiding (name)
import           EvoMod.Simulate.MarkovProcessAlongTree
import           EvoMod.Tools

-- | Simulate a 'MultiSequenceAlignment' for a given phylogenetic model,
-- phylogenetic tree, and alignment length.
simulateMSA :: (PrimMonad m, Measurable a, Named a)
            => PhyloModel -> Tree a -> Int -> Gen (PrimState m)
            -> m MultiSequenceAlignment
simulateMSA pm t n g = do
  statesTree <- case pm of
    PhyloSubstitutionModel sm -> simulateNSitesAlongTree n (smRateMatrix sm) t g
    PhyloMixtureModel mm      -> simulateNSitesAlongTreeMixtureModel n ws qs t g
      where
        ws = vector $ getWeights mm
        qs = getRateMatrices mm
  let leafNames  = map name $ leafs t
      leafStates = leafs statesTree
      code       = pmCode pm
      sequences  = [ toSequence sId (B.pack . map w2c $ indicesToCharacters code ss) |
                    (sId, ss) <- zip leafNames leafStates ]
  return $ fromSequenceList sequences

-- -- | Simulate a 'MultiSequenceAlignment' for a given substitution model and
-- -- phylogenetic tree.
-- simulateMSA :: (PrimMonad m, Measurable a, Named a)
--             => Code -> Int -> RateMatrix -> Tree a -> Gen (PrimState m)
--             -> m MultiSequenceAlignment
-- simulateMSA c n q t g = do
--   statesTree <- simulateNSitesAlongTree n q t g
--   let leafNames  = map name $ leafs t
--       leafStates = leafs statesTree
--       sequences  = [ toSequence sId (B.pack . map w2c $ indicesToCharacters c ss) |
--                     (sId, ss) <- zip leafNames leafStates ]
--   return $ fromSequenceList sequences

main :: IO ()
main = do
  EvoModSimArgs treeFile phyloModelStr len mEDMFile mSeed quiet outFile <- parseEvoModSimArgs
  unless quiet $ do
    programHeader
    putStrLn ""
    putStrLn "Read tree."
  tree <- parseFileWith newick treeFile
  unless quiet $ do
    B.putStr $ summarize tree
    putStrLn ""
  edmCs <- case mEDMFile of
    Nothing   -> return Nothing
    Just edmF -> do
      unless quiet $
        putStrLn "Read EDM file."
      Just <$> parseFileWith phylobayes edmF
  unless quiet $ do
    -- Is there a better way?
    maybe (return ()) (B.putStrLn . summarizeEDMComponents) edmCs
    putStrLn ""
    putStrLn "Read model string."
  let phyloModel = parseByteStringWith (phyloModelString edmCs) phyloModelStr
  unless quiet $ do
    B.putStr . B.unlines $ pmSummarize phyloModel
    putStrLn ""
    putStrLn "Simulate alignment."
    putStrLn $ "Length: " ++ show len ++ "."
  gen <- case mSeed of
    Nothing -> putStrLn "Seed: random"
               >> createSystemRandom
    Just s  -> putStrLn ("Seed: " ++ show s ++ ".")
               >> initialize (V.fromList s)
  msa <- simulateMSA phyloModel tree len gen
  let output = sequencesToFasta $ msaSequences msa
  B.writeFile outFile output
  unless quiet $ do
    putStrLn ""
    putStrLn ("Output written to file '" ++ outFile ++ "'.")
