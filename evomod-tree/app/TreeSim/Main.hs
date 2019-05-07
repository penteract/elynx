{- |
   Description :  Simulate reconstructed trees
   Copyright   :  (c) Dominik Schrempf 2018
   License     :  GPL-3

   Maintainer  :  dominik.schrempf@gmail.com
   Stability   :  unstable
   Portability :  portable

Creation date: Tue Feb 27 17:27:16 2018.

See Gernhard, T. (2008). The conditioned reconstructed process. Journal of
Theoretical Biology, 253(4), 769–778. http://doi.org/10.1016/j.jtbi.2008.04.005.

TODO: lambda ~ mu.

Mon Feb 4 14:26:11 CET 2019: Adding sampling probability rho. See Article
(Stadler2009) Stadler, T. On incomplete sampling under birth–death models and
connections to the sampling-based coalescent Journal of Theoretical Biology,
Elsevier BV, 2009, 261, 58-66

-}

module Main where

import           Control.Concurrent                   (getNumCapabilities,
                                                       myThreadId,
                                                       threadCapability)
import           Control.Concurrent.Async.Lifted.Safe (replicateConcurrently)
import           Control.Monad                        (replicateM)
import           Control.Monad.Trans.Class
import           Control.Monad.Trans.Reader
import           Control.Parallel.Strategies
import qualified Data.ByteString.Lazy.Char8           as L
import           Data.Tree
import           Data.Vector                          (fromList)
import           Data.Word
import           System.IO
import           System.Random.MWC

import           OptionsTreeSim

import           EvoMod.Data.Tree.PhyloTree           (PhyloIntLabel)
import           EvoMod.Data.Tree.SumStat             (formatNChildSumStat,
                                                       toNChildSumStat)
import           EvoMod.Export.Tree.Newick            (toNewickPhyloIntTree)
import           EvoMod.Options
import           EvoMod.Simulate.PointProcess         (simulateReconstructedTree)
import           EvoMod.Tools.Logger


newSection :: String -> String
newSection h = unlines
  [ ""
  , "-- " ++ h ]

main :: IO ()
main = do
  a <- parseArgs
  h <- setupLogger (argsVerbosity a) (argsFileNameOut a)
  runReaderT simulate (Params a h)
  closeLogger h

simulate :: Simulation ()
simulate = do
  a <- arguments <$> ask
  let s = argsSumStat a
  c <- lift getNumCapabilities
  hdr <- lift programHeader
  logS hdr
  logS $ newSection "Arguments"
  logS $ reportArgs a
  logS $ newSection "Simulation"
  logSDebug $ "Number of used cores: " ++ show c
  trs <- simulateNTreesConcurrently c a
  let ls = if s
           then parMap rpar (formatNChildSumStat . toNChildSumStat) trs
           else parMap rpar toNewickPhyloIntTree trs
  let mfn = argsFileNameOut a
  case mfn of
    Nothing -> logLBSQuiet $ L.unlines ls
    Just fn -> lift $ L.writeFile fn $ L.unlines ls

simulateNTreesConcurrently :: Int -> Args -> Simulation [Tree PhyloIntLabel]
simulateNTreesConcurrently c (Args t n h l m r _ _ _ _ s) = do
  let l' = l * r
      m' = m - l * (1.0 - r)
  trsCon <- replicateConcurrently c (simulateNTrees (t `div` c) n h l' m' s)
  trsRem <- simulateNTrees (t `mod` c) n h l' m' s
  return $ concat trsCon ++ trsRem

simulateNTrees :: Int -> Int -> Maybe Double -> Double -> Double
               -> Maybe [Word32]
               -> Simulation [Tree PhyloIntLabel]
simulateNTrees t n mH l m s
  | t <= 0 = return []
  | otherwise = do
      reportCapability
      g <- lift $ maybe createSystemRandom (initialize . fromList) s
      let f = simulateReconstructedTree n mH l m g
      replicateM t f

-- simulateNBranchLengthNChildrenConcurrently :: Int -> Args -> IO T.Text
-- simulateNBranchLengthNChildrenConcurrently c (Args t n h l m _ v _ s) = do
--   trsCon <- replicateConcurrently c (simulateNBranchLengthNChildren (t `div` c) n h l m v s)
--   trsRem <- simulateNBranchLengthNChildren (t `mod` c) n h l m v s
--   let trs = concat trsCon ++ trsRem
--       ls  = parMap rpar formatNChildSumStat trs
--   return $ T.unlines ls


-- simulateNBranchLengthNChildren :: Int -> Int -> Maybe Double -> Double -> Double -> Bool
--                                -> Maybe Int
--                                -> IO [[(Double, Int)]]
-- simulateNBranchLengthNChildren t n mH l m v s = do
--   when v reportCapability
--   g <- maybe createSystemRandom (initialize . singleton . fromIntegral) s
--   let f = case mH of
--             Nothing -> simulateBranchLengthNChildrenRandomHeight n l m g
--             Just h  -> simulateBranchLengthNChildren n h l m g
--   replicateM t f

reportCapability :: Simulation ()
reportCapability = do
  i <- lift myThreadId
  (c, _) <- lift $ threadCapability i
  logSDebug $ "Running on core: " ++ show c

type Simulation = ReaderT Params IO

data Params = Params { arguments  :: Args
                     , mLogHandle :: Maybe Handle }

instance Logger Params where
  verbosity = argsVerbosity . arguments
  mHandle = mLogHandle
