{- |
Module      :  EvoMod.Data.Tree.Distance
Description :  Compute distances between trees
Copyright   :  (c) Dominik Schrempf 2019
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Thu Jun 13 17:15:54 2019.

TODO: Compare with http://evolution.genetics.washington.edu/phylip/doc/treedist.html.

TODO: Implement branch score distance.

-}

module EvoMod.Data.Tree.Distance
  ( bipartitions
  , multipartitions
  , symmetricDistance
  , symmetricDistanceWith
  , incompatibleSplitsDistance
  , incompatibleSplitsDistanceWith
  -- , branchScoreDistance
  -- , branchScoreDistanceWith
  , computePairwiseDistances
  , computeAdjacentDistances
  ) where

import           Data.List
import qualified Data.Set              as Set
import           Data.Tree

import           EvoMod.Data.Tree.Tree
import           EvoMod.Data.Tree.Bipartition

leavesSet :: Ord a => Tree a -> Set.Set a
leavesSet = Set.fromList . leaves

-- TODO.
-- -- | Each node of a tree is root of a subtree. Set the node label to the leaves
-- -- of this subtree.
-- toLeavesTree :: Tree a -> Tree [a]
-- toLeavesTree (Node l []) = Node [l] []
-- toLeavesTree (Node _ xs) = Node (concatMap rootLabel xs') xs'
--   where xs' = map toLeavesTree xs

-- | Get all bipartitions. XXX: This is slow at the moment, because 'leaves' is
-- called excessively.
bipartitions :: Ord a => Tree a -> [Bipartition a]
bipartitions = bipartitions' Set.empty

-- XXX: A helper function could reduce redundancy a lot in the next functions.
-- bipartitionsThisNode :: Tree a -> [Bipartition a]
-- But:
-- 1. The calling function need to pass on the leaves of the other branches, and
--    so, they have to be recalculated.
-- 2. The unnecessary recalculation of leaves is fostered.
-- XXX: Use 'toLeaves'.
bipartitions' :: Ord a => Set.Set a -> Tree a -> [Bipartition a]
bipartitions' _   (Node _ []    ) = []
bipartitions' lsC (Node _ [c]   ) = bipartitions' lsC c
bipartitions' lsC (Node _ xs    )
  -- It really sucks that we have to treat a bifurcating root separately. But
  -- that's just how it is.
  | Set.null lsC && length xs == 2 =
    let l = head xs
        r = xs !! 1
        lsL = leavesSet l
        lsR = leavesSet r
    in bp lsL lsR : bipartitions' lsL r ++ bipartitions' lsR l
  | otherwise = bs ++ concat (zipWith bipartitions' lsOthers xs)
  where
    nChildren  = length xs
    lsChildren = map leavesSet xs
    lsOthers   = [ Set.unions $ lsC : take i lsChildren ++ drop (i+1) lsChildren
                      | i <- [0 .. (nChildren - 1)] ]
    bs         = zipWith bp lsChildren lsOthers

-- XXX: Rename this function. It does not compute multipartitions, rather it
-- computes bipartitions, but merges leaves for multifurcations.
-- | Get all bipartitions, but combine leaves from multi-furcations. This is
-- useful to find incompatible splits. See 'incompatibleSplitsDistance'.
multipartitions :: Ord a => Tree a -> [Bipartition a]
-- Assume that a root node with three children actually corresponds to an
-- unrooted tree.
multipartitions (Node _ [a, b, c]) = bp lsA lsBC
                                     : bp lsB lsAC
                                     : bp lsC lsAB
                                     : multipartitions' lsBC a
                                     ++ multipartitions' lsAC b
                                     ++ multipartitions' lsAB c
  where
    lsA = leavesSet a
    lsB = leavesSet b
    lsC = leavesSet c
    lsAB = lsA `Set.union` lsB
    lsAC = lsA `Set.union` lsC
    lsBC = lsB `Set.union` lsC
multipartitions n                  = multipartitions' Set.empty n

multipartitions' :: Ord a => Set.Set a -> Tree a -> [Bipartition a]
multipartitions' _   (Node _ []    ) = []
multipartitions' lsC (Node _ [c]   ) = multipartitions' lsC c
multipartitions' lsC (Node _ [l, r])
  | Set.null lsC = let lsL = leavesSet l
                       lsR = leavesSet r
                   in bp lsL lsR : multipartitions' lsL r ++ multipartitions' lsR l
  | otherwise = let lsL = leavesSet l
                    lsR = leavesSet r
                    lsCL = lsL `Set.union` lsC
                    lsCR = lsR `Set.union` lsC
                in bp lsCL lsR : bp lsCR lsL :
                   multipartitions' lsCL r ++ multipartitions' lsCR l
multipartitions' lsC n
  | Set.null lsC = []
  | otherwise = [ bp lsC $ leavesSet n ]

-- Symmetric difference between two lists.
symmetricDifference :: Ord a => Set.Set a -> Set.Set a -> Set.Set a
symmetricDifference xs ys = Set.difference xs ys `Set.union` Set.difference ys xs

-- | Symmetric (Robinson-Foulds) distance between two trees. Assumes that the
-- leaves have unique names! Before comparing the leaf labels, apply a function
-- . This is useful to compare the labels of 'Named' trees on their names only.
--
-- XXX: Comparing a list of trees with this function recomputes bipartitions.
symmetricDistanceWith :: (Ord b) => (a -> b) -> Tree a -> Tree a -> Int
symmetricDistanceWith f t1 t2 = length $ symmetricDifference (bs t1) (bs t2)
  where bs t = Set.fromList $ bipartitions $ fmap f t

-- | See 'symmetricDistanceWith', but with 'id' for comparisons.
symmetricDistance :: Ord a => Tree a -> Tree a -> Int
symmetricDistance = symmetricDistanceWith id

-- | Number of incompatible splits. Similar to 'symmetricDistance' but merges
-- multifurcations. Before comparing the leaf labels, apply a function . This is
-- useful to compare the labels of 'Named' trees on their names only.
incompatibleSplitsDistanceWith :: (Ord b) => (a -> b) -> Tree a -> Tree a -> Int
incompatibleSplitsDistanceWith f t1 t2 = length $ symmetricDifference (ms t1) (ms t2)
  where ms t = Set.fromList $ multipartitions $ fmap f t

-- | See 'incompatibleSplitsDistanceWith', use 'id' for comparisons.
incompatibleSplitsDistance :: (Ord a) => Tree a -> Tree a -> Int
incompatibleSplitsDistance = incompatibleSplitsDistanceWith id

-- -- | Compute branch score distance between two trees. Before comparing the leaf
-- -- labels, apply a function. This is useful to compare the labels of 'Named'
-- -- trees on their names only.
-- branchScoreDistanceWith :: (Ord b, Floating c)
--                         => (a -> b) -- ^ Label to compare on
--                         -> (a -> c) -- ^ Branch length associated with a node
--                         -> Tree a -> Tree a -> Double
-- branchScoreDistanceWith f g t1 t2 = undefined

-- -- | See 'branchScoreDistanceWith', use 'id' for comparisons.
-- branchScoreDistance :: Ord a => Tree a -> Tree a -> Double
-- branchScoreDistance = branchScoreDistanceWith id id

-- | Compute pairwise distances of a list of input trees. Use given distance
-- measure function. Returns a triple, the first two elements are the indices of
-- the compared trees, the third is the distance.
computePairwiseDistances :: (Tree a -> Tree a -> Int) -- ^ Distance function
                         -> [Tree a]                  -- ^ Input trees
                         -> [(Int, Int, Int)]         -- ^ (index i, index j, distance i j)
computePairwiseDistances dist trs = [ (i, j, dist x y)
                                    | (i:is, x:xs) <- zip (tails [0..]) (tails trs)
                                    , (j, y) <- zip is xs ]

-- | Compute distances between adjacent pairs of a list of input trees. Use
-- given distance measure function.
computeAdjacentDistances :: (Tree a -> Tree a -> Int) -- ^ Distance function
                         -> [Tree a]                  -- ^ Input trees
                         -> [Int]
computeAdjacentDistances dist trs = [ dist x y | (x, y) <- zip trs (tail trs) ]

