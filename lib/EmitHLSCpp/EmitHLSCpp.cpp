//===------------------------------------------------------------*- C++ -*-===//
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Affine/IR/AffineValueMap.h"
#include "mlir/Dialect/SCF/SCF.h"
#include "mlir/Dialect/StandardOps/IR/Ops.h"
#include "mlir/IR/AffineExprVisitor.h"
#include "mlir/IR/Function.h"
#include "mlir/IR/IntegerSet.h"
#include "mlir/IR/Module.h"
#include "mlir/IR/StandardTypes.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Translation.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/TypeSwitch.h"
#include "llvm/Support/raw_ostream.h"

#include "EmitHLSCpp.h"

using namespace mlir;
using namespace std;

//===----------------------------------------------------------------------===//
// Some Base Classes
//
// These classes should be factored out, and can be inherited by emitters
// targeting various backends (e.g., Xilinx Vivado HLS, Intel FPGAs, etc.).
//===----------------------------------------------------------------------===//

namespace {
/// This class maintains the mutable state that cross-cuts and is shared by the
/// various emitters.
class HLSCppEmitterState {
public:
  explicit HLSCppEmitterState(raw_ostream &os) : os(os) {}

  // The stream to emit to.
  raw_ostream &os;

  bool encounteredError = false;
  unsigned currentIndent = 0;

  // This table contains all declared values.
  DenseMap<Value, SmallString<8>> nameTable;

private:
  HLSCppEmitterState(const HLSCppEmitterState &) = delete;
  void operator=(const HLSCppEmitterState &) = delete;
};
} // namespace

namespace {
/// This is the base class for all of the HLSCpp Emitter components.
class HLSCppEmitterBase {
public:
  explicit HLSCppEmitterBase(HLSCppEmitterState &state)
      : state(state), os(state.os) {}

  InFlightDiagnostic emitError(Operation *op, const Twine &message) {
    state.encounteredError = true;
    return op->emitError(message);
  }

  raw_ostream &indent() { return os.indent(state.currentIndent); }

  void addIndent() { state.currentIndent += 2; }
  void reduceIndent() { state.currentIndent -= 2; }

  // All of the mutable state we are maintaining.
  HLSCppEmitterState &state;

  // The stream to emit to.
  raw_ostream &os;

  /// Value name management methods.
  SmallString<8> addName(Value val, bool isPtr);
  SmallString<8> getName(Value val);

private:
  HLSCppEmitterBase(const HLSCppEmitterBase &) = delete;
  void operator=(const HLSCppEmitterBase &) = delete;
};
} // namespace

SmallString<8> HLSCppEmitterBase::addName(Value val, bool isPtr = false) {
  assert(state.nameTable[val].empty() && "duplicate value declaration");

  // Temporary naming rule.
  SmallString<8> newName;
  if (isPtr)
    newName += "*";
  newName += StringRef("val" + to_string(state.nameTable.size()));

  state.nameTable[val] = newName;
  return newName;
}

SmallString<8> HLSCppEmitterBase::getName(Value val) {
  // For constant scalar operations, the constant number will be returned rather
  // than the value name.
  if (val.getKind() != Value::Kind::BlockArgument) {
    if (auto constOp = dyn_cast<mlir::ConstantOp>(val.getDefiningOp())) {
      auto constAttr = constOp.getValue();
      if (auto floatAttr = constAttr.dyn_cast<FloatAttr>())
        return StringRef(to_string(floatAttr.getValueAsDouble()));
      else if (auto intAttr = constAttr.dyn_cast<IntegerAttr>())
        return StringRef(to_string(intAttr.getInt()));
      else if (auto boolAttr = constAttr.dyn_cast<BoolAttr>())
        return StringRef(to_string(boolAttr.getValue()));
    }
  }
  return state.nameTable[val];
}

namespace {
/// This class is a visitor for SSACFG operation nodes.
template <typename ConcreteType, typename ResultType, typename... ExtraArgs>
class HLSCppVisitorBase {
public:
  ResultType dispatchVisitor(Operation *op, ExtraArgs... args) {
    auto *thisCast = static_cast<ConcreteType *>(this);
    return TypeSwitch<Operation *, ResultType>(op)
        .template Case<
            // Affine statements.
            AffineForOp, AffineIfOp, AffineParallelOp, AffineApplyOp,
            AffineMaxOp, AffineMinOp, AffineLoadOp, AffineStoreOp,
            AffineYieldOp, AffineVectorLoadOp, AffineVectorStoreOp,
            AffineDmaStartOp, AffineDmaWaitOp,
            // Memref-related statements.
            AllocOp, AllocaOp, LoadOp, StoreOp, DeallocOp, DmaStartOp,
            DmaWaitOp, AtomicRMWOp, GenericAtomicRMWOp, AtomicYieldOp,
            MemRefCastOp, ViewOp, SubViewOp,
            // Tensor-related statements.
            TensorLoadOp, TensorStoreOp, ExtractElementOp, TensorFromElementsOp,
            SplatOp, TensorCastOp, DimOp, RankOp,
            // Unary expressions.
            AbsFOp, CeilFOp, NegFOp, CosOp, SinOp, TanhOp, SqrtOp, RsqrtOp,
            ExpOp, Exp2Op, LogOp, Log2Op, Log10Op,
            // Float binary expressions.
            CmpFOp, AddFOp, SubFOp, MulFOp, DivFOp, RemFOp,
            // Integer binary expressions.
            CmpIOp, AddIOp, SubIOp, MulIOp, SignedDivIOp, SignedRemIOp,
            UnsignedDivIOp, UnsignedRemIOp, XOrOp, AndOp, OrOp, ShiftLeftOp,
            SignedShiftRightOp, UnsignedShiftRightOp,
            // Complex expressions.
            AddCFOp, SubCFOp, ImOp, ReOp, CreateComplexOp,
            // Special operations.
            CopySignOp, TruncateIOp, ZeroExtendIOp, SignExtendIOp, IndexCastOp,
            SelectOp, ConstantOp, CallOp, ReturnOp>(
            [&](auto opNode) -> ResultType {
              return thisCast->visitOp(opNode, args...);
            })
        .Default([&](auto opNode) -> ResultType {
          return thisCast->visitInvalidOp(op, args...);
        });
  }

