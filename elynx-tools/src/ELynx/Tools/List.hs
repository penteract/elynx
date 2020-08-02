-- |
-- Module      :  ELynx.Tools.List
-- Description :  Additional tools for lists
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Thu May  2 18:57:39 2019.
module ELynx.Tools.List
  ( -- * Lists
    shuffle,
    shuffleN,
    grabble,
  )
where

import Control.Monad
import Control.Monad.Primitive
import Control.Monad.ST
import Data.Vector (Vector)
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as M
import System.Random.MWC

-- | Shuffle a list.
shuffle :: PrimMonad m => [a] -> Gen (PrimState m) -> m [a]
shuffle xs g = head <$> grabble xs 1 (length xs) g

-- | Shuffle a list @n@ times.
shuffleN :: [a] -> Int -> GenIO -> IO [[a]]
shuffleN xs n = grabble xs n (length xs)

-- | @grabble xs m n@ is /O(m*n')/, where @n' = min n (length xs)@. Choose @n'@
-- elements from @xs@, without replacement, and that @m@ times.
grabble :: PrimMonad m => [a] -> Int -> Int -> Gen (PrimState m) -> m [[a]]
grabble xs m n gen = do
  swapss <- replicateM m $
    forM [0 .. min (l - 1) n] $ \i -> do
      j <- uniformR (i, l) gen
      return (i, j)
  return $ map (V.toList . V.take n . swapElems (V.fromList xs)) swapss
  where
    l = length xs - 1

swapElems :: Vector a -> [(Int, Int)] -> Vector a
swapElems xs swaps = runST $ do
  mxs <- V.unsafeThaw xs
  mapM_ (uncurry $ M.unsafeSwap mxs) swaps
  V.unsafeFreeze mxs
