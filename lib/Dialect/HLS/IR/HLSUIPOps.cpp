//===----------------------------------------------------------------------===//
//
// Copyright 2020-2021 The ScaleHLS Authors.
//
//===----------------------------------------------------------------------===//

#include "scalehls/Dialect/HLS/Utils/Utils.h"

using namespace mlir;
using namespace scalehls;
using namespace hls;

//===----------------------------------------------------------------------===//
// DeclareOp
//===----------------------------------------------------------------------===//

LibraryOp DeclareOp::getLibraryOp() {
  return cast<LibraryOp>((*this)->getParentOp());
}
SemanticsOp DeclareOp::getSemanticsOp() {
  return cast<SemanticsOp>(getMeta().front().getTerminator());
}

//===----------------------------------------------------------------------===//
// InstanceOp
//===----------------------------------------------------------------------===//

LogicalResult InstanceOp::verifySymbolUses(mlir::SymbolTableCollection &table) {
  auto param = table.lookupNearestSymbolFrom<DeclareOp>(
      (*this)->getParentOfType<ModuleOp>(), getIpAttr());
  if (!param)
    return (*this)->emitOpError("unknown IP name ") << getIpAttr();
  return success(param);
}

//===----------------------------------------------------------------------===//
// SemanticsOp
//===----------------------------------------------------------------------===//

/// Initialize the block arguments. We create a tensor for each input and
/// output. The tensor type is determined by the corresponding port type.
void SemanticsOp::initializeBlockArguments() {
  SmallVector<Type> argTypes;
  SmallVector<Location> argLocs;

  auto appendTypesAndLocs = [&](ValueRange values) {
    for (auto value : values) {
      auto port = value.getDefiningOp<PortOp>();
      assert(port && "invalid semantics input/output");
      auto tensorType = RankedTensorType::get(
          SmallVector<int64_t>(port.getSizes().size(), ShapedType::kDynamic),
          /*port.getType().getType()*/ Builder(*this).getF32Type(), nullptr);
      argTypes.push_back(tensorType);
      argLocs.push_back(port.getLoc());
    }
  };
  appendTypesAndLocs(getInputs());
  appendTypesAndLocs(getOutputs());

  if (getBody().empty())
    getBody().emplaceBlock();
  getBody().addArguments(argTypes, argLocs);
}

/// Get the immediate included linalg op. Will return nullptr if there is no
/// such linalg op or more than one linalg op.
linalg::LinalgOp SemanticsOp::getSemanticsLinalgOp() {
  auto linalgOps = getOps<linalg::LinalgOp>();
  if (llvm::hasSingleElement(linalgOps))
    return *linalgOps.begin();
  return nullptr;
}

DeclareOp SemanticsOp::getDeclareOp() {
  return cast<DeclareOp>((*this)->getParentOp());
}
SemanticsOutputOp SemanticsOp::getSemanticsOutputOp() {
  return cast<SemanticsOutputOp>(getBody().front().getTerminator());
}

//===----------------------------------------------------------------------===//
// SemanticsOutputOp
//===----------------------------------------------------------------------===//

SemanticsOp SemanticsOutputOp::getSemanticsOp() {
  return cast<SemanticsOp>((*this)->getParentOp());
}