  /// This callback is invoked on any invalid operations.
  ResultType visitInvalidOp(Operation *op, ExtraArgs... args) {
    op->emitOpError("is unsupported operation.");
    abort();
  }

  /// This callback is invoked on any operations that are not handled by the
  /// concrete visitor.
  ResultType visitUnhandledOp(Operation *op, ExtraArgs... args) {
    return ResultType();
  }

#define HANDLE(OPTYPE)                                                         \
  ResultType visitOp(OPTYPE op, ExtraArgs... args) {                           \
    return static_cast<ConcreteType *>(this)->visitUnhandledOp(op, args...);   \
  }

  // Affine statements.
  HANDLE(AffineForOp);
  HANDLE(AffineIfOp);
  HANDLE(AffineParallelOp);
  HANDLE(AffineApplyOp);
  HANDLE(AffineMaxOp);
  HANDLE(AffineMinOp);
  HANDLE(AffineLoadOp);
  HANDLE(AffineStoreOp);
  HANDLE(AffineYieldOp);
  HANDLE(AffineVectorLoadOp);
  HANDLE(AffineVectorStoreOp);
  HANDLE(AffineDmaStartOp);
  HANDLE(AffineDmaWaitOp);

  // Memref-related statements.
  HANDLE(AllocOp);
  HANDLE(AllocaOp);
  HANDLE(LoadOp);
  HANDLE(StoreOp);
  HANDLE(DeallocOp);
  HANDLE(DmaStartOp);
  HANDLE(DmaWaitOp);
  HANDLE(AtomicRMWOp);
  HANDLE(GenericAtomicRMWOp);
  HANDLE(AtomicYieldOp);
  HANDLE(MemRefCastOp);
  HANDLE(ViewOp);
  HANDLE(SubViewOp);

  // Tensor-related statements.
  HANDLE(TensorLoadOp);
  HANDLE(TensorStoreOp);
  HANDLE(ExtractElementOp);
  HANDLE(TensorFromElementsOp);
  HANDLE(SplatOp);
  HANDLE(TensorCastOp);
  HANDLE(DimOp);
  HANDLE(RankOp);

  // Unary expressions.
  HANDLE(AbsFOp);
  HANDLE(CeilFOp);
  HANDLE(NegFOp);
  HANDLE(CosOp);
  HANDLE(SinOp);
  HANDLE(TanhOp);
  HANDLE(SqrtOp);
  HANDLE(RsqrtOp);
  HANDLE(ExpOp);
  HANDLE(Exp2Op);
  HANDLE(LogOp);
  HANDLE(Log2Op);
  HANDLE(Log10Op);

  // Float binary expressions.
  HANDLE(CmpFOp);
  HANDLE(AddFOp);
  HANDLE(SubFOp);
  HANDLE(MulFOp);
  HANDLE(DivFOp);
  HANDLE(RemFOp);

  // Integer binary expressions.
  HANDLE(CmpIOp);
  HANDLE(AddIOp);
  HANDLE(SubIOp);
  HANDLE(MulIOp);
  HANDLE(SignedDivIOp);
  HANDLE(SignedRemIOp);
  HANDLE(UnsignedDivIOp);
  HANDLE(UnsignedRemIOp);
  HANDLE(XOrOp);
  HANDLE(AndOp);
  HANDLE(OrOp);
  HANDLE(ShiftLeftOp);
  HANDLE(SignedShiftRightOp);
  HANDLE(UnsignedShiftRightOp);

  // Complex expressions.
  HANDLE(AddCFOp);
  HANDLE(SubCFOp);
  HANDLE(ImOp);
  HANDLE(ReOp);
  HANDLE(CreateComplexOp);

  // Special operations.
  HANDLE(CopySignOp);
  HANDLE(TruncateIOp);
  HANDLE(ZeroExtendIOp);
  HANDLE(SignExtendIOp);
  HANDLE(IndexCastOp);
  HANDLE(SelectOp);
  HANDLE(ConstantOp);
  HANDLE(CallOp);
  HANDLE(ReturnOp);
#undef HANDLE
};
} // namespace

//===----------------------------------------------------------------------===//
// Utils
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// ModuleEmitter Class Definition
//===----------------------------------------------------------------------===//

namespace {
class ModuleEmitter : public HLSCppEmitterBase {
public:
  using operand_range = Operation::operand_range;
  explicit ModuleEmitter(HLSCppEmitterState &state)
      : HLSCppEmitterBase(state) {}

  /// Affine statement emitters.
  void emitAffineFor(AffineForOp *op);
  void emitAffineIf(AffineIfOp *op);
  void emitAffineParallel(AffineParallelOp *op);
  void emitAffineApply(AffineApplyOp *op);
  void emitAffineMax(AffineMaxOp *op);
  void emitAffineMin(AffineMinOp *op);
  void emitAffineLoad(AffineLoadOp *op);
  void emitAffineStore(AffineStoreOp *op);
  void emitAffineYield(AffineYieldOp *op);

  /// Memref-related statement emitters.
  template <typename OpType>
  void emitAlloc(OpType *op);
  void emitLoad(LoadOp *op);
  void emitStore(StoreOp *op);

  /// Tensor-related statement emitters.
  void emitTensorLoad(TensorLoadOp *op);
  void emitTensorStore(TensorStoreOp *op);
  void emitSplat(SplatOp *op);
  void emitExtractElement(ExtractElementOp *op);
  void emitTensorFromElements(TensorFromElementsOp *op);
  void emitDim(DimOp *op);
  void emitRank(RankOp *op);

