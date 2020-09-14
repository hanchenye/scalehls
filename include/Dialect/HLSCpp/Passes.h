//===------------------------------------------------------------*- C++ -*-===//
//
//===----------------------------------------------------------------------===//

#ifndef SCALEHLS_DIALECT_HLSCPP_PASSES_H
#define SCALEHLS_DIALECT_HLSCPP_PASSES_H

#include "mlir/Pass/Pass.h"
#include <memory>

namespace mlir {
class Pass;
} // namespace mlir

namespace mlir {
namespace scalehls {
namespace hlscpp {

std::unique_ptr<mlir::Pass> createPragmaInsertionPass();

void registerHLSCppPasses();

#define GEN_PASS_CLASSES
#include "Dialect/HLSCpp/HLSCppPasses.h.inc"

} // namespace hlscpp
} // namespace scalehls
} // namespace mlir

#endif // SCALEHLS_DIALECT_HLSCPP_PASSES_H