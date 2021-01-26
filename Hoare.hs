module Hoare where

import Arithmetic
import Boolean
import Command

data HoareTriple =
  HoareTriple Bexp Command Bexp

instance Show HoareTriple where
  show (HoareTriple pre c post) = "{" ++ show pre ++ "} " ++ show c ++ " {" ++ show post ++ "}"

-- | Hoare skip rule
hoareSkip :: Bexp -> HoareTriple
hoareSkip q = HoareTriple q CSkip q

-- | Hoare assignment rule
hoareAssignment :: Char -> Aexp -> Bexp -> HoareTriple
hoareAssignment v e q = HoareTriple (substAssignment (boptimize q) (aoptimize e) v) (CAssign v e) q

-- Q[E/V] is the result of replacing in Q all occurrences of V by E
substAssignment :: Bexp -> Aexp -> Char -> Bexp
substAssignment q@(BEq (AId x) y) e v
  | x == v    = BEq e y
  | otherwise = q
substAssignment q@(BEq x (AId y)) e v
  | y == v    = BEq e (AId y)
  | otherwise = q
substAssignment (BAnd b1 b2) e v = BAnd (substAssignment b1 e v) (substAssignment b2 e v)
substAssignment (BNot b) e v     = BNot (substAssignment b e v)
substAssignment q _ _ = q

-- | Hoare sequence rule
hoareSequence :: HoareTriple -> HoareTriple -> Either String HoareTriple
hoareSequence (HoareTriple p c1 q1) (HoareTriple q2 c2 r)
  | q1 == q2  = Right $ HoareTriple p (CSequence c1 c2) r
  | otherwise = Left "Cannot construct proof"

-- | Hoare conditional rule
hoareConditional :: HoareTriple -> HoareTriple -> Either String HoareTriple
hoareConditional (HoareTriple (BAnd b1 p1) c1 q1) (HoareTriple (BAnd (BNot b2) p2) c2 q2)
  | b1 == b2 &&
    p1 == p2 &&
    q1 == q2 = Right $ HoareTriple p1 (CIfElse b1 c1 c2) q1
hoareConditional (HoareTriple (BAnd p1 b1) c1 q1) (HoareTriple (BAnd (BNot p2) b2) c2 q2)
  | b1 == b2 &&
    p1 == p2 &&
    q1 == q2 = Right $ HoareTriple p1 (CIfElse b1 c1 c2) q1
  | otherwise                    = Left "Cannot construct proof"
hoareConditional _ _ = Left "Cannot construct proof"

-- | Hoare while rule
hoareWhile :: HoareTriple -> Either String HoareTriple
hoareWhile (HoareTriple (BAnd b p1) c p2)
  | p1 == p2  = Right $ HoareTriple p1 (CWhile b c) (BAnd (BNot b) p2)
  | otherwise = Left "Cannot construct proof"
hoareWhile _ = Left "Cannot construct proof"