  /// Standard expression emitters.
  void emitBinary(Operation *op, const char *syntax);
  void emitUnary(Operation *op, const char *syntax);

  /// Special operation emitters.
  void emitIndexCast(IndexCastOp *op);
  void emitSelect(SelectOp *op);
  template <typename ResultType>
  void emitCppArray(ConstantOp *op);
  void emitConstant(ConstantOp *op);
  void emitCall(CallOp *op);

  /// Top-level MLIR module emitter.
  void emitModule(ModuleOp module);

private:
  /// MLIR component emitters.
  void emitValue(Value val, bool isPtr = false);
  void emitOperation(Operation *op);
  void emitBlock(Block &block);
  void emitFunction(FuncOp func);
};
} // namespace

//===----------------------------------------------------------------------===//
// AffineEmitter Class
//===----------------------------------------------------------------------===//

namespace {
class AffineExprEmitter : public HLSCppEmitterBase,
                          public AffineExprVisitor<AffineExprEmitter> {
public:
  using operand_range = Operation::operand_range;
  explicit AffineExprEmitter(HLSCppEmitterState &state, unsigned numDim,
                             operand_range operands)
      : HLSCppEmitterBase(state), numDim(numDim), operands(operands) {}

  void visitAddExpr(AffineBinaryOpExpr expr) { emitAffineBinary(expr, "+"); }
  void visitMulExpr(AffineBinaryOpExpr expr) { emitAffineBinary(expr, "*"); }
  void visitModExpr(AffineBinaryOpExpr expr) { emitAffineBinary(expr, "%"); }
  void visitFloorDivExpr(AffineBinaryOpExpr expr) {
    emitAffineBinary(expr, "/");
  }
  void visitCeilDivExpr(AffineBinaryOpExpr expr) {
    // This is super inefficient.
    os << "(";
    visit(expr.getLHS());
    os << " + ";
    visit(expr.getRHS());
    os << " - 1) / ";
    visit(expr.getRHS());
    os << ")";
  }

  void visitConstantExpr(AffineConstantExpr expr) {
    auto exprValue = expr.getValue();
    if (exprValue < 0)
      os << "(" << exprValue << ")";
    else
      os << exprValue;
  }

  void visitDimExpr(AffineDimExpr expr) {
    os << getName(operands[expr.getPosition()]);
  }
  void visitSymbolExpr(AffineSymbolExpr expr) {
    os << getName(operands[numDim + expr.getPosition()]);
  }

  /// Affine expression emitters.
  void emitAffineBinary(AffineBinaryOpExpr expr, const char *syntax) {
    os << "(";
    visit(expr.getLHS());
    os << " " << syntax << " ";
    visit(expr.getRHS());
    os << ")";
  }

  void emitAffineExpr(AffineExpr expr) { visit(expr); }

private:
  unsigned numDim;
  operand_range operands;
};
} // namespace

//===----------------------------------------------------------------------===//
// StmtVisitor and ExprVisitor Classes
//===----------------------------------------------------------------------===//

namespace {
class StmtVisitor : public HLSCppVisitorBase<StmtVisitor, bool> {
public:
  StmtVisitor(ModuleEmitter &emitter) : emitter(emitter) {}

  using HLSCppVisitorBase::visitOp;
  /// Affine statements.
  bool visitOp(AffineForOp op) { return emitter.emitAffineFor(&op), true; }
  bool visitOp(AffineIfOp op) { return emitter.emitAffineIf(&op), true; }
  bool visitOp(AffineParallelOp op) {
    return emitter.emitAffineParallel(&op), true;
  }
  bool visitOp(AffineApplyOp op) { return emitter.emitAffineApply(&op), true; }
  bool visitOp(AffineMaxOp op) { return emitter.emitAffineMax(&op), true; }
  bool visitOp(AffineMinOp op) { return emitter.emitAffineMin(&op), true; }
  bool visitOp(AffineLoadOp op) { return emitter.emitAffineLoad(&op), true; }
  bool visitOp(AffineStoreOp op) { return emitter.emitAffineStore(&op), true; }
  bool visitOp(AffineYieldOp op) { return emitter.emitAffineYield(&op), true; }

  /// Memref-related statements.
  bool visitOp(AllocOp op) { return emitter.emitAlloc<AllocOp>(&op), true; }
  bool visitOp(AllocaOp op) { return emitter.emitAlloc<AllocaOp>(&op), true; }
  bool visitOp(LoadOp op) { return emitter.emitLoad(&op), true; }
  bool visitOp(StoreOp op) { return emitter.emitStore(&op), true; }
  bool visitOp(DeallocOp op) { return true; }

  /// Tensor-related statements.
  bool visitOp(TensorLoadOp op) { return emitter.emitTensorLoad(&op), true; }
  bool visitOp(TensorStoreOp op) { return emitter.emitTensorStore(&op), true; }
  bool visitOp(SplatOp op) { return emitter.emitSplat(&op), true; }
  bool visitOp(ExtractElementOp op) {
    return emitter.emitExtractElement(&op), true;
  }
  bool visitOp(TensorFromElementsOp op) {
    return emitter.emitTensorFromElements(&op), true;
  }
  bool visitOp(DimOp op) { return emitter.emitDim(&op), true; }
  bool visitOp(RankOp op) { return emitter.emitRank(&op), true; }

private:
  ModuleEmitter &emitter;
};
} // namespace

namespace {
class ExprVisitor : public HLSCppVisitorBase<ExprVisitor, bool> {
public:
  ExprVisitor(ModuleEmitter &emitter) : emitter(emitter) {}

  using HLSCppVisitorBase::visitOp;
  /// Float binary expressions.
  bool visitOp(CmpFOp op);
  bool visitOp(AddFOp op) { return emitter.emitBinary(op, "+"), true; }
  bool visitOp(SubFOp op) { return emitter.emitBinary(op, "-"), true; }
  bool visitOp(MulFOp op) { return emitter.emitBinary(op, "*"), true; }
  bool visitOp(DivFOp op) { return emitter.emitBinary(op, "/"), true; }
  bool visitOp(RemFOp op) { return emitter.emitBinary(op, "%"), true; }

