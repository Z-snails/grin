{-# LANGUAGE OverloadedStrings #-}
module Reducer.LLVM.PrimOps where

import LLVM.AST
import qualified LLVM.AST.IntegerPredicate as I
import qualified LLVM.AST.FloatingPointPredicate as F
import qualified LLVM.AST.CallingConvention as CC
import LLVM.AST.Type as LLVM
import LLVM.AST.AddrSpace
import qualified LLVM.AST.Constant as C

import qualified Grin.Grin as Grin
import Grin.TypeEnv hiding (function)
import Reducer.LLVM.Base
import Reducer.LLVM.TypeGen

cgUnit    = toCGType $ T_SimpleType T_Unit    :: CGType
cgInt64   = toCGType $ T_SimpleType T_Int64   :: CGType
cgWord64  = toCGType $ T_SimpleType T_Word64  :: CGType
cgFloat   = toCGType $ T_SimpleType T_Float   :: CGType
cgBool    = toCGType $ T_SimpleType T_Bool    :: CGType

codeGenPrimOp :: Grin.Name -> [Grin.Val] -> [Operand] -> CG Result
codeGenPrimOp name _ [opA, opB] = case name of
  -- Int
  "_prim_int_add"   -> pure . I cgInt64 $ Add  {nsw=False, nuw=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_sub"   -> pure . I cgInt64 $ Sub  {nsw=False, nuw=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_mul"   -> pure . I cgInt64 $ Mul  {nsw=False, nuw=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_div"   -> pure . I cgInt64 $ SDiv {exact=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_eq"    -> pure . I cgBool  $ ICmp {iPredicate=I.EQ,  operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_ne"    -> pure . I cgBool  $ ICmp {iPredicate=I.NE,  operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_gt"    -> pure . I cgBool  $ ICmp {iPredicate=I.SGT, operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_ge"    -> pure . I cgBool  $ ICmp {iPredicate=I.SGE, operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_lt"    -> pure . I cgBool  $ ICmp {iPredicate=I.SLT, operand0=opA, operand1=opB, metadata=[]}
  "_prim_int_le"    -> pure . I cgBool  $ ICmp {iPredicate=I.SLE, operand0=opA, operand1=opB, metadata=[]}

  -- Word
  "_prim_word_add"  -> pure . I cgWord64 $ Add  {nsw=False, nuw=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_sub"  -> pure . I cgWord64 $ Sub  {nsw=False, nuw=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_mul"  -> pure . I cgWord64 $ Mul  {nsw=False, nuw=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_div"  -> pure . I cgWord64 $ UDiv {exact=False, operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_eq"   -> pure . I cgBool   $ ICmp {iPredicate=I.EQ,  operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_ne"   -> pure . I cgBool   $ ICmp {iPredicate=I.NE,  operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_gt"   -> pure . I cgBool   $ ICmp {iPredicate=I.UGT, operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_ge"   -> pure . I cgBool   $ ICmp {iPredicate=I.UGE, operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_lt"   -> pure . I cgBool   $ ICmp {iPredicate=I.ULT, operand0=opA, operand1=opB, metadata=[]}
  "_prim_word_le"   -> pure . I cgBool   $ ICmp {iPredicate=I.ULE, operand0=opA, operand1=opB, metadata=[]}

  -- Float
  "_prim_float_add" -> pure . I cgFloat $ FAdd {fastMathFlags=noFastMathFlags, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_sub" -> pure . I cgFloat $ FSub {fastMathFlags=noFastMathFlags, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_mul" -> pure . I cgFloat $ FMul {fastMathFlags=noFastMathFlags, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_div" -> pure . I cgFloat $ FDiv {fastMathFlags=noFastMathFlags, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_eq"  -> pure . I cgBool  $ FCmp {fpPredicate=F.OEQ, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_ne"  -> pure . I cgBool  $ FCmp {fpPredicate=F.ONE, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_gt"  -> pure . I cgBool  $ FCmp {fpPredicate=F.OGT, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_ge"  -> pure . I cgBool  $ FCmp {fpPredicate=F.OGE, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_lt"  -> pure . I cgBool  $ FCmp {fpPredicate=F.OLT, operand0=opA, operand1=opB, metadata=[]}
  "_prim_float_le"  -> pure . I cgBool  $ FCmp {fpPredicate=F.OLE, operand0=opA, operand1=opB, metadata=[]}

  -- Bool
  "_prim_bool_eq"   -> pure . I cgBool $ ICmp {iPredicate=I.EQ,  operand0=opA, operand1=opB, metadata=[]}
  "_prim_bool_ne"   -> pure . I cgBool $ ICmp {iPredicate=I.NE,  operand0=opA, operand1=opB, metadata=[]}

codeGenPrimOp "_prim_int_print" _ [opA] = pure . I cgUnit $ Call
    { tailCallKind        = Nothing
    , callingConvention   = CC.C
    , returnAttributes    = []
    , function            = Right $ ConstantOperand $ C.GlobalReference (fun void [i64]) (mkName "_prim_int_print")
    , arguments           = [(opA, [])]
    , functionAttributes  = []
    , metadata            = []
    }
  where
    ptr ty = PointerType { pointerReferent = ty, pointerAddrSpace = AddrSpace 0}
    fun ret args = ptr FunctionType {resultType = ret, argumentTypes = args, isVarArg = False}

codeGenPrimOp name args _ = error $ "unknown primitive operation: " ++ Grin.unpackName name ++ " arguments: " ++ show args
