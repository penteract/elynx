{-# LANGUAGE ScopedTypeVariables #-}

-- |
--   Description :  Work with transition probability matrices on rooted trees
--   Copyright   :  (c) Dominik Schrempf 2017
--   License     :  GPLv3
--
--   Maintainer  :  dominik.schrempf@gmail.com
--   Stability   :  unstable
--   Portability :  non-portable (not tested)
--
-- Calculate transition probability matrices, map rate matrices on trees, populate
-- a tree with states according to a stationary distribution, etc.
--
-- The implementation of the Markov process is more than basic and can be improved
-- in a lot of ways.
module ELynx.Simulate.MarkovProcessAlongTree
  ( -- * Single rate matrix.
    simulate,
    simulateAndFlatten,

    -- * Mixture models.
    simulateMixtureModel,
    simulateAndFlattenMixtureModel,
    simulateAndFlattenMixtureModelPar,
  )
where

import Control.Concurrent
import Control.Concurrent.Async
import Control.Monad
import Control.Monad.Primitive
import Control.Parallel.Strategies
import Data.Tree
import qualified Data.Vector.Storable as V
import Data.Word (Word32)
import ELynx.Data.MarkovProcess.RateMatrix
import ELynx.Simulate.MarkovProcess
import Numeric.LinearAlgebra
import System.Random.MWC
import System.Random.MWC.Distributions (categorical)

toProbTree :: RateMatrix -> Tree Double -> Tree ProbMatrix
toProbTree q = fmap (probMatrix q)

getRootStates ::
  PrimMonad m =>
  Int ->
  StationaryDistribution ->
  Gen (PrimState m) ->
  m [State]
getRootStates n d g = replicateM n $ categorical d g

-- | Simulate a number of sites for a given substitution model. Only the states
-- at the leafs are retained. The states at internal nodes are removed. This has
-- a lower memory footprint.
--
-- XXX: Improve performance. Use vectors, not lists.
simulateAndFlatten ::
  PrimMonad m =>
  Int ->
  StationaryDistribution ->
  ExchangeabilityMatrix ->
  Tree Double ->
  Gen (PrimState m) ->
  m [[State]]
simulateAndFlatten n d e t g = do
  let q = fromExchangeabilityMatrix e d
      pt = toProbTree q t
  is <- getRootStates n d g
  simulateAndFlatten' is pt g

-- This is the heart of the simulation. Take a tree and a list of root states.
-- Recursively jump down the branches to the leafs. Forget states at internal.
simulateAndFlatten' ::
  (PrimMonad m) =>
  [State] ->
  Tree ProbMatrix ->
  Gen (PrimState m) ->
  m [[State]]
simulateAndFlatten' is (Node p f) g = do
  is' <- mapM (\i -> jump i p g) is
  if null f
    then return [is']
    else concat <$> sequence [simulateAndFlatten' is' t g | t <- f]

-- | Simulate a number of sites for a given substitution model. Keep states at
-- internal nodes. The result is a tree with the list of simulated states as
-- node labels.
simulate ::
  PrimMonad m =>
  Int ->
  StationaryDistribution ->
  ExchangeabilityMatrix ->
  Tree Double ->
  Gen (PrimState m) ->
  m (Tree [State])
simulate n d e t g = do
  let q = fromExchangeabilityMatrix e d
      pt = toProbTree q t
  is <- getRootStates n d g
  simulate' is pt g

-- This is the heart of the simulation. Take a tree and a list of root states.
-- Recursively jump down the branches to the leafs.
simulate' ::
  (PrimMonad m) =>
  [State] ->
  Tree ProbMatrix ->
  Gen (PrimState m) ->
  m (Tree [State])
simulate' is (Node p f) g = do
  is' <- mapM (\i -> jump i p g) is
  f' <- sequence [simulate' is' t g | t <- f]
  return $ Node is' f'

toProbTreeMixtureModel ::
  [RateMatrix] -> Tree Double -> Tree [ProbMatrix]
toProbTreeMixtureModel qs =
  fmap (\a -> [probMatrix q a | q <- qs] `using` parList rpar)

getComponentsAndRootStates ::
  PrimMonad m =>
  Int ->
  Vector R ->
  [StationaryDistribution] ->
  Gen (PrimState m) ->
  m ([Int], [State])
getComponentsAndRootStates n ws ds g = do
  cs <- replicateM n $ categorical ws g
  is <- sequence [categorical (ds !! c) g | c <- cs]
  return (cs, is)

-- | Simulate a number of sites for a given set of substitution models with
-- corresponding weights. Forget states at internal nodes. See also
-- 'simulateAndFlatten'.
simulateAndFlattenMixtureModel ::
  PrimMonad m =>
  Int ->
  Vector R ->
  [StationaryDistribution] ->
  [ExchangeabilityMatrix] ->
  Tree Double ->
  Gen (PrimState m) ->
  m [[State]]
simulateAndFlattenMixtureModel n ws ds es t g = do
  let qs = zipWith fromExchangeabilityMatrix es ds
      pt = toProbTreeMixtureModel qs t
  (cs, is) <- getComponentsAndRootStates n ws ds g
  simulateAndFlattenMixtureModel' is cs pt g

simulateAndFlattenMixtureModel' ::
  (PrimMonad m) =>
  [State] ->
  [Int] ->
  Tree [ProbMatrix] ->
  Gen (PrimState m) ->
  m [[State]]
simulateAndFlattenMixtureModel' is cs (Node ps f) g = do
  is' <- sequence [jump i (ps !! c) g | (i, c) <- zip is cs]
  if null f
    then return [is']
    else
      concat
        <$> sequence [simulateAndFlattenMixtureModel' is' cs t g | t <- f]

getChunks :: Int -> Int -> [Int]
getChunks c n = ns
  where
    n' = n `div` c
    r = n `mod` c
    ns = replicate r (n' + 1) ++ replicate (c - r) n'

splitGen :: PrimMonad m => Int -> Gen (PrimState m) -> m [Gen (PrimState m)]
splitGen n gen
  | n <= 0 = return []
  | otherwise = do
    seeds :: [V.Vector Word32] <- replicateM (n -1) $ uniformVector gen 256
    fmap (gen :) (mapM initialize seeds)

parComp :: Int -> (Int -> GenIO -> IO b) -> GenIO -> IO [b]
parComp num fun gen = do
  ncap <- getNumCapabilities
  let chunks = getChunks ncap num
  gs <- splitGen ncap gen
  mapConcurrently (uncurry fun) (zip chunks gs)

-- | See 'simulateAndFlattenMixtureModel', parallel version.
simulateAndFlattenMixtureModelPar ::
  Int ->
  Vector R ->
  [StationaryDistribution] ->
  [ExchangeabilityMatrix] ->
  Tree Double ->
  GenIO ->
  IO [[[State]]]
simulateAndFlattenMixtureModelPar n ws ds es t g = do
  let qs = zipWith fromExchangeabilityMatrix es ds
      pt = toProbTreeMixtureModel qs t
  parComp
    n
    ( \n' g' -> do
        (cs, is) <- getComponentsAndRootStates n' ws ds g'
        simulateAndFlattenMixtureModel' is cs pt g'
    )
    g

-- | Simulate a number of sites for a given set of substitution models with
-- corresponding weights. Keep states at internal nodes. See also
-- 'simulate'.
simulateMixtureModel ::
  PrimMonad m =>
  Int ->
  Vector R ->
  [StationaryDistribution] ->
  [ExchangeabilityMatrix] ->
  Tree Double ->
  Gen (PrimState m) ->
  m (Tree [State])
simulateMixtureModel n ws ds es t g = do
  let qs = zipWith fromExchangeabilityMatrix es ds
      pt = toProbTreeMixtureModel qs t
  (cs, is) <- getComponentsAndRootStates n ws ds g
  simulateMixtureModel' is cs pt g

-- See 'simulateAlongProbTree', only we have a number of mixture components. The
-- starting states and the components for each site have to be provided.
simulateMixtureModel' ::
  (PrimMonad m) =>
  [State] ->
  [Int] ->
  Tree [ProbMatrix] ->
  Gen (PrimState m) ->
  m (Tree [State])
simulateMixtureModel' is cs (Node ps f) g = do
  is' <- sequence [jump i (ps !! c) g | (i, c) <- zip is cs]
  f' <- sequence [simulateMixtureModel' is' cs t g | t <- f]
  return $ Node is' f'