  /// Integer binary expressions.
  bool visitOp(CmpIOp op);
  bool visitOp(AddIOp op) { return emitter.emitBinary(op, "+"), true; }
  bool visitOp(SubIOp op) { return emitter.emitBinary(op, "-"), true; }
  bool visitOp(MulIOp op) { return emitter.emitBinary(op, "*"), true; }
  bool visitOp(SignedDivIOp op) { return emitter.emitBinary(op, "/"), true; }
  bool visitOp(SignedRemIOp op) { return emitter.emitBinary(op, "/"), true; }
  bool visitOp(UnsignedDivIOp op) { return emitter.emitBinary(op, "%"), true; }
  bool visitOp(UnsignedRemIOp op) { return emitter.emitBinary(op, "%"), true; }
  bool visitOp(XOrOp op) { return emitter.emitBinary(op, "^"), true; }
  bool visitOp(AndOp op) { return emitter.emitBinary(op, "&"), true; }
  bool visitOp(OrOp op) { return emitter.emitBinary(op, "|"), true; }
  bool visitOp(ShiftLeftOp op) { return emitter.emitBinary(op, "<<"), true; }
  bool visitOp(SignedShiftRightOp op) {
    return emitter.emitBinary(op, ">>"), true;
  }
  bool visitOp(UnsignedShiftRightOp op) {
    return emitter.emitBinary(op, ">>"), true;
  }

  /// Unary expressions.
  bool visitOp(AbsFOp op) { return emitter.emitUnary(op, "abs"), true; }
  bool visitOp(CeilFOp op) { return emitter.emitUnary(op, "ceil"), true; }
  bool visitOp(NegFOp op) { return emitter.emitUnary(op, "-"), true; }
  bool visitOp(CosOp op) { return emitter.emitUnary(op, "cos"), true; }
  bool visitOp(SinOp op) { return emitter.emitUnary(op, "sin"), true; }
  bool visitOp(TanhOp op) { return emitter.emitUnary(op, "tanh"), true; }
  bool visitOp(SqrtOp op) { return emitter.emitUnary(op, "sqrt"), true; }
  bool visitOp(RsqrtOp op) { return emitter.emitUnary(op, "1.0 / sqrt"), true; }
  bool visitOp(ExpOp op) { return emitter.emitUnary(op, "exp"), true; }
  bool visitOp(Exp2Op op) { return emitter.emitUnary(op, "exp2"), true; }
  bool visitOp(LogOp op) { return emitter.emitUnary(op, "log"), true; }
  bool visitOp(Log2Op op) { return emitter.emitUnary(op, "log2"), true; }
  bool visitOp(Log10Op op) { return emitter.emitUnary(op, "log10"), true; }

  /// Special operations.
  bool visitOp(IndexCastOp op) { return emitter.emitIndexCast(&op), true; }
  bool visitOp(SelectOp op) { return emitter.emitSelect(&op), true; }
  bool visitOp(ConstantOp op) { return emitter.emitConstant(&op), true; }
  bool visitOp(CallOp op) { return emitter.emitCall(&op), true; }
  bool visitOp(ReturnOp op) { return true; }

private:
  ModuleEmitter &emitter;
}; // namespace
} // namespace

bool ExprVisitor::visitOp(CmpFOp op) {
  switch (op.getPredicate()) {
  case CmpFPredicate::OEQ:
  case CmpFPredicate::UEQ:
    return emitter.emitBinary(op, "=="), true;
  case CmpFPredicate::ONE:
  case CmpFPredicate::UNE:
    return emitter.emitBinary(op, "!="), true;
  case CmpFPredicate::OLT:
  case CmpFPredicate::ULT:
    return emitter.emitBinary(op, "<"), true;
  case CmpFPredicate::OLE:
  case CmpFPredicate::ULE:
    return emitter.emitBinary(op, "<="), true;
  case CmpFPredicate::OGT:
  case CmpFPredicate::UGT:
    return emitter.emitBinary(op, ">"), true;
  case CmpFPredicate::OGE:
  case CmpFPredicate::UGE:
    return emitter.emitBinary(op, ">="), true;
  default:
    return true;
  }
}

bool ExprVisitor::visitOp(CmpIOp op) {
  switch (op.getPredicate()) {
  case CmpIPredicate::eq:
    return emitter.emitBinary(op, "=="), true;
  case CmpIPredicate::ne:
    return emitter.emitBinary(op, "!="), true;
  case CmpIPredicate::slt:
  case CmpIPredicate::ult:
    return emitter.emitBinary(op, "<"), true;
  case CmpIPredicate::sle:
  case CmpIPredicate::ule:
    return emitter.emitBinary(op, "<="), true;
  case CmpIPredicate::sgt:
  case CmpIPredicate::ugt:
    return emitter.emitBinary(op, ">"), true;
  case CmpIPredicate::sge:
  case CmpIPredicate::uge:
    return emitter.emitBinary(op, ">="), true;
  }
}

//===----------------------------------------------------------------------===//
// ModuleEmitter Class Implementation
//===----------------------------------------------------------------------===//

