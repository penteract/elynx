-- |
-- Module      :  ELynx.Tree.Splittable
-- Description :  Splittable branch labels
-- Copyright   :  (c) Dominik Schrempf, 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Sat Jul 18 13:52:22 2020.
module ELynx.Tree.Splittable
  ( Splittable (..),
  )
where

-- | A data type that can be combined using '<>' and split into one out of two
-- equal entities.
--
-- The following equality should hold:
--
-- @
-- split x <> split x = x
-- @
class Splittable e where
  split :: e -> e

instance Splittable Double where
  split = (/ 2)
