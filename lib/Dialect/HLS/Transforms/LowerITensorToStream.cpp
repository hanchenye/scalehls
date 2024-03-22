//===----------------------------------------------------------------------===//
//
// Copyright 2020-2021 The ScaleHLS Authors.
//
//===----------------------------------------------------------------------===//

#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "scalehls/Dialect/HLS/Transforms/Passes.h"

using namespace mlir;
using namespace scalehls;
using namespace hls;

static StreamType getStreamType(hls::ITensorType iTensorType) {
  return hls::StreamType::get(iTensorType.getDataType(),
                              iTensorType.getDepth());
}

namespace {
struct LowerITensorReadOp : public OpRewritePattern<hls::ITensorReadOp> {
  using OpRewritePattern<hls::ITensorReadOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(hls::ITensorReadOp read,
                                PatternRewriter &rewriter) const override {
    auto streamType = getStreamType(read.getSourceType());
    auto stream = rewriter.create<hls::ITensorToStreamOp>(
        read.getLoc(), streamType, read.getSource());
    rewriter.replaceOpWithNewOp<hls::StreamReadOp>(read, read.getType(),
                                                   stream);
    return success();
  }
};
} // namespace

namespace {
struct LowerITensorWriteOp : public OpRewritePattern<hls::ITensorWriteOp> {
  using OpRewritePattern<hls::ITensorWriteOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(hls::ITensorWriteOp write,
                                PatternRewriter &rewriter) const override {
    auto stream = rewriter.create<hls::ITensorToStreamOp>(
        write.getLoc(), getStreamType(write.getDestType()), write.getDest());
    rewriter.create<hls::StreamWriteOp>(write.getLoc(), write.getValue(),
                                        stream);
    auto replacement = rewriter.create<hls::StreamToITensorOp>(
        write.getLoc(), write.getResultType(), stream);
    rewriter.replaceOp(write, replacement);
    return success();
  }
};
} // namespace

namespace {
struct LowerITensorViewLikeOpInterface
    : public OpInterfaceRewritePattern<hls::ITensorViewLikeOpInterface> {
  using OpInterfaceRewritePattern<
      hls::ITensorViewLikeOpInterface>::OpInterfaceRewritePattern;

  LogicalResult matchAndRewrite(hls::ITensorViewLikeOpInterface view,
                                PatternRewriter &rewriter) const override {
    auto stream = rewriter.create<hls::ITensorToStreamOp>(
        view.getLoc(), getStreamType(view.getResultType()), view.getSource());
    auto replacement = rewriter.create<hls::StreamToITensorOp>(
        view.getLoc(), view.getResultType(), stream);
    rewriter.replaceOp(view, replacement);
    return success();
  }
};
} // namespace

namespace {
struct LowerForOp : public OpRewritePattern<scf::ForOp> {
  using OpRewritePattern<scf::ForOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(scf::ForOp loop,
                                PatternRewriter &rewriter) const override {
    bool hasChanged = false;

    for (auto [initArg, iterArg, yieldedValue, result] :
         llvm::zip(loop.getInitArgs(), loop.getRegionIterArgs(),
                   loop.getYieldedValues(), loop.getResults())) {
      auto iTensorType = dyn_cast<ITensorType>(result.getType());
      if (iTensorType && iterArg != yieldedValue && !iterArg.use_empty()) {
        hasChanged = true;
        auto streamType = getStreamType(iTensorType);

        rewriter.setInsertionPoint(loop);
        auto stream = rewriter.create<hls::ITensorToStreamOp>(
            loop.getLoc(), streamType, initArg);

        rewriter.setInsertionPointToStart(loop.getBody());
        auto iterArgRepl = rewriter.create<hls::StreamToITensorOp>(
            loop.getLoc(), iTensorType, stream);
        rewriter.replaceAllUsesWith(iterArg, iterArgRepl);

        rewriter.setInsertionPointAfter(loop);
        auto resultRepl = rewriter.create<hls::StreamToITensorOp>(
            loop.getLoc(), iTensorType, stream);
        rewriter.replaceAllUsesWith(result, resultRepl);
      }
    }
    return success(hasChanged);
  }
};
} // namespace

namespace {
struct RemoveITensorToStreamOp
    : public OpRewritePattern<hls::ITensorToStreamOp> {
  using OpRewritePattern<hls::ITensorToStreamOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(hls::ITensorToStreamOp toStream,
                                PatternRewriter &rewriter) const override {
    if (toStream.use_empty()) {
      rewriter.eraseOp(toStream);
      return success();
    }

    if (auto init = toStream.getITensor().getDefiningOp<hls::ITensorInitOp>()) {
      if (!init.getInitValue()) {
        rewriter.replaceOpWithNewOp<hls::StreamOp>(toStream,
                                                   toStream.getStreamType());
        return success();
      }
    } else if (auto toITensor = toStream.getITensor()
                                    .getDefiningOp<hls::StreamToITensorOp>()) {
      if (toStream.getStreamType() == toITensor.getStreamType()) {
        rewriter.replaceOp(toStream, toITensor.getStream());
        return success();
      }
    }
    return failure();
  }
};
} // namespace

namespace {
struct RemoveStreamToITensorOp
    : public OpRewritePattern<hls::StreamToITensorOp> {
  using OpRewritePattern<hls::StreamToITensorOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(hls::StreamToITensorOp toITensor,
                                PatternRewriter &rewriter) const override {
    if (toITensor.use_empty()) {
      rewriter.eraseOp(toITensor);
      return success();
    }
    return failure();
  }
};
} // namespace

namespace {
struct DuplicateStreamOp : public OpRewritePattern<hls::StreamOp> {
  using OpRewritePattern<hls::StreamOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(hls::StreamOp stream,
                                PatternRewriter &rewriter) const override {
    auto writeUses = stream.getWriteUses();
    if (writeUses.size() != 1)
      return failure();
    auto writer = stream.getWriter();

    bool hasChanged = false;
    for (auto use : llvm::drop_begin(stream.getReadUses())) {
      hasChanged = true;
      rewriter.setInsertionPoint(stream);
      auto newStream =
          rewriter.create<hls::StreamOp>(stream.getLoc(), stream.getType());
      rewriter.setInsertionPoint(writer);
      rewriter.create<hls::StreamWriteOp>(writer.getLoc(), writer.getValue(),
                                          newStream);
      rewriter.updateRootInPlace(use->getOwner(),
                                 [&]() { use->set(newStream); });
    }
    return success(hasChanged);
  }
};
} // namespace

namespace {
struct LowerITensorToStream
    : public LowerITensorToStreamBase<LowerITensorToStream> {
  void runOnOperation() override {
    auto op = getOperation();
    auto context = op->getContext();

    mlir::RewritePatternSet patterns(context);
    patterns.add<LowerITensorReadOp>(context);
    patterns.add<LowerITensorWriteOp>(context);
    patterns.add<LowerITensorViewLikeOpInterface>(context);
    patterns.add<LowerForOp>(context);
    scf::ForOp::getCanonicalizationPatterns(patterns, context);
    patterns.add<RemoveITensorToStreamOp>(context);
    patterns.add<RemoveStreamToITensorOp>(context);
    patterns.add<DuplicateStreamOp>(context);
    (void)applyPatternsAndFoldGreedily(op, std::move(patterns));
  }
};
} // namespace

std::unique_ptr<Pass> scalehls::hls::createLowerITensorToStreamPass() {
  return std::make_unique<LowerITensorToStream>();
}