/// Affine statement emitters.
void ModuleEmitter::emitAffineFor(AffineForOp *op) {
  indent();
  os << "for (";
  auto iterVar = op->getInductionVar();

  // Emit lower bound.
  emitValue(iterVar);
  os << " = ";
  auto lowerMap = op->getLowerBoundMap();
  AffineExprEmitter lowerEmitter(state, lowerMap.getNumDims(),
                                 op->getLowerBoundOperands());
  if (lowerMap.getNumResults() == 1)
    lowerEmitter.emitAffineExpr(lowerMap.getResult(0));
  else {
    for (unsigned i = 0, e = lowerMap.getNumResults() - 1; i < e; ++i) {
      os << "max(";
    }
    lowerEmitter.emitAffineExpr(lowerMap.getResult(0));
    for (auto &expr : llvm::drop_begin(lowerMap.getResults(), 1)) {
      os << ", ";
      lowerEmitter.emitAffineExpr(expr);
      os << ")";
    }
  }
  os << "; ";

  // Emit upper bound.
  emitValue(iterVar);
  os << " < ";
  auto upperMap = op->getUpperBoundMap();
  AffineExprEmitter upperEmitter(state, upperMap.getNumDims(),
                                 op->getUpperBoundOperands());
  if (upperMap.getNumResults() == 1)
    upperEmitter.emitAffineExpr(upperMap.getResult(0));
  else {
    for (unsigned i = 0, e = upperMap.getNumResults() - 1; i < e; ++i) {
      os << "min(";
    }
    upperEmitter.emitAffineExpr(upperMap.getResult(0));
    for (auto &expr : llvm::drop_begin(upperMap.getResults(), 1)) {
      os << ", ";
      upperEmitter.emitAffineExpr(expr);
      os << ")";
    }
  }
  os << "; ";

  // Emit increase step.
  emitValue(iterVar);
  os << " += " << op->getStep() << ") {\n";

  addIndent();
  emitBlock(op->getLoopBody().front());
  reduceIndent();

  indent();
  os << "}\n";
}

void ModuleEmitter::emitAffineIf(AffineIfOp *op) {
  // Declare all values returned by AffineYieldOp. They will be further handled
  // by the AffineYieldOp emitter.
  for (auto result : op->getResults()) {
    indent();
    emitValue(result);
    os << ";\n";
  }

  indent();
  os << "if (";
  auto constrSet = op->getIntegerSet();
  AffineExprEmitter constrEmitter(state, constrSet.getNumDims(),
                                  op->getOperands());

  // Emit all constraints.
  unsigned constrIdx = 0;
  for (auto &expr : constrSet.getConstraints()) {
    constrEmitter.emitAffineExpr(expr);
    if (constrSet.isEq(constrIdx))
      os << " == 0";
    else
      os << " >= 0";

    if (constrIdx != constrSet.getNumConstraints() - 1)
      os << " && ";

    constrIdx += 1;
  }
  os << ") {\n";
  addIndent();
  emitBlock(*op->getThenBlock());
  reduceIndent();

  if (op->hasElse()) {
    indent();
    os << "} else {\n";
    addIndent();
    emitBlock(*op->getElseBlock());
    reduceIndent();
  }

  indent();
  os << "}\n";
}

void ModuleEmitter::emitAffineParallel(AffineParallelOp *op) {
  // Declare all values returned by AffineParallelOp. They will be further
  // handled by the AffineYieldOp emitter.
  for (auto result : op->getResults()) {
    indent();
    emitValue(result);
    os << ";\n";
  }

  for (unsigned i = 0, e = op->getNumDims(); i < e; ++i) {
    indent();
    os << "for (";
    auto iterVar = op->getBody()->getArgument(i);

    // Emit lower bound.
    emitValue(iterVar);
    os << " = ";
    auto lowerMap = op->getLowerBoundsValueMap().getAffineMap();
    AffineExprEmitter lowerEmitter(state, lowerMap.getNumDims(),
                                   op->getLowerBoundsOperands());
    lowerEmitter.emitAffineExpr(lowerMap.getResult(i));
    os << "; ";

    // Emit upper bound.
    emitValue(iterVar);
    os << " < ";
    auto upperMap = op->getUpperBoundsValueMap().getAffineMap();
    AffineExprEmitter upperEmitter(state, upperMap.getNumDims(),
                                   op->getUpperBoundsOperands());
    upperEmitter.emitAffineExpr(upperMap.getResult(i));
    os << "; ";

    // Emit increase step.
    emitValue(iterVar);
    auto step = op->getAttrOfType<ArrayAttr>(op->getStepsAttrName())[i]
                    .cast<IntegerAttr>()
                    .getInt();
    os << " += " << step << ") {\n";

    addIndent();
  }

  emitBlock(op->getLoopBody().front());

  for (unsigned i = 0, e = op->getNumDims(); i < e; ++i) {
    reduceIndent();

    indent();
    os << "}\n";
  }
}

void ModuleEmitter::emitAffineApply(AffineApplyOp *op) {
  indent();
  emitValue(op->getResult());
  os << " = ";
  auto affineMap = op->getAffineMap();
  AffineExprEmitter(state, affineMap.getNumDims(), op->getOperands())
      .emitAffineExpr(affineMap.getResult(0));
  os << ";\n";
}

void ModuleEmitter::emitAffineMax(AffineMaxOp *op) {
  indent();
  emitValue(op->getResult());
  os << " = ";
  auto affineMap = op->getAffineMap();
  AffineExprEmitter affineEmitter(state, affineMap.getNumDims(),
                                  op->getOperands());
  for (unsigned i = 0, e = affineMap.getNumResults() - 1; i < e; ++i) {
    os << "max(";
  }
  affineEmitter.emitAffineExpr(affineMap.getResult(0));
  for (auto &expr : llvm::drop_begin(affineMap.getResults(), 1)) {
    os << ", ";
    affineEmitter.emitAffineExpr(expr);
    os << ")";
  }
  os << ";\n";
}

void ModuleEmitter::emitAffineMin(AffineMinOp *op) {
  indent();
  emitValue(op->getResult());
  os << " = ";
  auto affineMap = op->getAffineMap();
  AffineExprEmitter affineEmitter(state, affineMap.getNumDims(),
                                  op->getOperands());
  for (unsigned i = 0, e = affineMap.getNumResults() - 1; i < e; ++i) {
    os << "min(";
  }
  affineEmitter.emitAffineExpr(affineMap.getResult(0));
  for (auto &expr : llvm::drop_begin(affineMap.getResults(), 1)) {
    os << ", ";
    affineEmitter.emitAffineExpr(expr);
    os << ")";
  }
  os << ";\n";
}

