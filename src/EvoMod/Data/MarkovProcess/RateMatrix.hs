{- |
Description :  Rate matrix helper functions
Copyright   :  (c) Dominik Schrempf 2017
License     :  GPLv3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  non-portable (not tested)

Some helper functions that come handy when working with rate matrices of
continuous-time discrete-state Markov processes.

* Changelog

-}

module EvoMod.Data.MarkovProcess.RateMatrix
  ( RateMatrix
  , ExchMatrix
  , StationaryDistribution
  , normalize
  , normalizeWith
  , setDiagonal
  , toExchMatrix
  , fromExchMatrix
  , getStationaryDistribution
  )
where

import           Numeric.LinearAlgebra      hiding (normalize)
import           Prelude                    hiding ((<>))

import           EvoMod.Tools.Equality
import           EvoMod.Tools.LinearAlgebra
import           EvoMod.Tools.Vector

-- | A rate matrix is just a real matrix.
type RateMatrix = Matrix R

-- | A matrix of exchangeabilities, we have q = e * pi, where q is a rate
-- matrix, e is the exchangeability matrix and pi is the diagonal matrix
-- containing the stationary frequency distribution.
type ExchMatrix = Matrix R

-- | Stationary distribution of a rate matrix.
type StationaryDistribution = Vector R

-- | Normalizes a Markov process generator such that one event happens per unit
-- time. Calculates stationary distribution from rate matrix.
normalize :: RateMatrix -> RateMatrix
normalize m = normalizeWith (getStationaryDistribution m) m

-- | Normalizes a Markov process generator such that one event happens per unit
-- time. Stationary distribution has to be given.
normalizeWith :: StationaryDistribution -> RateMatrix -> RateMatrix
normalizeWith f m = scale (1.0 / totalRate) m
  where totalRate = norm_1 $ f <# matrixSetDiagToZero m

-- | Set the diagonal entries of a matrix such that the rows sum to 0.
setDiagonal :: RateMatrix -> RateMatrix
setDiagonal m = diagZeroes - diag (fromList rowSums)
  where diagZeroes = matrixSetDiagToZero m
        rowSums    = map norm_1 $ toRows diagZeroes

-- | Extract the exchangeability matrix from a rate matrix.
toExchMatrix :: RateMatrix -> StationaryDistribution -> ExchMatrix
toExchMatrix m f = m <> diag oneOverF
  where oneOverF = cmap (1.0/) f

-- | Convert exchangeability matrix to rate matrix.
fromExchMatrix :: ExchMatrix -> StationaryDistribution -> RateMatrix
fromExchMatrix em d = normalizeWith d $ setDiagonal $ em <> diag d

-- | Get stationary distribution from 'RateMatrix'. Involves eigendecomposition.
-- If the given matrix does not satisfy the required properties of transition
-- rate matrices and no eigenvector with an eigenvalue nearly equal to 0 is
-- found, an error is thrown. Is there an easier way to calculate the stationary
-- distribution or a better way to handle errors (of course I could use the
-- Maybe monad, but then the error report is just delayed to the calling
-- function)?
getStationaryDistribution :: RateMatrix -> StationaryDistribution
getStationaryDistribution m =
  if magnitude (eVals ! i) `nearlyEq` 0
  then normalizeSumVec 1.0 distReal
  else error "Could not retrieve stationary distribution."
    where
      (eVals, eVecs) = eig (tr m)
      i = minIndex eVals
      distComplex = toColumns eVecs !! i
      distReal = cmap realPart distComplex
