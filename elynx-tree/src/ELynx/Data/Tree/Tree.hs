-- |
-- Module      :  ELynx.Data.Tree.Tree
-- Description :  Functions related to phylogenetic trees
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Thu Jan 17 09:57:29 2019.
--
-- Functions to work with rooted, rose 'Tree's with labeled leaves. Although for
-- phylogenetic trees, the order of children is unimportant, equality checks and
-- other comparisons are sensitive to the order of children for the moment. The
-- reason is that the underlying data structure stores the children as a list,
-- which has a specific order.
--
-- Comment about nomenclature:
--
-- - A 'Tree' is defined as
--
-- @
-- data Tree a = Node {
--         rootLabel :: a,         -- ^ label value
--         subForest :: Forest a   -- ^ zero or more child trees
--     }
-- @
--
-- This means, that the word 'Node' is reserved for the constructor of a tree, and
-- that a 'Node' has a label and children. The terms 'Node' and /label/ are not to
-- be confused.
--
-- Using the 'Tree' data type has some disadvantages:
--
-- 1. Branch labels are not explicit.
--
-- 2. The order of the sub-forest does not matter for phylogenetic trees.
-- Equality checks will throw false negatives the compared trees only differ in
-- their orders of sub-trees.
--
-- For example:
-- @
-- -- | A rose tree with unordered sub-forest, branch labels of type @e@ and node
-- -- labels of type @a@.
-- data Tree e a = Node e a (Set (Tree e a))
-- @
--
-- Branches can have /lengths/. For example, a branch length can be a distance
-- or a given number of time units.
--
-- NOTE: Trees in this library are all rooted. Unrooted trees can be treated with a
-- rooted data structure, as it is used here. However, some functions may be
-- meaningless.
module ELynx.Data.Tree.Tree
  ( singleton,
    degree,
    leaves,
    pruneWith,
    dropLeafWith,
    intersectWith,
    merge,
    tZipWith,
    partitionTree,
    subForestGetSubsets,
    subTree,
    bifurcating,
    clades,
  )
where

import Control.Monad (zipWithM)
import Data.List
  ( foldl',
    foldl1',
  )
import Data.Maybe (mapMaybe)
import qualified Data.Set as S
import Data.Traversable
import Data.Tree

-- | The simplest tree. Usually an extant leaf.
singleton :: a -> Tree a
singleton l = Node l []

-- | The degree of the root node of a tree.
degree :: Tree a -> Int
degree = (+ 1) . length . subForest

-- | Get leaves of tree.
leaves :: Tree a -> [a]
leaves (Node l []) = [l]
leaves (Node _ f) = concatMap leaves f

-- | Prune or remove degree two inner nodes. The information stored in a pruned
-- node can be used to change the daughter node. To discard this information,
-- use, @pruneWith const@, otherwise @pruneWith (\daughter parent -> combined)@.
pruneWith :: (a -> a -> a) -> Tree a -> Tree a
pruneWith _ n@(Node _ []) = n
pruneWith f (Node paLbl [ch]) =
  let lbl = f (rootLabel ch) paLbl in pruneWith f $ Node lbl (subForest ch)
pruneWith f (Node paLbl chs) = Node paLbl (map (pruneWith f) chs)

-- | Drop a leaf from a tree with unique leaf names. The possibly resulting
-- degree two node is pruned with 'pruneWith'. Two functions are given for node
-- name extraction, and for the combination of possibly resulting degree two
-- nodes.
dropLeafWith ::
  (Show b, Ord b) => (a -> b) -> (a -> a -> a) -> b -> Tree a -> Tree a
dropLeafWith f g l t
  | l `notElem` lvs = error "dropLeafWith: leaf not found on tree."
  | S.size (S.fromList lvs) < length lvs =
    error
      "dropLeafWith: tree does not have unique leaves."
  | otherwise = dropLeafWithUnsafe f g l t
  where
    lvs = leaves $ fmap f t

-- See 'dropLeafWith'.
dropLeafWithUnsafe :: Eq b => (a -> b) -> (a -> a -> a) -> b -> Tree a -> Tree a
dropLeafWithUnsafe f g lf (Node x xs)
  | length xs' == 1 = let Node z zs = head xs' in Node (g z x) zs
  | otherwise = Node x xs'
  where
    isThisLeaf y = null (subForest y) && f (rootLabel y) == lf
    xs' = map (dropLeafWithUnsafe f g lf) (filter (not . isThisLeaf) xs)