void ModuleEmitter::emitAffineLoad(AffineLoadOp *op) {
  indent();
  emitValue(op->getResult());
  os << " = ";
  emitValue(op->getMemRef());
  auto affineMap = op->getAffineMap();
  AffineExprEmitter affineEmitter(state, affineMap.getNumDims(),
                                  op->getMapOperands());
  for (auto index : affineMap.getResults()) {
    os << "[";
    affineEmitter.emitAffineExpr(index);
    os << "]";
  }
  os << ";\n";
}

void ModuleEmitter::emitAffineStore(AffineStoreOp *op) {
  indent();
  emitValue(op->getMemRef());
  auto affineMap = op->getAffineMap();
  AffineExprEmitter affineEmitter(state, affineMap.getNumDims(),
                                  op->getMapOperands());
  for (auto index : affineMap.getResults()) {
    os << "[";
    affineEmitter.emitAffineExpr(index);
    os << "]";
  }
  os << " = ";
  emitValue(op->getValueToStore());
  os << ";\n";
}

void ModuleEmitter::emitAffineYield(AffineYieldOp *op) {
  if (op->getNumOperands() == 0)
    return;

  // For now, only AffineParallel and AffineFor operations will use AffineYield
  // to return generated values.
  if (auto parentOp = dyn_cast<AffineIfOp>(op->getParentOp())) {
    unsigned resultIdx = 0;
    for (auto result : parentOp.getResults()) {
      indent();
      emitValue(result);
      os << " = ";
      emitValue(op->getOperand(resultIdx));
      os << ";\n";
      resultIdx += 1;
    }
  } else if (auto parentOp =
                 dyn_cast<mlir::AffineParallelOp>(op->getParentOp())) {
    indent();
    os << "if (";
    emitValue(parentOp.getBody()->getArgument(0));
    os << " == 0";
    for (auto iv : llvm::drop_begin(parentOp.getBody()->getArguments(), 1)) {
      os << " && ";
      emitValue(iv);
      os << " == 0";
    }
    os << ") {\n";

    // When all induction values are 0, generated values will be directly
    // assigned to the current results, correspondingly.
    addIndent();
    unsigned resultIdx = 0;
    for (auto result : parentOp.getResults()) {
      indent();
      emitValue(result);
      os << " = ";
      emitValue(op->getOperand(resultIdx));
      os << ";\n";
      resultIdx += 1;
    }
    reduceIndent();

    indent();
    os << "} else {\n";

    // Otherwise, generated values will be accumulated/reduced to the current
    // results with corresponding AtomicRMWKind operations.
    addIndent();
    resultIdx = 0;
    for (auto result : parentOp.getResults()) {
      indent();
      emitValue(result);
      switch ((AtomicRMWKind)parentOp
                  .getAttrOfType<ArrayAttr>(
                      parentOp.getReductionsAttrName())[resultIdx]
                  .cast<IntegerAttr>()
                  .getInt()) {
      case (AtomicRMWKind::addf):
      case (AtomicRMWKind::addi):
        os << " += ";
        emitValue(op->getOperand(resultIdx));
        break;
      case (AtomicRMWKind::assign):
        os << " = ";
        emitValue(op->getOperand(resultIdx));
        break;
      case (AtomicRMWKind::maxf):
      case (AtomicRMWKind::maxs):
      case (AtomicRMWKind::maxu):
        os << " = max(";
        emitValue(result);
        os << ", ";
        emitValue(op->getOperand(resultIdx));
        os << ")";
        break;
      case (AtomicRMWKind::minf):
      case (AtomicRMWKind::mins):
      case (AtomicRMWKind::minu):
        os << " = min(";
        emitValue(result);
        os << ", ";
        emitValue(op->getOperand(resultIdx));
        os << ")";
        break;
      case (AtomicRMWKind::mulf):
      case (AtomicRMWKind::muli):
        os << " *= ";
        emitValue(op->getOperand(resultIdx));
        break;
      }

      os << ";\n";
      resultIdx += 1;
    }
    reduceIndent();

    indent();
    os << "}\n";
  }
}

/// Memref-related statement emitters.
template <typename OpType>
void ModuleEmitter::emitAlloc(OpType *op) {
  // This indicates that the memref is output of the function, and has been
  // declared in the function signature.
  if (!getName(op->getResult()).empty())
    return;

  // Vivado HLS only supports static shape on-chip memory.
  if (!op->getType().hasStaticShape())
    emitError(*op, "is unranked or has dynamic shape.");

  indent();
  emitValue(op->getResult());
  for (auto &shape : op->getType().getShape())
    os << "[" << shape << "]";
  os << ";\n";
}

void ModuleEmitter::emitLoad(LoadOp *op) {
  indent();
  emitValue(op->getResult());
  os << " = ";
  emitValue(op->getMemRef());
  for (auto index : op->getIndices()) {
    os << "[";
    emitValue(index);
    os << "]";
  }
  os << ";\n";
}

void ModuleEmitter::emitStore(StoreOp *op) {
  indent();
  emitValue(op->getMemRef());
  for (auto index : op->getIndices()) {
    os << "[";
    emitValue(index);
    os << "]";
  }
  os << " = ";
  emitValue(op->getValueToStore());
  os << ";\n";
}

/// Tensor-related statement emitters.
void ModuleEmitter::emitTensorLoad(TensorLoadOp *op) {
  if (!op->getType().hasStaticShape())
    emitError(*op, "is unranked or has dynamic shape.");

  auto tensorShape = op->getType().getShape();
  // Declare a new tensor.
  indent();
  emitValue(op->getResult());
  for (auto &shape : tensorShape)
    os << "[" << shape << "]";
  os << ";\n";

  // Create a nested loop for loading tensor.
  unsigned numDim = tensorShape.size();
  for (unsigned i = 0; i < numDim; ++i) {
    indent();
    os << "for (int idx" << i << " = 0; ";
    os << "idx" << i << " < " << tensorShape[i] << "; ";
    os << "++idx" << i << ") {\n";

    addIndent();
  }

  indent();
  emitValue(op->getResult());
  for (unsigned i = 0; i < numDim; ++i)
    os << "[idx" << i << "]";
  os << " = ";
  emitValue(op->getOperand());
  for (unsigned i = 0; i < numDim; ++i)
    os << "[idx" << i << "]";
  os << ";\n";

  for (unsigned i = 0; i < numDim; ++i) {
    reduceIndent();

    indent();
    os << "}\n";
  }
}

void ModuleEmitter::emitTensorStore(TensorStoreOp *op) {
  auto tensorType = op->getOperand(0).getType().cast<TensorType>();
  if (!tensorType.hasStaticShape())
    emitError(*op, "is unranked or has dynamic shape.");

  // Create a nested loop for storing tensor.
  unsigned numDim = tensorType.getShape().size();
  for (unsigned i = 0; i < numDim; ++i) {
    indent();
    os << "for (int idx" << i << " = 0; ";
    os << "idx" << i << " < " << tensorType.getShape()[i] << "; ";
    os << "++idx" << i << ") {\n";

    addIndent();
  }

  indent();
  emitValue(op->getOperand(1));
  for (unsigned i = 0; i < numDim; ++i)
    os << "[idx" << i << "]";
  os << " = ";
  emitValue(op->getOperand(0));
  for (unsigned i = 0; i < numDim; ++i)
    os << "[idx" << i << "]";
  os << ";\n";

  for (unsigned i = 0; i < numDim; ++i) {
    reduceIndent();

    indent();
    os << "}\n";
  }
}

void ModuleEmitter::emitSplat(SplatOp *op) { return; }

void ModuleEmitter::emitExtractElement(ExtractElementOp *op) { return; }

void ModuleEmitter::emitTensorFromElements(TensorFromElementsOp *op) { return; }

void ModuleEmitter::emitDim(DimOp *op) {
  if (auto constOp = dyn_cast<ConstantOp>(op->getOperand(1).getDefiningOp())) {
    auto constVal = constOp.getValue().dyn_cast<IntegerAttr>().getInt();

    if (auto memType = op->getOperand(0).getType().dyn_cast<MemRefType>()) {
      if (memType.hasStaticShape()) {
        if (constVal >= 0 && constVal < memType.getShape().size()) {
          indent();
          emitValue(op->getResult());
          os << " = ";
          os << memType.getShape()[constVal] << ";\n";
        } else
          emitError(*op, "index is out of range.");
      } else
        emitError(*op, "is unranked or has dynamic shape.");
    } else if (auto tensorType =
                   op->getOperand(0).getType().dyn_cast<TensorType>()) {
      if (tensorType.hasStaticShape()) {
        if (constVal >= 0 && constVal < tensorType.getShape().size()) {
          indent();
          emitValue(op->getResult());
          os << " = ";
          os << tensorType.getShape()[constVal] << ";\n";
        } else
          emitError(*op, "index is out of range.");
      } else
        emitError(*op, "is unranked or has dynamic shape.");
    }
  } else
    emitError(*op, "index is not a constant.");
}

void ModuleEmitter::emitRank(RankOp *op) {
  if (auto memType = op->getOperand().getType().dyn_cast<MemRefType>()) {
    if (memType.hasRank()) {
      indent();
      emitValue(op->getResult());
      os << " = ";
      os << memType.getRank() << ";\n";
    } else
      emitError(*op, "is unranked.");
  } else if (auto tensorType =
                 op->getOperand().getType().dyn_cast<TensorType>()) {
    if (tensorType.hasRank()) {
      indent();
      emitValue(op->getResult());
      os << " = ";
      os << tensorType.getRank() << ";\n";
    } else
      emitError(*op, "is unranked.");
  }
}

/// Standard expression emitters.
void ModuleEmitter::emitBinary(Operation *op, const char *syntax) {
  indent();
  emitValue(op->getResult(0));
  os << " = ";
  emitValue(op->getOperand(0));
  os << " " << syntax << " ";
  emitValue(op->getOperand(1));
  os << ";\n";
}

void ModuleEmitter::emitUnary(Operation *op, const char *syntax) {
  indent();
  emitValue(op->getResult(0));
  os << " = " << syntax << "(";
  emitValue(op->getOperand(0));
  os << ");\n";
}

/// Special operation emitters.
void ModuleEmitter::emitIndexCast(IndexCastOp *op) {
  indent();
  emitValue(op->getResult());
  os << " = ";
  emitValue(op->getOperand());
  os << ";\n";
}

void ModuleEmitter::emitSelect(SelectOp *op) {
  indent();
  emitValue(op->getResult());
  os << " = ";
  emitValue(op->getCondition());
  os << " ? ";
  emitValue(op->getTrueValue());
  os << " : ";
  emitValue(op->getFalseValue());
  os << ";\n";
}

template <typename ResultType>
void ModuleEmitter::emitCppArray(ConstantOp *op) {
  auto denseAttr = op->getValue().dyn_cast<DenseElementsAttr>();
  auto elementType = op->getType().dyn_cast<ResultType>().getElementType();
  os << "{";
  unsigned elementIdx = 0;
  if (elementType.isF32()) {
    for (auto element : denseAttr.getFloatValues()) {
      os << element.convertToFloat();
      if (elementIdx == denseAttr.getNumElements() - 1)
        os << "}";
      else
        os << ", ";
      elementIdx += 1;
    }
  } else if (elementType.isF64()) {
    for (auto element : denseAttr.getFloatValues()) {
      os << element.convertToDouble();
      if (elementIdx == denseAttr.getNumElements() - 1)
        os << "}";
      else
        os << ", ";
      elementIdx += 1;
    }
  } else if (elementType.isInteger(1)) {
    for (auto element : denseAttr.getBoolValues()) {
      os << element;
      if (elementIdx == denseAttr.getNumElements() - 1)
        os << "}";
      else
        os << ", ";
      elementIdx += 1;
    }
  } else if (elementType.isIntOrIndex()) {
    for (auto element : denseAttr.getIntValues()) {
      os << element;
      if (elementIdx == denseAttr.getNumElements() - 1)
        os << "}";
      else
        os << ", ";
      elementIdx += 1;
    }
  } else
    emitError(*op, "has unsupported element type.");
}