-- | Compute the intersection of trees.
--
-- The intersections are the largest subtrees sharing the same leaf set. Leaf
-- are compared using a given function. Leaves are dropped with 'dropLeafWith',
-- and degree two nodes are pruned with 'pruneWith'.
intersectWith ::
  (Show b, Ord b) => (a -> b) -> (a -> a -> a) -> [Tree a] -> [Tree a]
intersectWith f g ts =
  if null ls
    then error "intersect: intersection of leaves is empty."
    else map (retainLeavesWith f g ls) ts
  where
    -- Leaf sets.
    lss = map (S.fromList . leaves . fmap f) ts
    -- Common leaf set.
    ls = foldl1' S.intersection lss

-- Retain all leaves in a provided set; or conversely, drop all leaves not in a
-- provided set.
retainLeavesWith ::
  (Show b, Ord b) => (a -> b) -> (a -> a -> a) -> S.Set b -> Tree a -> Tree a
retainLeavesWith f g ls t = foldl' (flip (dropLeafWith f g)) t leavesToDrop
  where
    leavesToDrop = filter (`S.notMember` ls) $ leaves $ fmap f t

-- | Merge two trees with the same topology. Returns 'Nothing' if the topologies
-- are different.
merge :: Tree a -> Tree b -> Maybe (Tree (a, b))
merge (Node l xs) (Node r ys) =
  if length xs == length ys
    then -- I am proud of that :)).
      zipWithM merge xs ys >>= Just . Node (l, r)
    else Nothing

-- | Apply a function with different effect on each node to a 'Traversable'.
-- Based on https://stackoverflow.com/a/41523456.
tZipWith :: Traversable t => (a -> b -> c) -> [a] -> t b -> Maybe (t c)
tZipWith f xs = sequenceA . snd . mapAccumL pair xs
  where
    pair [] _ = ([], Nothing)
    pair (y : ys) z = (ys, Just (f y z))

-- | Each node of a tree is root of a subtree. Get the leaves of the subtree of
-- each node.
partitionTree :: (Ord a) => Tree a -> Tree (S.Set a)
partitionTree (Node l []) = Node (S.singleton l) []
partitionTree (Node _ xs) = Node (S.unions $ map rootLabel xs') xs'
  where
    xs' = map partitionTree xs

-- | Get subtree of 'Tree' with nodes satisfying predicate. Return 'Nothing', if
-- no leaf satisfies predicate. At the moment: recursively, for each child, take
-- the child if any leaf in the child satisfies the predicate.
subTree :: (a -> Bool) -> Tree a -> Maybe (Tree a)
subTree p leaf@(Node lbl [])
  | p lbl = Just leaf
  | otherwise = Nothing
subTree p (Node lbl chs) =
  if null subTrees
    then Nothing
    else Just $ Node lbl subTrees
  where
    subTrees = mapMaybe (subTree p) chs

-- | Loop through each tree in a forest to report the complementary leaf sets.
subForestGetSubsets ::
  (Ord a) =>
  -- | Complementary partition at the stem
  S.Set a ->
  -- | Tree with partition nodes
  Tree (S.Set a) ->
  [S.Set a]
subForestGetSubsets lvs t = lvsOthers
  where
    xs = subForest t
    nChildren = length xs
    lvsChildren = map rootLabel xs
    lvsOtherChildren =
      [ S.unions $ lvs : take i lvsChildren ++ drop (i + 1) lvsChildren
        | i <- [0 .. (nChildren - 1)]
      ]
    lvsOthers = map (S.union lvs) lvsOtherChildren

-- | Check if a tree is bifurcating. A Bifurcating tree only contains degree one
-- and degree three nodes. I know, one should use a proper data structure to
-- encode bifurcating trees.
bifurcating :: Tree a -> Bool
bifurcating (Node _ []) = True
bifurcating (Node _ [x, y]) = bifurcating x && bifurcating y
bifurcating (Node _ [_]) = False
bifurcating (Node _ _) = False

-- TODO: This bifurcating stuff irritates me. There are two solutions:
--
-- 1. Use a bifurcating data structure.
--
-- 2. Do not move down multifurcations.
--
-- Solution 1 is pretty, but doesn't allow for what we actually want to do,
-- which is solution 2. We want to encode clades that for sure do not contain
-- the root as multifurcations.

-- | Get clades induced by multifurcations.
clades :: Ord a => Tree a -> [S.Set a]
clades (Node _ []) = []
clades (Node _ [x]) = clades x
clades (Node _ [x, y]) = clades x ++ clades y
clades t = S.fromList (leaves t) : concatMap clades (subForest t)