void ModuleEmitter::emitConstant(ConstantOp *op) {
  auto constAttr = op->getValue();
  if (constAttr.isa<FloatAttr>() || constAttr.isa<IntegerAttr>() ||
      constAttr.isa<BoolAttr>()) {
    // Scalar constant operations will be handle by getName method.
    return;
  } else if (constAttr.isa<DenseElementsAttr>()) {
    indent();
    emitValue(op->getResult());
    os << " = ";
    if (op->getType().isa<TensorType>())
      emitCppArray<TensorType>(op);
    else
      emitCppArray<VectorType>(op);
    os << ";\n";
  } else
    emitError(*op, "has unsupported constant type.");
}

void ModuleEmitter::emitCall(CallOp *op) {
  // TODO
  return;
}

/// MLIR component emitters.
void ModuleEmitter::emitValue(Value val, bool isPtr) {
  // Value has been declared before or is a constant number.
  auto valName = getName(val);
  if (!valName.empty()) {
    os << valName;
    return;
  }

  // Handle memref, tensor, and vector types.
  auto valType = val.getType();
  if (auto memType = valType.dyn_cast<MemRefType>())
    valType = memType.getElementType();
  else if (auto tensorType = valType.dyn_cast<TensorType>())
    valType = tensorType.getElementType();
  else if (auto vectorType = valType.dyn_cast<VectorType>())
    valType = vectorType.getElementType();

  // Emit value type for declaring a new value.
  switch (valType.getKind()) {
  // Handle float types.
  case StandardTypes::F32:
    os << "float ";
    break;
  case StandardTypes::F64:
    os << "double ";
    break;

  // Handle integer types.
  case StandardTypes::Index:
    os << "int ";
    break;
  case StandardTypes::Integer: {
    auto intType = valType.cast<IntegerType>();
    os << "ap_";
    if (intType.getSignedness() == IntegerType::SignednessSemantics::Unsigned)
      os << "u";
    os << "int<" << intType.getWidth() << "> ";
    break;
  }
  default:
    emitError(val.getDefiningOp(), "has unsupported type.");
    break;
  }

  // Add the new value to nameTable and emit its name.
  os << addName(val, isPtr);
  return;
}

void ModuleEmitter::emitOperation(Operation *op) {
  if (ExprVisitor(*this).dispatchVisitor(op))
    return;

  if (StmtVisitor(*this).dispatchVisitor(op))
    return;

  emitError(op, "can't be correctly emitted.");
}

void ModuleEmitter::emitBlock(Block &block) {
  for (auto &op : block)
    emitOperation(&op);
}

void ModuleEmitter::emitFunction(FuncOp func) {
  if (func.getBlocks().size() != 1)
    emitError(func, "has more than one basic blocks.");
  os << "void " << func.getName() << "(\n";

  // Emit function signature.
  addIndent();

  // Handle input arguments.
  unsigned argIdx = 0;
  for (auto &arg : func.getArguments()) {
    indent();
    emitValue(arg);
    if (auto memType = arg.getType().dyn_cast<MemRefType>())
      for (auto &shape : memType.getShape())
        os << "[" << shape << "]";
    if (argIdx == func.getNumArguments() - 1 && func.getNumResults() == 0)
      os << "\n";
    else
      os << ",\n";
    argIdx += 1;
  }

  // Handle results.
  if (auto funcReturn = dyn_cast<ReturnOp>(func.front().getTerminator())) {
    unsigned resultIdx = 0;
    for (auto result : funcReturn.getOperands()) {
      indent();
      if (auto memType = result.getType().dyn_cast<MemRefType>()) {
        emitValue(result);
        for (auto &shape : memType.getShape())
          os << "[" << shape << "]";
      } else {
        // In Vivado HLS, pointer type indicates an output scalar value.
        emitValue(result, /*isPtr=*/true);
      }

      if (resultIdx == func.getNumResults() - 1)
        os << "\n";
      else
        os << ",\n";
      resultIdx += 1;
    }
  } else {
    emitError(func, "doesn't have return operation as terminator.");
  }

  reduceIndent();
  os << ") {\n";

  // Emit function body.
  addIndent();
  emitBlock(func.front());
  reduceIndent();
  os << "}\n";
}

/// Top-level MLIR module emitter.
void ModuleEmitter::emitModule(ModuleOp module) {
  os << R"XXX(
//===------------------------------------------------------------*- C++ -*-===//
//
// Automatically generated file for High-level Synthesis (HLS).
//
//===----------------------------------------------------------------------===//

#include <algorithm>
#include <ap_axi_sdata.h>
#include <ap_fixed.h>
#include <ap_int.h>
#include <hls_math.h>
#include <hls_stream.h>
#include <math.h>
#include <stdint.h>

using namespace std;

)XXX";

  for (auto &op : *module.getBody()) {
    if (auto func = dyn_cast<FuncOp>(op))
      emitFunction(func);
    else if (!isa<ModuleTerminatorOp>(op))
      emitError(&op, "is unsupported operation.");
  }
}

//===----------------------------------------------------------------------===//
// Entry of hlsld-translate
//===----------------------------------------------------------------------===//

static LogicalResult emitHLSCpp(ModuleOp module, llvm::raw_ostream &os) {
  HLSCppEmitterState state(os);
  ModuleEmitter(state).emitModule(module);
  return failure(state.encounteredError);
}

void hlsld::registerHLSCppEmitterTranslation() {
  static TranslateFromMLIRRegistration toHLSCpp("emit-hlscpp", emitHLSCpp);
}
