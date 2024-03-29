// RUN: scalehls-opt -scalehls-create-axi-interface %s | FileCheck %s

// CHECK: #map = affine_map<(d0) -> (d0 mod 100)>
// CHECK: #map1 = affine_map<(d0) -> (d0 floordiv 100)>
// CHECK: #map2 = affine_map<(d0) -> (d0 mod 4)>
// CHECK: #map3 = affine_map<(d0) -> ((d0 floordiv 4) mod 2)>
// CHECK: #map4 = affine_map<(d0) -> ((d0 floordiv 4) floordiv 2)>
// CHECK: #map5 = affine_map<(d0) -> (d0 mod 2)>
// CHECK: #map6 = affine_map<(d0) -> ((d0 floordiv 2) mod 2)>
// CHECK: #map7 = affine_map<(d0) -> (((d0 floordiv 2) floordiv 2) mod 4)>
// CHECK: #map8 = affine_map<(d0) -> (((d0 floordiv 2) floordiv 2) floordiv 4)>
// CHECK: #map9 = affine_map<(d0) -> ((((d0 floordiv 2) floordiv 2) floordiv 4) mod 3)>
// CHECK: #map10 = affine_map<(d0) -> (((((d0 floordiv 2) floordiv 2) floordiv 4) floordiv 3) mod 3)>
// CHECK: #map11 = affine_map<(d0) -> (((((d0 floordiv 2) floordiv 2) floordiv 4) floordiv 3) floordiv 3)>
// CHECK: #map12 = affine_map<(d0) -> ((d0 floordiv 4) mod 4)>
// CHECK: #map13 = affine_map<(d0) -> ((d0 floordiv 4) floordiv 4)>
// CHECK: #set = affine_set<(d0) : (d0 == 0)>
// CHECK: #set1 = affine_set<(d0, d1) : (d0 + d1 * 16 == 0)>
// CHECK: #set2 = affine_set<(d0, d1, d2, d3) : (-d0 - d2 * 14 + 27 == 0, -d1 - d3 * 14 + 27 == 0)>
// CHECK: #set3 = affine_set<(d0)[s0] : (-d0 - s0 * 16 + 63 == 0)>
// CHECK: #set4 = affine_set<(d0, d1, d2, d3) : (-d2 - d3 * 16 + 63 == 0, -d0 + 2 == 0, -d1 + 2 == 0)>
// CHECK: module attributes {torch.debug_module_name = "ResNet"} {
// CHECK:   func.func @forward_node1(%arg0: memref<10xi8, 7>, %arg1: memref<1000xi8, 12>, %arg2: index) attributes {inline} {
// CHECK:     affine.for %arg3 = 0 to 10 {
// CHECK:       %0 = affine.load %arg0[%arg3] : memref<10xi8, 7>
// CHECK:       affine.store %0, %arg1[%arg3 + symbol(%arg2) * 10] : memref<1000xi8, 12>
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node2(%arg0: memref<64xi8, 7>, %arg1: memref<10x16xi8, 7>, %arg2: memref<10xi8, 7>, %arg3: memref<10xi8, 7>, %arg4: index) attributes {inline} {
// CHECK:     %c-24_i8 = arith.constant -24 : i8
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 10 {
// CHECK:         %0 = affine.load %arg2[%arg6] : memref<10xi8, 7>
// CHECK:         %1 = affine.load %arg3[%arg6] : memref<10xi8, 7>
// CHECK:         %2 = hls.affine.select #set(%arg5) %0, %1 : i8
// CHECK:         %3 = hls.affine.select #set1(%arg5, %arg4) %c-24_i8, %2 : i8
// CHECK:         %4 = affine.load %arg0[%arg5 + symbol(%arg4) * 16] : memref<64xi8, 7>
// CHECK:         %5 = affine.load %arg1[%arg6, %arg5] : memref<10x16xi8, 7>
// CHECK:         %6 = arith.muli %4, %5 : i8
// CHECK:         %7 = arith.addi %3, %6 : i8
// CHECK:         affine.store %7, %arg3[%arg6] : memref<10xi8, 7>
// CHECK:       } {parallel, point}
// CHECK:     } {point}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node3(%arg0: memref<1000x64xi8, 12>, %arg1: memref<10x16xi8, 7>, %arg2: index, %arg3: index) attributes {inline} {
// CHECK:     affine.for %arg4 = 0 to 10 {
// CHECK:       affine.for %arg5 = 0 to 16 {
// CHECK:         %0 = affine.load %arg0[%arg4 + symbol(%arg2) * 10, %arg5 + symbol(%arg3) * 16] : memref<1000x64xi8, 12>
// CHECK:         affine.store %0, %arg1[%arg4, %arg5] : memref<10x16xi8, 7>
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node4(%arg0: memref<1000xi8, 12>, %arg1: memref<10xi8, 7>, %arg2: index) attributes {inline} {
// CHECK:     affine.for %arg3 = 0 to 10 {
// CHECK:       %0 = affine.load %arg0[%arg3 + symbol(%arg2) * 10] : memref<1000xi8, 12>
// CHECK:       affine.store %0, %arg1[%arg3] : memref<10xi8, 7>
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node0(%arg0: memref<64xi8, 7>, %arg1: memref<1000x64xi8, 12>, %arg2: memref<1000xi8, 12>, %arg3: memref<1000xi8, 12>) {
// CHECK:     affine.for %arg4 = 0 to 400 {
// CHECK:       %0 = affine.apply #map(%arg4)
// CHECK:       %1 = affine.apply #map1(%arg4)
// CHECK:       %2 = hls.dataflow.buffer {depth = 1 : i32} : memref<10x16xi8, 7>
// CHECK:       %3 = hls.dataflow.buffer {depth = 1 : i32} : memref<10xi8, 7>
// CHECK:       func.call @forward_node4(%arg2, %3, %0) : (memref<1000xi8, 12>, memref<10xi8, 7>, index) -> ()
// CHECK:       func.call @forward_node3(%arg1, %2, %0, %1) : (memref<1000x64xi8, 12>, memref<10x16xi8, 7>, index, index) -> ()
// CHECK:       %4 = hls.dataflow.buffer {depth = 1 : i32} : memref<10xi8, 7>
// CHECK:       func.call @forward_node2(%arg0, %2, %3, %4, %1) : (memref<64xi8, 7>, memref<10x16xi8, 7>, memref<10xi8, 7>, memref<10xi8, 7>, index) -> ()
// CHECK:       func.call @forward_node1(%4, %arg3, %0) : (memref<10xi8, 7>, memref<1000xi8, 12>, index) -> ()
// CHECK:     } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node6(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     %c-24_i8 = arith.constant -24 : i8
// CHECK:     affine.for %arg5 = 0 to 14 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 16 {
// CHECK:           %0 = affine.load %arg0[%arg7, %arg5, %arg6] : memref<16x14x14xi8, 7>
// CHECK:           %1 = affine.load %arg1[%arg7 + symbol(%arg2) * 16] : memref<64xi8, 7>
// CHECK:           %2 = arith.addi %1, %0 : i8
// CHECK:           %3 = arith.divui %2, %c-24_i8 : i8
// CHECK:           %4 = hls.affine.select #set2(%arg5, %arg6, %arg3, %arg4) %3, %2 : i8
// CHECK:           affine.store %4, %arg1[%arg7 + symbol(%arg2) * 16] : memref<64xi8, 7>
// CHECK:         } {parallel, point}
// CHECK:       } {point}
// CHECK:     } {point}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node7(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node5(%arg0: !hls.stream<i1, 1>, %arg1: memref<64x28x28xi8, 12>, %arg2: memref<64xi8, 7>) {
// CHECK:     hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 1>) -> ()
// CHECK:     affine.for %arg3 = 0 to 16 {
// CHECK:       %0 = affine.apply #map2(%arg3)
// CHECK:       %1 = affine.apply #map3(%arg3)
// CHECK:       %2 = affine.apply #map4(%arg3)
// CHECK:       %3 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node7(%arg1, %3, %0, %2, %1) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       func.call @forward_node6(%3, %arg2, %0, %2, %1) : (memref<16x14x14xi8, 7>, memref<64xi8, 7>, index, index, index) -> ()
// CHECK:     } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node9(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node10(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node11(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x14x14xi8, 7>, %arg2: memref<16x16xi8, 7>, %arg3: memref<16x14x14xi8, 7>, %arg4: memref<16x14x14xi8, 7>, %arg5: memref<16x14x14xi8, 7>, %arg6: index) attributes {inline} {
// CHECK:     %c-24_i8 = arith.constant -24 : i8
// CHECK:     affine.for %arg7 = 0 to 16 {
// CHECK:       affine.for %arg8 = 0 to 16 {
// CHECK:         affine.for %arg9 = 0 to 14 {
// CHECK:           affine.for %arg10 = 0 to 14 {
// CHECK:             %0 = affine.load %arg1[%arg7, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %1 = affine.load %arg2[%arg8, %arg7] : memref<16x16xi8, 7>
// CHECK:             %2 = affine.load %arg3[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %3 = affine.load %arg5[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %4 = hls.affine.select #set(%arg7) %2, %3 : i8
// CHECK:             %5 = arith.muli %0, %1 : i8
// CHECK:             %6 = arith.addi %4, %5 : i8
// CHECK:             affine.store %6, %arg5[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %7 = affine.load %arg0[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %8 = arith.addi %7, %6 : i8
// CHECK:             %9 = arith.cmpi ugt, %8, %c-24_i8 : i8
// CHECK:             %10 = arith.select %9, %8, %c-24_i8 : i8
// CHECK:             affine.if #set3(%arg7)[%arg6] {
// CHECK:               affine.store %10, %arg4[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             }
// CHECK:           } {parallel, point}
// CHECK:         } {parallel, point}
// CHECK:       } {parallel, point}
// CHECK:     } {point}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node12(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node13(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node14(%arg0: memref<64x64xi8, 12>, %arg1: memref<16x16xi8, 7>, %arg2: index, %arg3: index) attributes {inline} {
// CHECK:     affine.for %arg4 = 0 to 16 {
// CHECK:       affine.for %arg5 = 0 to 16 {
// CHECK:         %0 = affine.load %arg0[%arg4 + symbol(%arg2) * 16, %arg5 + symbol(%arg3) * 16] : memref<64x64xi8, 12>
// CHECK:         affine.store %0, %arg1[%arg4, %arg5] : memref<16x16xi8, 7>
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node15(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 * 2 + symbol(%arg3) * 28, %arg7 * 2 + symbol(%arg4) * 28] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node8(%arg0: !hls.stream<i1, 3>, %arg1: memref<64x56x56xi8, 12>, %arg2: memref<64x64xi8, 12>, %arg3: !hls.stream<i1, 1>, %arg4: memref<64x28x28xi8, 12>, %arg5: memref<64x28x28xi8, 12>, %arg6: !hls.stream<i1, 1>, %arg7: memref<64x28x28xi8, 12>, %arg8: memref<64x28x28xi8, 12>) {
// CHECK:     %true = arith.constant true
// CHECK:     hls.dataflow.stream_read %arg3 : (!hls.stream<i1, 1>) -> ()
// CHECK:     hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 3>) -> ()
// CHECK:     affine.for %arg9 = 0 to 64 {
// CHECK:       %0 = affine.apply #map5(%arg9)
// CHECK:       %1 = affine.apply #map6(%arg9)
// CHECK:       %2 = affine.apply #map7(%arg9)
// CHECK:       %3 = affine.apply #map8(%arg9)
// CHECK:       %4 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       %5 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
// CHECK:       %6 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
// CHECK:       %7 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x16xi8, 7>
// CHECK:       %8 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node15(%arg1, %8, %3, %1, %0) : (memref<64x56x56xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       func.call @forward_node14(%arg2, %7, %2, %3) : (memref<64x64xi8, 12>, memref<16x16xi8, 7>, index, index) -> ()
// CHECK:       func.call @forward_node13(%arg5, %6, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       func.call @forward_node12(%arg4, %5, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       %9 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node11(%5, %8, %7, %6, %4, %9, %3) : (memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, memref<16x16xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, index) -> ()
// CHECK:       func.call @forward_node10(%9, %arg8, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
// CHECK:       func.call @forward_node9(%4, %arg7, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
// CHECK:     } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
// CHECK:     hls.dataflow.stream_write %arg6, %true : <i1, 1>, i1
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node17(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 step 2 {
// CHECK:         affine.for %arg7 = 0 to 14 step 2 {
// CHECK:           %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           %1 = affine.load %arg0[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %1, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:           %2 = affine.load %arg0[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %2, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           %3 = affine.load %arg0[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %3, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node18(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x16xi8, 7>, %arg2: memref<16x14x14xi8, 7>, %arg3: memref<16x14x14xi8, 7>) attributes {inline} {
// CHECK:     affine.for %arg4 = 0 to 16 {
// CHECK:       affine.for %arg5 = 0 to 16 {
// CHECK:         affine.for %arg6 = 0 to 14 step 2 {
// CHECK:           affine.for %arg7 = 0 to 14 step 2 {
// CHECK:             %0 = affine.load %arg0[%arg4, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %1 = affine.load %arg1[%arg5, %arg4] : memref<16x16xi8, 7>
// CHECK:             %2 = affine.load %arg2[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %3 = affine.load %arg3[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %4 = hls.affine.select #set(%arg4) %2, %3 : i8
// CHECK:             %5 = arith.muli %0, %1 : i8
// CHECK:             %6 = arith.addi %4, %5 : i8
// CHECK:             affine.store %6, %arg3[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %7 = affine.load %arg0[%arg4, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %8 = affine.load %arg2[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %9 = affine.load %arg3[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %10 = hls.affine.select #set(%arg4) %8, %9 : i8
// CHECK:             %11 = arith.muli %7, %1 : i8
// CHECK:             %12 = arith.addi %10, %11 : i8
// CHECK:             affine.store %12, %arg3[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %13 = affine.load %arg0[%arg4, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %14 = affine.load %arg2[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %15 = affine.load %arg3[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %16 = hls.affine.select #set(%arg4) %14, %15 : i8
// CHECK:             %17 = arith.muli %13, %1 : i8
// CHECK:             %18 = arith.addi %16, %17 : i8
// CHECK:             affine.store %18, %arg3[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:             %19 = affine.load %arg0[%arg4, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %20 = affine.load %arg2[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %21 = affine.load %arg3[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %22 = hls.affine.select #set(%arg4) %20, %21 : i8
// CHECK:             %23 = arith.muli %19, %1 : i8
// CHECK:             %24 = arith.addi %22, %23 : i8
// CHECK:             affine.store %24, %arg3[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:           } {parallel, point}
// CHECK:         } {parallel, point}
// CHECK:       } {parallel, point}
// CHECK:     } {point}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node19(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 step 2 {
// CHECK:         affine.for %arg7 = 0 to 14 step 2 {
// CHECK:           %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           %1 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %1, %arg1[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:           %2 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %2, %arg1[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           %3 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %3, %arg1[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node20(%arg0: memref<64x64x3x3xi8, 12>, %arg1: memref<16x16xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index) attributes {inline} {
// CHECK:     affine.for %arg6 = 0 to 16 {
// CHECK:       affine.for %arg7 = 0 to 16 {
// CHECK:         %0 = affine.load %arg0[%arg6 + symbol(%arg2) * 16, %arg7 + symbol(%arg3) * 16, symbol(%arg4), symbol(%arg5)] : memref<64x64x3x3xi8, 12>
// CHECK:         affine.store %0, %arg1[%arg6, %arg7] : memref<16x16xi8, 7>
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node21(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index, %arg6: index) attributes {inline} {
// CHECK:     affine.for %arg7 = 0 to 16 {
// CHECK:       affine.for %arg8 = 0 to 14 step 2 {
// CHECK:         affine.for %arg9 = 0 to 14 step 2 {
// CHECK:           %0 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14 - 1, %arg9 + symbol(%arg5) + symbol(%arg6) * 14 - 1] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg7, %arg8, %arg9] : memref<16x14x14xi8, 7>
// CHECK:           %1 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14 - 1, %arg9 + symbol(%arg5) + symbol(%arg6) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %1, %arg1[%arg7, %arg8, %arg9 + 1] : memref<16x14x14xi8, 7>
// CHECK:           %2 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14, %arg9 + symbol(%arg5) + symbol(%arg6) * 14 - 1] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %2, %arg1[%arg7, %arg8 + 1, %arg9] : memref<16x14x14xi8, 7>
// CHECK:           %3 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14, %arg9 + symbol(%arg5) + symbol(%arg6) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %3, %arg1[%arg7, %arg8 + 1, %arg9 + 1] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node16(%arg0: memref<64x64x3x3xi8, 12>, %arg1: !hls.stream<i1, 1>, %arg2: memref<64x28x28xi8, 12>, %arg3: memref<64x28x28xi8, 12>, %arg4: !hls.stream<i1, 1>, %arg5: memref<64x28x28xi8, 12>) {
// CHECK:     %true = arith.constant true
// CHECK:     hls.dataflow.stream_read %arg1 : (!hls.stream<i1, 1>) -> ()
// CHECK:     affine.for %arg6 = 0 to 576 {
// CHECK:       %0 = affine.apply #map5(%arg6)
// CHECK:       %1 = affine.apply #map6(%arg6)
// CHECK:       %2 = affine.apply #map7(%arg6)
// CHECK:       %3 = affine.apply #map9(%arg6)
// CHECK:       %4 = affine.apply #map10(%arg6)
// CHECK:       %5 = affine.apply #map11(%arg6)
// CHECK:       %6 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
// CHECK:       %7 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x16xi8, 7>
// CHECK:       %8 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node21(%arg2, %8, %5, %4, %1, %3, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index, index, index) -> ()
// CHECK:       func.call @forward_node20(%arg0, %7, %2, %5, %4, %3) : (memref<64x64x3x3xi8, 12>, memref<16x16xi8, 7>, index, index, index, index) -> ()
// CHECK:       func.call @forward_node19(%arg3, %6, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       %9 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node18(%8, %7, %6, %9) : (memref<16x14x14xi8, 7>, memref<16x16xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>) -> ()
// CHECK:       func.call @forward_node17(%9, %arg5, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
// CHECK:     } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
// CHECK:     hls.dataflow.stream_write %arg4, %true : <i1, 1>, i1
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node23(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 step 2 {
// CHECK:         affine.for %arg7 = 0 to 14 step 2 {
// CHECK:           %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           %1 = affine.load %arg0[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %1, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:           %2 = affine.load %arg0[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %2, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           %3 = affine.load %arg0[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %3, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node24(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x16xi8, 7>, %arg2: memref<16x14x14xi8, 7>, %arg3: memref<16x14x14xi8, 7>, %arg4: index, %arg5: index, %arg6: index) attributes {inline} {
// CHECK:     %c-24_i8 = arith.constant -24 : i8
// CHECK:     affine.for %arg7 = 0 to 16 {
// CHECK:       affine.for %arg8 = 0 to 16 {
// CHECK:         affine.for %arg9 = 0 to 14 step 2 {
// CHECK:           affine.for %arg10 = 0 to 14 step 2 {
// CHECK:             %0 = affine.load %arg0[%arg7, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %1 = affine.load %arg1[%arg8, %arg7] : memref<16x16xi8, 7>
// CHECK:             %2 = affine.load %arg2[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %3 = affine.load %arg3[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %4 = hls.affine.select #set(%arg7) %2, %3 : i8
// CHECK:             %5 = arith.muli %0, %1 : i8
// CHECK:             %6 = arith.addi %4, %5 : i8
// CHECK:             %7 = arith.cmpi ugt, %6, %c-24_i8 : i8
// CHECK:             %8 = arith.select %7, %6, %c-24_i8 : i8
// CHECK:             %9 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %8, %6 : i8
// CHECK:             affine.store %9, %arg3[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %10 = affine.load %arg0[%arg7, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %11 = affine.load %arg2[%arg8, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %12 = affine.load %arg3[%arg8, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %13 = hls.affine.select #set(%arg7) %11, %12 : i8
// CHECK:             %14 = arith.muli %10, %1 : i8
// CHECK:             %15 = arith.addi %13, %14 : i8
// CHECK:             %16 = arith.cmpi ugt, %15, %c-24_i8 : i8
// CHECK:             %17 = arith.select %16, %15, %c-24_i8 : i8
// CHECK:             %18 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %17, %15 : i8
// CHECK:             affine.store %18, %arg3[%arg8, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %19 = affine.load %arg0[%arg7, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %20 = affine.load %arg2[%arg8, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %21 = affine.load %arg3[%arg8, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %22 = hls.affine.select #set(%arg7) %20, %21 : i8
// CHECK:             %23 = arith.muli %19, %1 : i8
// CHECK:             %24 = arith.addi %22, %23 : i8
// CHECK:             %25 = arith.cmpi ugt, %24, %c-24_i8 : i8
// CHECK:             %26 = arith.select %25, %24, %c-24_i8 : i8
// CHECK:             %27 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %26, %24 : i8
// CHECK:             affine.store %27, %arg3[%arg8, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
// CHECK:             %28 = affine.load %arg0[%arg7, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %29 = affine.load %arg2[%arg8, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %30 = affine.load %arg3[%arg8, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:             %31 = hls.affine.select #set(%arg7) %29, %30 : i8
// CHECK:             %32 = arith.muli %28, %1 : i8
// CHECK:             %33 = arith.addi %31, %32 : i8
// CHECK:             %34 = arith.cmpi ugt, %33, %c-24_i8 : i8
// CHECK:             %35 = arith.select %34, %33, %c-24_i8 : i8
// CHECK:             %36 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %35, %33 : i8
// CHECK:             affine.store %36, %arg3[%arg8, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
// CHECK:           } {parallel, point}
// CHECK:         } {parallel, point}
// CHECK:       } {parallel, point}
// CHECK:     } {point}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node25(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 step 2 {
// CHECK:         affine.for %arg7 = 0 to 14 step 2 {
// CHECK:           %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           %1 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %1, %arg1[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:           %2 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %2, %arg1[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           %3 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
// CHECK:           affine.store %3, %arg1[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node26(%arg0: memref<64x64x3x3xi8, 12>, %arg1: memref<16x16xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index) attributes {inline} {
// CHECK:     affine.for %arg6 = 0 to 16 {
// CHECK:       affine.for %arg7 = 0 to 16 {
// CHECK:         %0 = affine.load %arg0[%arg6 + symbol(%arg2) * 16, %arg7 + symbol(%arg3) * 16, symbol(%arg4), symbol(%arg5)] : memref<64x64x3x3xi8, 12>
// CHECK:         affine.store %0, %arg1[%arg6, %arg7] : memref<16x16xi8, 7>
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node27(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index, %arg6: index) attributes {inline} {
// CHECK:     affine.for %arg7 = 0 to 16 {
// CHECK:       affine.for %arg8 = 0 to 14 step 2 {
// CHECK:         affine.for %arg9 = 0 to 14 step 2 {
// CHECK:           %0 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 - 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 - 1] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg7, %arg8, %arg9] : memref<16x14x14xi8, 7>
// CHECK:           %1 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 - 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 + 1] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %1, %arg1[%arg7, %arg8, %arg9 + 1] : memref<16x14x14xi8, 7>
// CHECK:           %2 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 + 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 - 1] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %2, %arg1[%arg7, %arg8 + 1, %arg9] : memref<16x14x14xi8, 7>
// CHECK:           %3 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 + 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 + 1] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %3, %arg1[%arg7, %arg8 + 1, %arg9 + 1] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node22(%arg0: !hls.stream<i1, 1>, %arg1: memref<64x56x56xi8, 12>, %arg2: memref<64x64x3x3xi8, 12>, %arg3: memref<64x28x28xi8, 12>, %arg4: !hls.stream<i1, 1>, %arg5: memref<64x28x28xi8, 12>) {
// CHECK:     %true = arith.constant true
// CHECK:     hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 1>) -> ()
// CHECK:     affine.for %arg6 = 0 to 576 {
// CHECK:       %0 = affine.apply #map5(%arg6)
// CHECK:       %1 = affine.apply #map6(%arg6)
// CHECK:       %2 = affine.apply #map7(%arg6)
// CHECK:       %3 = affine.apply #map9(%arg6)
// CHECK:       %4 = affine.apply #map10(%arg6)
// CHECK:       %5 = affine.apply #map11(%arg6)
// CHECK:       %6 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
// CHECK:       %7 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x16xi8, 7>
// CHECK:       %8 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node27(%arg1, %8, %5, %4, %1, %3, %0) : (memref<64x56x56xi8, 12>, memref<16x14x14xi8, 7>, index, index, index, index, index) -> ()
// CHECK:       func.call @forward_node26(%arg2, %7, %2, %5, %4, %3) : (memref<64x64x3x3xi8, 12>, memref<16x16xi8, 7>, index, index, index, index) -> ()
// CHECK:       func.call @forward_node25(%arg3, %6, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       %9 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node24(%8, %7, %6, %9, %3, %5, %4) : (memref<16x14x14xi8, 7>, memref<16x16xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       func.call @forward_node23(%9, %arg5, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
// CHECK:     } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
// CHECK:     hls.dataflow.stream_write %arg4, %true : <i1, 1>, i1
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node28(%arg0: !hls.stream<i1, 1>, %arg1: memref<64x56x56xi8, 12>, %arg2: !hls.stream<i1, 3>, %arg3: memref<64x56x56xi8, 12>, %arg4: !hls.stream<i1, 1>, %arg5: memref<64x56x56xi8, 12>) {
// CHECK:     %true = arith.constant true
// CHECK:     hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 1>) -> ()
// CHECK:     affine.for %arg6 = 0 to 64 {
// CHECK:       affine.for %arg7 = 0 to 56 {
// CHECK:         affine.for %arg8 = 0 to 56 {
// CHECK:           %0 = affine.load %arg1[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %0, %arg3[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     affine.for %arg6 = 0 to 64 {
// CHECK:       affine.for %arg7 = 0 to 56 {
// CHECK:         affine.for %arg8 = 0 to 56 {
// CHECK:           %0 = affine.load %arg1[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %0, %arg5[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     hls.dataflow.stream_write %arg2, %true : <i1, 3>, i1
// CHECK:     hls.dataflow.stream_write %arg4, %true : <i1, 1>, i1
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node30(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x56x56xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:           affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x56x56xi8, 12>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node31(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x14x14xi8, 7>) attributes {inline} {
// CHECK:     %c-24_i8 = arith.constant -24 : i8
// CHECK:     affine.for %arg2 = 0 to 16 {
// CHECK:       affine.for %arg3 = 0 to 14 {
// CHECK:         affine.for %arg4 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg2, %arg3, %arg4] : memref<16x14x14xi8, 7>
// CHECK:           %1 = arith.cmpi ugt, %0, %c-24_i8 : i8
// CHECK:           %2 = arith.select %1, %0, %c-24_i8 : i8
// CHECK:           affine.store %2, %arg1[%arg2, %arg3, %arg4] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel, point}
// CHECK:       } {parallel, point}
// CHECK:     } {parallel, point}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node32(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
// CHECK:     affine.for %arg5 = 0 to 16 {
// CHECK:       affine.for %arg6 = 0 to 14 {
// CHECK:         affine.for %arg7 = 0 to 14 {
// CHECK:           %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x56x56xi8, 12>
// CHECK:           affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
// CHECK:         } {parallel}
// CHECK:       } {parallel}
// CHECK:     } {parallel}
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward_node29(%arg0: memref<64x56x56xi8, 12>, %arg1: !hls.stream<i1, 1>, %arg2: memref<64x56x56xi8, 12>) {
// CHECK:     %true = arith.constant true
// CHECK:     affine.for %arg3 = 0 to 64 {
// CHECK:       %0 = affine.apply #map2(%arg3)
// CHECK:       %1 = affine.apply #map12(%arg3)
// CHECK:       %2 = affine.apply #map13(%arg3)
// CHECK:       %3 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node32(%arg0, %3, %2, %1, %0) : (memref<64x56x56xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
// CHECK:       %4 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
// CHECK:       func.call @forward_node31(%3, %4) : (memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>) -> ()
// CHECK:       func.call @forward_node30(%4, %arg2, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x56x56xi8, 12>, index, index, index) -> ()
// CHECK:     } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>, parallel}
// CHECK:     hls.dataflow.stream_write %arg1, %true : <i1, 1>, i1
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @forward(%arg0: !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, %arg1: !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, %arg2: !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, %arg3: !hls.axi<memref<1000x64xi8, 12>, 0 : i32>, %arg4: !hls.axi<memref<64x64xi8, 12>, 0 : i32>, %arg5: !hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>, %arg6: !hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>, %arg7: !hls.axi<memref<1000xi8, 12>, 0 : i32>, %arg8: !hls.axi<memref<1000xi8, 12>, 0 : i32>, %arg9: !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, %arg10: !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, %arg11: !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, %arg12: !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, %arg13: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg14: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg15: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg16: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg17: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg18: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg19: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg20: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg21: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, %arg22: !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) attributes {func_directive = #hls.fd<pipeline=false, targetInterval=1, dataflow=true>, top_func} {
// CHECK:     %0 = hls.axi.bundle "axi22" : <0 : i32>
// CHECK:     %1 = hls.axi.port %0, %arg22 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %2 = hls.axi.bundle "axi21" : <0 : i32>
// CHECK:     %3 = hls.axi.port %2, %arg21 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %4 = hls.axi.bundle "axi20" : <0 : i32>
// CHECK:     %5 = hls.axi.port %4, %arg20 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %6 = hls.axi.bundle "axi19" : <0 : i32>
// CHECK:     %7 = hls.axi.port %6, %arg19 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %8 = hls.axi.bundle "axi18" : <0 : i32>
// CHECK:     %9 = hls.axi.port %8, %arg18 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %10 = hls.axi.bundle "axi17" : <0 : i32>
// CHECK:     %11 = hls.axi.port %10, %arg17 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %12 = hls.axi.bundle "axi16" : <0 : i32>
// CHECK:     %13 = hls.axi.port %12, %arg16 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %14 = hls.axi.bundle "axi15" : <0 : i32>
// CHECK:     %15 = hls.axi.port %14, %arg15 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %16 = hls.axi.bundle "axi14" : <0 : i32>
// CHECK:     %17 = hls.axi.port %16, %arg14 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %18 = hls.axi.bundle "axi13" : <0 : i32>
// CHECK:     %19 = hls.axi.port %18, %arg13 : <0 : i32>, (!hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> memref<64x28x28xi8, 12>
// CHECK:     %20 = hls.axi.bundle "axi12" : <0 : i32>
// CHECK:     %21 = hls.axi.port %20, %arg12 : <0 : i32>, (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>) -> memref<64x56x56xi8, 12>
// CHECK:     %22 = hls.axi.bundle "axi11" : <0 : i32>
// CHECK:     %23 = hls.axi.port %22, %arg11 : <0 : i32>, (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>) -> memref<64x56x56xi8, 12>
// CHECK:     %24 = hls.axi.bundle "axi10" : <0 : i32>
// CHECK:     %25 = hls.axi.port %24, %arg10 : <0 : i32>, (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>) -> memref<64x56x56xi8, 12>
// CHECK:     %26 = hls.axi.bundle "axi9" : <0 : i32>
// CHECK:     %27 = hls.axi.port %26, %arg9 : <0 : i32>, (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>) -> memref<64x56x56xi8, 12>
// CHECK:     %28 = hls.axi.bundle "axi8" : <0 : i32>
// CHECK:     %29 = hls.axi.port %28, %arg8 : <0 : i32>, (!hls.axi<memref<1000xi8, 12>, 0 : i32>) -> memref<1000xi8, 12>
// CHECK:     %30 = hls.axi.bundle "axi7" : <0 : i32>
// CHECK:     %31 = hls.axi.port %30, %arg7 : <0 : i32>, (!hls.axi<memref<1000xi8, 12>, 0 : i32>) -> memref<1000xi8, 12>
// CHECK:     %32 = hls.axi.bundle "axi6" : <0 : i32>
// CHECK:     %33 = hls.axi.port %32, %arg6 : <0 : i32>, (!hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>) -> memref<64x64x3x3xi8, 12>
// CHECK:     %34 = hls.axi.bundle "axi5" : <0 : i32>
// CHECK:     %35 = hls.axi.port %34, %arg5 : <0 : i32>, (!hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>) -> memref<64x64x3x3xi8, 12>
// CHECK:     %36 = hls.axi.bundle "axi4" : <0 : i32>
// CHECK:     %37 = hls.axi.port %36, %arg4 : <0 : i32>, (!hls.axi<memref<64x64xi8, 12>, 0 : i32>) -> memref<64x64xi8, 12>
// CHECK:     %38 = hls.axi.bundle "axi3" : <0 : i32>
// CHECK:     %39 = hls.axi.port %38, %arg3 : <0 : i32>, (!hls.axi<memref<1000x64xi8, 12>, 0 : i32>) -> memref<1000x64xi8, 12>
// CHECK:     %40 = hls.axi.bundle "axi2" : <0 : i32>
// CHECK:     %41 = hls.axi.port %40, %arg2 : <0 : i32>, (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>) -> memref<64x56x56xi8, 12>
// CHECK:     %42 = hls.axi.bundle "axi1" : <0 : i32>
// CHECK:     %43 = hls.axi.port %42, %arg1 : <0 : i32>, (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>) -> memref<64x56x56xi8, 12>
// CHECK:     %44 = hls.axi.bundle "axi0" : <0 : i32>
// CHECK:     %45 = hls.axi.port %44, %arg0 : <0 : i32>, (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>) -> memref<64x56x56xi8, 12>
// CHECK:     %46 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
// CHECK:     call @forward_node29(%45, %46, %43) : (memref<64x56x56xi8, 12>, !hls.stream<i1, 1>, memref<64x56x56xi8, 12>) -> ()
// CHECK:     %47 = hls.dataflow.stream {depth = 3 : i32} : <i1, 3>
// CHECK:     %48 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
// CHECK:     call @forward_node28(%46, %41, %47, %25, %48, %21) : (!hls.stream<i1, 1>, memref<64x56x56xi8, 12>, !hls.stream<i1, 3>, memref<64x56x56xi8, 12>, !hls.stream<i1, 1>, memref<64x56x56xi8, 12>) -> ()
// CHECK:     %49 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
// CHECK:     call @forward_node22(%48, %23, %33, %15, %49, %17) : (!hls.stream<i1, 1>, memref<64x56x56xi8, 12>, memref<64x64x3x3xi8, 12>, memref<64x28x28xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>) -> ()
// CHECK:     %50 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
// CHECK:     call @forward_node16(%35, %49, %19, %9, %50, %11) : (memref<64x64x3x3xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64x28x28xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>) -> ()
// CHECK:     %51 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
// CHECK:     call @forward_node8(%47, %27, %37, %50, %13, %1, %51, %5, %3) : (!hls.stream<i1, 3>, memref<64x56x56xi8, 12>, memref<64x64xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64x28x28xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64x28x28xi8, 12>) -> ()
// CHECK:     %52 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64xi8, 7>
// CHECK:     call @forward_node5(%51, %7, %52) : (!hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64xi8, 7>) -> ()
// CHECK:     call @forward_node0(%52, %39, %31, %29) : (memref<64xi8, 7>, memref<1000x64xi8, 12>, memref<1000xi8, 12>, memref<1000xi8, 12>) -> ()
// CHECK:     return
// CHECK:   }
// CHECK:   func.func @main(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<1000x64xi8, 12>, %arg2: memref<64x64xi8, 12>, %arg3: memref<64x64x3x3xi8, 12>, %arg4: memref<64x64x3x3xi8, 12>, %arg5: memref<1000xi8, 12>) attributes {runtime} {
// CHECK:     %0 = hls.dataflow.buffer {depth = 3 : i32} : memref<64x56x56xi8, 12>
// CHECK:     %1 = hls.dataflow.buffer {depth = 1 : i32} : memref<64x56x56xi8, 12>
// CHECK:     %2 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64x28x28xi8, 12>
// CHECK:     %3 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64x28x28xi8, 12>
// CHECK:     %4 = hls.dataflow.buffer {depth = 1 : i32} : memref<64x28x28xi8, 12>
// CHECK:     %5 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64x28x28xi8, 12>
// CHECK:     %6 = hls.axi.pack %arg0 : (memref<64x56x56xi8, 12>) -> !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>
// CHECK:     %7 = hls.axi.pack %arg0 : (memref<64x56x56xi8, 12>) -> !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>
// CHECK:     %8 = hls.axi.pack %arg0 : (memref<64x56x56xi8, 12>) -> !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>
// CHECK:     %9 = hls.axi.pack %arg1 : (memref<1000x64xi8, 12>) -> !hls.axi<memref<1000x64xi8, 12>, 0 : i32>
// CHECK:     %10 = hls.axi.pack %arg2 : (memref<64x64xi8, 12>) -> !hls.axi<memref<64x64xi8, 12>, 0 : i32>
// CHECK:     %11 = hls.axi.pack %arg3 : (memref<64x64x3x3xi8, 12>) -> !hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>
// CHECK:     %12 = hls.axi.pack %arg4 : (memref<64x64x3x3xi8, 12>) -> !hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>
// CHECK:     %13 = hls.axi.pack %arg5 : (memref<1000xi8, 12>) -> !hls.axi<memref<1000xi8, 12>, 0 : i32>
// CHECK:     %14 = hls.axi.pack %arg5 : (memref<1000xi8, 12>) -> !hls.axi<memref<1000xi8, 12>, 0 : i32>
// CHECK:     %15 = hls.axi.pack %0 : (memref<64x56x56xi8, 12>) -> !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>
// CHECK:     %16 = hls.axi.pack %0 : (memref<64x56x56xi8, 12>) -> !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>
// CHECK:     %17 = hls.axi.pack %1 : (memref<64x56x56xi8, 12>) -> !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>
// CHECK:     %18 = hls.axi.pack %1 : (memref<64x56x56xi8, 12>) -> !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>
// CHECK:     %19 = hls.axi.pack %2 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %20 = hls.axi.pack %2 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %21 = hls.axi.pack %2 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %22 = hls.axi.pack %3 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %23 = hls.axi.pack %3 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %24 = hls.axi.pack %3 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %25 = hls.axi.pack %4 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %26 = hls.axi.pack %4 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %27 = hls.axi.pack %5 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     %28 = hls.axi.pack %5 : (memref<64x28x28xi8, 12>) -> !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>
// CHECK:     call @forward(%6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17, %18, %19, %20, %21, %22, %23, %24, %25, %26, %27, %28) : (!hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, !hls.axi<memref<1000x64xi8, 12>, 0 : i32>, !hls.axi<memref<64x64xi8, 12>, 0 : i32>, !hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>, !hls.axi<memref<64x64x3x3xi8, 12>, 0 : i32>, !hls.axi<memref<1000xi8, 12>, 0 : i32>, !hls.axi<memref<1000xi8, 12>, 0 : i32>, !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, !hls.axi<memref<64x56x56xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>, !hls.axi<memref<64x28x28xi8, 12>, 0 : i32>) -> ()
// CHECK:     return
// CHECK:   }
// CHECK: }

#map = affine_map<(d0) -> (d0 mod 100)>
#map1 = affine_map<(d0) -> (d0 floordiv 100)>
#map2 = affine_map<(d0) -> (d0 mod 4)>
#map3 = affine_map<(d0) -> ((d0 floordiv 4) mod 2)>
#map4 = affine_map<(d0) -> ((d0 floordiv 4) floordiv 2)>
#map5 = affine_map<(d0) -> (d0 mod 2)>
#map6 = affine_map<(d0) -> ((d0 floordiv 2) mod 2)>
#map7 = affine_map<(d0) -> (((d0 floordiv 2) floordiv 2) mod 4)>
#map8 = affine_map<(d0) -> (((d0 floordiv 2) floordiv 2) floordiv 4)>
#map9 = affine_map<(d0) -> ((((d0 floordiv 2) floordiv 2) floordiv 4) mod 3)>
#map10 = affine_map<(d0) -> (((((d0 floordiv 2) floordiv 2) floordiv 4) floordiv 3) mod 3)>
#map11 = affine_map<(d0) -> (((((d0 floordiv 2) floordiv 2) floordiv 4) floordiv 3) floordiv 3)>
#map12 = affine_map<(d0) -> ((d0 floordiv 4) mod 4)>
#map13 = affine_map<(d0) -> ((d0 floordiv 4) floordiv 4)>
#set = affine_set<(d0) : (d0 == 0)>
#set1 = affine_set<(d0, d1) : (d0 + d1 * 16 == 0)>
#set2 = affine_set<(d0, d1, d2, d3) : (-d0 - d2 * 14 + 27 == 0, -d1 - d3 * 14 + 27 == 0)>
#set3 = affine_set<(d0)[s0] : (-d0 - s0 * 16 + 63 == 0)>
#set4 = affine_set<(d0, d1, d2, d3) : (-d2 - d3 * 16 + 63 == 0, -d0 + 2 == 0, -d1 + 2 == 0)>
module attributes {torch.debug_module_name = "ResNet"} {
  func.func @forward_node1(%arg0: memref<10xi8, 7>, %arg1: memref<1000xi8, 12>, %arg2: index) attributes {inline} {
    affine.for %arg3 = 0 to 10 {
      %0 = affine.load %arg0[%arg3] : memref<10xi8, 7>
      affine.store %0, %arg1[%arg3 + symbol(%arg2) * 10] : memref<1000xi8, 12>
    } {parallel}
    return
  }
  func.func @forward_node2(%arg0: memref<64xi8, 7>, %arg1: memref<10x16xi8, 7>, %arg2: memref<10xi8, 7>, %arg3: memref<10xi8, 7>, %arg4: index) attributes {inline} {
    %c-24_i8 = arith.constant -24 : i8
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 10 {
        %0 = affine.load %arg2[%arg6] : memref<10xi8, 7>
        %1 = affine.load %arg3[%arg6] : memref<10xi8, 7>
        %2 = hls.affine.select #set(%arg5) %0, %1 : i8
        %3 = hls.affine.select #set1(%arg5, %arg4) %c-24_i8, %2 : i8
        %4 = affine.load %arg0[%arg5 + symbol(%arg4) * 16] : memref<64xi8, 7>
        %5 = affine.load %arg1[%arg6, %arg5] : memref<10x16xi8, 7>
        %6 = arith.muli %4, %5 : i8
        %7 = arith.addi %3, %6 : i8
        affine.store %7, %arg3[%arg6] : memref<10xi8, 7>
      } {parallel, point}
    } {point}
    return
  }
  func.func @forward_node3(%arg0: memref<1000x64xi8, 12>, %arg1: memref<10x16xi8, 7>, %arg2: index, %arg3: index) attributes {inline} {
    affine.for %arg4 = 0 to 10 {
      affine.for %arg5 = 0 to 16 {
        %0 = affine.load %arg0[%arg4 + symbol(%arg2) * 10, %arg5 + symbol(%arg3) * 16] : memref<1000x64xi8, 12>
        affine.store %0, %arg1[%arg4, %arg5] : memref<10x16xi8, 7>
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node4(%arg0: memref<1000xi8, 12>, %arg1: memref<10xi8, 7>, %arg2: index) attributes {inline} {
    affine.for %arg3 = 0 to 10 {
      %0 = affine.load %arg0[%arg3 + symbol(%arg2) * 10] : memref<1000xi8, 12>
      affine.store %0, %arg1[%arg3] : memref<10xi8, 7>
    } {parallel}
    return
  }
  func.func @forward_node0(%arg0: memref<64xi8, 7>, %arg1: memref<1000x64xi8, 12>, %arg2: memref<1000xi8, 12>, %arg3: memref<1000xi8, 12>) {
    affine.for %arg4 = 0 to 400 {
      %0 = affine.apply #map(%arg4)
      %1 = affine.apply #map1(%arg4)
      %2 = hls.dataflow.buffer {depth = 1 : i32} : memref<10x16xi8, 7>
      %3 = hls.dataflow.buffer {depth = 1 : i32} : memref<10xi8, 7>
      func.call @forward_node4(%arg2, %3, %0) : (memref<1000xi8, 12>, memref<10xi8, 7>, index) -> ()
      func.call @forward_node3(%arg1, %2, %0, %1) : (memref<1000x64xi8, 12>, memref<10x16xi8, 7>, index, index) -> ()
      %4 = hls.dataflow.buffer {depth = 1 : i32} : memref<10xi8, 7>
      func.call @forward_node2(%arg0, %2, %3, %4, %1) : (memref<64xi8, 7>, memref<10x16xi8, 7>, memref<10xi8, 7>, memref<10xi8, 7>, index) -> ()
      func.call @forward_node1(%4, %arg3, %0) : (memref<10xi8, 7>, memref<1000xi8, 12>, index) -> ()
    } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
    return
  }
  func.func @forward_node6(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    %c-24_i8 = arith.constant -24 : i8
    affine.for %arg5 = 0 to 14 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 16 {
          %0 = affine.load %arg0[%arg7, %arg5, %arg6] : memref<16x14x14xi8, 7>
          %1 = affine.load %arg1[%arg7 + symbol(%arg2) * 16] : memref<64xi8, 7>
          %2 = arith.addi %1, %0 : i8
          %3 = arith.divui %2, %c-24_i8 : i8
          %4 = hls.affine.select #set2(%arg5, %arg6, %arg3, %arg4) %3, %2 : i8
          affine.store %4, %arg1[%arg7 + symbol(%arg2) * 16] : memref<64xi8, 7>
        } {parallel, point}
      } {point}
    } {point}
    return
  }
  func.func @forward_node7(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node5(%arg0: !hls.stream<i1, 1>, %arg1: memref<64x28x28xi8, 12>, %arg2: memref<64xi8, 7>) {
    hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 1>) -> ()
    affine.for %arg3 = 0 to 16 {
      %0 = affine.apply #map2(%arg3)
      %1 = affine.apply #map3(%arg3)
      %2 = affine.apply #map4(%arg3)
      %3 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node7(%arg1, %3, %0, %2, %1) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      func.call @forward_node6(%3, %arg2, %0, %2, %1) : (memref<16x14x14xi8, 7>, memref<64xi8, 7>, index, index, index) -> ()
    } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
    return
  }
  func.func @forward_node9(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
          affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node10(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
          affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node11(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x14x14xi8, 7>, %arg2: memref<16x16xi8, 7>, %arg3: memref<16x14x14xi8, 7>, %arg4: memref<16x14x14xi8, 7>, %arg5: memref<16x14x14xi8, 7>, %arg6: index) attributes {inline} {
    %c-24_i8 = arith.constant -24 : i8
    affine.for %arg7 = 0 to 16 {
      affine.for %arg8 = 0 to 16 {
        affine.for %arg9 = 0 to 14 {
          affine.for %arg10 = 0 to 14 {
            %0 = affine.load %arg1[%arg7, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %1 = affine.load %arg2[%arg8, %arg7] : memref<16x16xi8, 7>
            %2 = affine.load %arg3[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %3 = affine.load %arg5[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %4 = hls.affine.select #set(%arg7) %2, %3 : i8
            %5 = arith.muli %0, %1 : i8
            %6 = arith.addi %4, %5 : i8
            affine.store %6, %arg5[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %7 = affine.load %arg0[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %8 = arith.addi %7, %6 : i8
            %9 = arith.cmpi ugt, %8, %c-24_i8 : i8
            %10 = arith.select %9, %8, %c-24_i8 : i8
            affine.if #set3(%arg7)[%arg6] {
              affine.store %10, %arg4[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            }
          } {parallel, point}
        } {parallel, point}
      } {parallel, point}
    } {point}
    return
  }
  func.func @forward_node12(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node13(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node14(%arg0: memref<64x64xi8, 12>, %arg1: memref<16x16xi8, 7>, %arg2: index, %arg3: index) attributes {inline} {
    affine.for %arg4 = 0 to 16 {
      affine.for %arg5 = 0 to 16 {
        %0 = affine.load %arg0[%arg4 + symbol(%arg2) * 16, %arg5 + symbol(%arg3) * 16] : memref<64x64xi8, 12>
        affine.store %0, %arg1[%arg4, %arg5] : memref<16x16xi8, 7>
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node15(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 * 2 + symbol(%arg3) * 28, %arg7 * 2 + symbol(%arg4) * 28] : memref<64x56x56xi8, 12>
          affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node8(%arg0: !hls.stream<i1, 3>, %arg1: memref<64x56x56xi8, 12>, %arg2: memref<64x64xi8, 12>, %arg3: !hls.stream<i1, 1>, %arg4: memref<64x28x28xi8, 12>, %arg5: memref<64x28x28xi8, 12>, %arg6: !hls.stream<i1, 1>, %arg7: memref<64x28x28xi8, 12>, %arg8: memref<64x28x28xi8, 12>) {
    %true = arith.constant true
    hls.dataflow.stream_read %arg3 : (!hls.stream<i1, 1>) -> ()
    hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 3>) -> ()
    affine.for %arg9 = 0 to 64 {
      %0 = affine.apply #map5(%arg9)
      %1 = affine.apply #map6(%arg9)
      %2 = affine.apply #map7(%arg9)
      %3 = affine.apply #map8(%arg9)
      %4 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      %5 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
      %6 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
      %7 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x16xi8, 7>
      %8 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node15(%arg1, %8, %3, %1, %0) : (memref<64x56x56xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      func.call @forward_node14(%arg2, %7, %2, %3) : (memref<64x64xi8, 12>, memref<16x16xi8, 7>, index, index) -> ()
      func.call @forward_node13(%arg5, %6, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      func.call @forward_node12(%arg4, %5, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      %9 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node11(%5, %8, %7, %6, %4, %9, %3) : (memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, memref<16x16xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, index) -> ()
      func.call @forward_node10(%9, %arg8, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
      func.call @forward_node9(%4, %arg7, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
    } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
    hls.dataflow.stream_write %arg6, %true : <i1, 1>, i1
    return
  }
  func.func @forward_node17(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 step 2 {
        affine.for %arg7 = 0 to 14 step 2 {
          %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
          affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          %1 = affine.load %arg0[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
          affine.store %1, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
          %2 = affine.load %arg0[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
          affine.store %2, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          %3 = affine.load %arg0[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
          affine.store %3, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node18(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x16xi8, 7>, %arg2: memref<16x14x14xi8, 7>, %arg3: memref<16x14x14xi8, 7>) attributes {inline} {
    affine.for %arg4 = 0 to 16 {
      affine.for %arg5 = 0 to 16 {
        affine.for %arg6 = 0 to 14 step 2 {
          affine.for %arg7 = 0 to 14 step 2 {
            %0 = affine.load %arg0[%arg4, %arg6, %arg7] : memref<16x14x14xi8, 7>
            %1 = affine.load %arg1[%arg5, %arg4] : memref<16x16xi8, 7>
            %2 = affine.load %arg2[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
            %3 = affine.load %arg3[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
            %4 = hls.affine.select #set(%arg4) %2, %3 : i8
            %5 = arith.muli %0, %1 : i8
            %6 = arith.addi %4, %5 : i8
            affine.store %6, %arg3[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
            %7 = affine.load %arg0[%arg4, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
            %8 = affine.load %arg2[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
            %9 = affine.load %arg3[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
            %10 = hls.affine.select #set(%arg4) %8, %9 : i8
            %11 = arith.muli %7, %1 : i8
            %12 = arith.addi %10, %11 : i8
            affine.store %12, %arg3[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
            %13 = affine.load %arg0[%arg4, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
            %14 = affine.load %arg2[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
            %15 = affine.load %arg3[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
            %16 = hls.affine.select #set(%arg4) %14, %15 : i8
            %17 = arith.muli %13, %1 : i8
            %18 = arith.addi %16, %17 : i8
            affine.store %18, %arg3[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
            %19 = affine.load %arg0[%arg4, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
            %20 = affine.load %arg2[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
            %21 = affine.load %arg3[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
            %22 = hls.affine.select #set(%arg4) %20, %21 : i8
            %23 = arith.muli %19, %1 : i8
            %24 = arith.addi %22, %23 : i8
            affine.store %24, %arg3[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
          } {parallel, point}
        } {parallel, point}
      } {parallel, point}
    } {point}
    return
  }
  func.func @forward_node19(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 step 2 {
        affine.for %arg7 = 0 to 14 step 2 {
          %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
          %1 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
          affine.store %1, %arg1[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
          %2 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          affine.store %2, %arg1[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
          %3 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
          affine.store %3, %arg1[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node20(%arg0: memref<64x64x3x3xi8, 12>, %arg1: memref<16x16xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index) attributes {inline} {
    affine.for %arg6 = 0 to 16 {
      affine.for %arg7 = 0 to 16 {
        %0 = affine.load %arg0[%arg6 + symbol(%arg2) * 16, %arg7 + symbol(%arg3) * 16, symbol(%arg4), symbol(%arg5)] : memref<64x64x3x3xi8, 12>
        affine.store %0, %arg1[%arg6, %arg7] : memref<16x16xi8, 7>
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node21(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index, %arg6: index) attributes {inline} {
    affine.for %arg7 = 0 to 16 {
      affine.for %arg8 = 0 to 14 step 2 {
        affine.for %arg9 = 0 to 14 step 2 {
          %0 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14 - 1, %arg9 + symbol(%arg5) + symbol(%arg6) * 14 - 1] : memref<64x28x28xi8, 12>
          affine.store %0, %arg1[%arg7, %arg8, %arg9] : memref<16x14x14xi8, 7>
          %1 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14 - 1, %arg9 + symbol(%arg5) + symbol(%arg6) * 14] : memref<64x28x28xi8, 12>
          affine.store %1, %arg1[%arg7, %arg8, %arg9 + 1] : memref<16x14x14xi8, 7>
          %2 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14, %arg9 + symbol(%arg5) + symbol(%arg6) * 14 - 1] : memref<64x28x28xi8, 12>
          affine.store %2, %arg1[%arg7, %arg8 + 1, %arg9] : memref<16x14x14xi8, 7>
          %3 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 + symbol(%arg3) + symbol(%arg4) * 14, %arg9 + symbol(%arg5) + symbol(%arg6) * 14] : memref<64x28x28xi8, 12>
          affine.store %3, %arg1[%arg7, %arg8 + 1, %arg9 + 1] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node16(%arg0: memref<64x64x3x3xi8, 12>, %arg1: !hls.stream<i1, 1>, %arg2: memref<64x28x28xi8, 12>, %arg3: memref<64x28x28xi8, 12>, %arg4: !hls.stream<i1, 1>, %arg5: memref<64x28x28xi8, 12>) {
    %true = arith.constant true
    hls.dataflow.stream_read %arg1 : (!hls.stream<i1, 1>) -> ()
    affine.for %arg6 = 0 to 576 {
      %0 = affine.apply #map5(%arg6)
      %1 = affine.apply #map6(%arg6)
      %2 = affine.apply #map7(%arg6)
      %3 = affine.apply #map9(%arg6)
      %4 = affine.apply #map10(%arg6)
      %5 = affine.apply #map11(%arg6)
      %6 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
      %7 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x16xi8, 7>
      %8 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
      func.call @forward_node21(%arg2, %8, %5, %4, %1, %3, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index, index, index) -> ()
      func.call @forward_node20(%arg0, %7, %2, %5, %4, %3) : (memref<64x64x3x3xi8, 12>, memref<16x16xi8, 7>, index, index, index, index) -> ()
      func.call @forward_node19(%arg3, %6, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      %9 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node18(%8, %7, %6, %9) : (memref<16x14x14xi8, 7>, memref<16x16xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>) -> ()
      func.call @forward_node17(%9, %arg5, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
    } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
    hls.dataflow.stream_write %arg4, %true : <i1, 1>, i1
    return
  }
  func.func @forward_node23(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x28x28xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 step 2 {
        affine.for %arg7 = 0 to 14 step 2 {
          %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
          affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          %1 = affine.load %arg0[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
          affine.store %1, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
          %2 = affine.load %arg0[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
          affine.store %2, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          %3 = affine.load %arg0[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
          affine.store %3, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node24(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x16xi8, 7>, %arg2: memref<16x14x14xi8, 7>, %arg3: memref<16x14x14xi8, 7>, %arg4: index, %arg5: index, %arg6: index) attributes {inline} {
    %c-24_i8 = arith.constant -24 : i8
    affine.for %arg7 = 0 to 16 {
      affine.for %arg8 = 0 to 16 {
        affine.for %arg9 = 0 to 14 step 2 {
          affine.for %arg10 = 0 to 14 step 2 {
            %0 = affine.load %arg0[%arg7, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %1 = affine.load %arg1[%arg8, %arg7] : memref<16x16xi8, 7>
            %2 = affine.load %arg2[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %3 = affine.load %arg3[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %4 = hls.affine.select #set(%arg7) %2, %3 : i8
            %5 = arith.muli %0, %1 : i8
            %6 = arith.addi %4, %5 : i8
            %7 = arith.cmpi ugt, %6, %c-24_i8 : i8
            %8 = arith.select %7, %6, %c-24_i8 : i8
            %9 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %8, %6 : i8
            affine.store %9, %arg3[%arg8, %arg9, %arg10] : memref<16x14x14xi8, 7>
            %10 = affine.load %arg0[%arg7, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
            %11 = affine.load %arg2[%arg8, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
            %12 = affine.load %arg3[%arg8, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
            %13 = hls.affine.select #set(%arg7) %11, %12 : i8
            %14 = arith.muli %10, %1 : i8
            %15 = arith.addi %13, %14 : i8
            %16 = arith.cmpi ugt, %15, %c-24_i8 : i8
            %17 = arith.select %16, %15, %c-24_i8 : i8
            %18 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %17, %15 : i8
            affine.store %18, %arg3[%arg8, %arg9, %arg10 + 1] : memref<16x14x14xi8, 7>
            %19 = affine.load %arg0[%arg7, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
            %20 = affine.load %arg2[%arg8, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
            %21 = affine.load %arg3[%arg8, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
            %22 = hls.affine.select #set(%arg7) %20, %21 : i8
            %23 = arith.muli %19, %1 : i8
            %24 = arith.addi %22, %23 : i8
            %25 = arith.cmpi ugt, %24, %c-24_i8 : i8
            %26 = arith.select %25, %24, %c-24_i8 : i8
            %27 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %26, %24 : i8
            affine.store %27, %arg3[%arg8, %arg9 + 1, %arg10] : memref<16x14x14xi8, 7>
            %28 = affine.load %arg0[%arg7, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
            %29 = affine.load %arg2[%arg8, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
            %30 = affine.load %arg3[%arg8, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
            %31 = hls.affine.select #set(%arg7) %29, %30 : i8
            %32 = arith.muli %28, %1 : i8
            %33 = arith.addi %31, %32 : i8
            %34 = arith.cmpi ugt, %33, %c-24_i8 : i8
            %35 = arith.select %34, %33, %c-24_i8 : i8
            %36 = hls.affine.select #set4(%arg6, %arg4, %arg7, %arg5) %35, %33 : i8
            affine.store %36, %arg3[%arg8, %arg9 + 1, %arg10 + 1] : memref<16x14x14xi8, 7>
          } {parallel, point}
        } {parallel, point}
      } {parallel, point}
    } {point}
    return
  }
  func.func @forward_node25(%arg0: memref<64x28x28xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 step 2 {
        affine.for %arg7 = 0 to 14 step 2 {
          %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
          %1 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
          affine.store %1, %arg1[%arg5, %arg6, %arg7 + 1] : memref<16x14x14xi8, 7>
          %2 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14] : memref<64x28x28xi8, 12>
          affine.store %2, %arg1[%arg5, %arg6 + 1, %arg7] : memref<16x14x14xi8, 7>
          %3 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14 + 1, %arg7 + symbol(%arg4) * 14 + 1] : memref<64x28x28xi8, 12>
          affine.store %3, %arg1[%arg5, %arg6 + 1, %arg7 + 1] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node26(%arg0: memref<64x64x3x3xi8, 12>, %arg1: memref<16x16xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index) attributes {inline} {
    affine.for %arg6 = 0 to 16 {
      affine.for %arg7 = 0 to 16 {
        %0 = affine.load %arg0[%arg6 + symbol(%arg2) * 16, %arg7 + symbol(%arg3) * 16, symbol(%arg4), symbol(%arg5)] : memref<64x64x3x3xi8, 12>
        affine.store %0, %arg1[%arg6, %arg7] : memref<16x16xi8, 7>
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node27(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index, %arg5: index, %arg6: index) attributes {inline} {
    affine.for %arg7 = 0 to 16 {
      affine.for %arg8 = 0 to 14 step 2 {
        affine.for %arg9 = 0 to 14 step 2 {
          %0 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 - 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 - 1] : memref<64x56x56xi8, 12>
          affine.store %0, %arg1[%arg7, %arg8, %arg9] : memref<16x14x14xi8, 7>
          %1 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 - 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 + 1] : memref<64x56x56xi8, 12>
          affine.store %1, %arg1[%arg7, %arg8, %arg9 + 1] : memref<16x14x14xi8, 7>
          %2 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 + 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 - 1] : memref<64x56x56xi8, 12>
          affine.store %2, %arg1[%arg7, %arg8 + 1, %arg9] : memref<16x14x14xi8, 7>
          %3 = affine.load %arg0[%arg7 + symbol(%arg2) * 16, %arg8 * 2 + symbol(%arg3) + symbol(%arg4) * 28 + 1, %arg9 * 2 + symbol(%arg5) + symbol(%arg6) * 28 + 1] : memref<64x56x56xi8, 12>
          affine.store %3, %arg1[%arg7, %arg8 + 1, %arg9 + 1] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node22(%arg0: !hls.stream<i1, 1>, %arg1: memref<64x56x56xi8, 12>, %arg2: memref<64x64x3x3xi8, 12>, %arg3: memref<64x28x28xi8, 12>, %arg4: !hls.stream<i1, 1>, %arg5: memref<64x28x28xi8, 12>) {
    %true = arith.constant true
    hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 1>) -> ()
    affine.for %arg6 = 0 to 576 {
      %0 = affine.apply #map5(%arg6)
      %1 = affine.apply #map6(%arg6)
      %2 = affine.apply #map7(%arg6)
      %3 = affine.apply #map9(%arg6)
      %4 = affine.apply #map10(%arg6)
      %5 = affine.apply #map11(%arg6)
      %6 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<16x14x14xi8, 7>
      %7 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x16xi8, 7>
      %8 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node27(%arg1, %8, %5, %4, %1, %3, %0) : (memref<64x56x56xi8, 12>, memref<16x14x14xi8, 7>, index, index, index, index, index) -> ()
      func.call @forward_node26(%arg2, %7, %2, %5, %4, %3) : (memref<64x64x3x3xi8, 12>, memref<16x16xi8, 7>, index, index, index, index) -> ()
      func.call @forward_node25(%arg3, %6, %2, %1, %0) : (memref<64x28x28xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      %9 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node24(%8, %7, %6, %9, %3, %5, %4) : (memref<16x14x14xi8, 7>, memref<16x16xi8, 7>, memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      func.call @forward_node23(%9, %arg5, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x28x28xi8, 12>, index, index, index) -> ()
    } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>}
    hls.dataflow.stream_write %arg4, %true : <i1, 1>, i1
    return
  }
  func.func @forward_node28(%arg0: !hls.stream<i1, 1>, %arg1: memref<64x56x56xi8, 12>, %arg2: !hls.stream<i1, 3>, %arg3: memref<64x56x56xi8, 12>, %arg4: !hls.stream<i1, 1>, %arg5: memref<64x56x56xi8, 12>) {
    %true = arith.constant true
    hls.dataflow.stream_read %arg0 : (!hls.stream<i1, 1>) -> ()
    affine.for %arg6 = 0 to 64 {
      affine.for %arg7 = 0 to 56 {
        affine.for %arg8 = 0 to 56 {
          %0 = affine.load %arg1[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
          affine.store %0, %arg3[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
        } {parallel}
      } {parallel}
    } {parallel}
    affine.for %arg6 = 0 to 64 {
      affine.for %arg7 = 0 to 56 {
        affine.for %arg8 = 0 to 56 {
          %0 = affine.load %arg1[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
          affine.store %0, %arg5[%arg6, %arg7, %arg8] : memref<64x56x56xi8, 12>
        } {parallel}
      } {parallel}
    } {parallel}
    hls.dataflow.stream_write %arg2, %true : <i1, 3>, i1
    hls.dataflow.stream_write %arg4, %true : <i1, 1>, i1
    return
  }
  func.func @forward_node30(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<64x56x56xi8, 12>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
          affine.store %0, %arg1[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x56x56xi8, 12>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node31(%arg0: memref<16x14x14xi8, 7>, %arg1: memref<16x14x14xi8, 7>) attributes {inline} {
    %c-24_i8 = arith.constant -24 : i8
    affine.for %arg2 = 0 to 16 {
      affine.for %arg3 = 0 to 14 {
        affine.for %arg4 = 0 to 14 {
          %0 = affine.load %arg0[%arg2, %arg3, %arg4] : memref<16x14x14xi8, 7>
          %1 = arith.cmpi ugt, %0, %c-24_i8 : i8
          %2 = arith.select %1, %0, %c-24_i8 : i8
          affine.store %2, %arg1[%arg2, %arg3, %arg4] : memref<16x14x14xi8, 7>
        } {parallel, point}
      } {parallel, point}
    } {parallel, point}
    return
  }
  func.func @forward_node32(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<16x14x14xi8, 7>, %arg2: index, %arg3: index, %arg4: index) attributes {inline} {
    affine.for %arg5 = 0 to 16 {
      affine.for %arg6 = 0 to 14 {
        affine.for %arg7 = 0 to 14 {
          %0 = affine.load %arg0[%arg5 + symbol(%arg2) * 16, %arg6 + symbol(%arg3) * 14, %arg7 + symbol(%arg4) * 14] : memref<64x56x56xi8, 12>
          affine.store %0, %arg1[%arg5, %arg6, %arg7] : memref<16x14x14xi8, 7>
        } {parallel}
      } {parallel}
    } {parallel}
    return
  }
  func.func @forward_node29(%arg0: memref<64x56x56xi8, 12>, %arg1: !hls.stream<i1, 1>, %arg2: memref<64x56x56xi8, 12>) {
    %true = arith.constant true
    affine.for %arg3 = 0 to 64 {
      %0 = affine.apply #map2(%arg3)
      %1 = affine.apply #map12(%arg3)
      %2 = affine.apply #map13(%arg3)
      %3 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node32(%arg0, %3, %2, %1, %0) : (memref<64x56x56xi8, 12>, memref<16x14x14xi8, 7>, index, index, index) -> ()
      %4 = hls.dataflow.buffer {depth = 1 : i32} : memref<16x14x14xi8, 7>
      func.call @forward_node31(%3, %4) : (memref<16x14x14xi8, 7>, memref<16x14x14xi8, 7>) -> ()
      func.call @forward_node30(%4, %arg2, %2, %1, %0) : (memref<16x14x14xi8, 7>, memref<64x56x56xi8, 12>, index, index, index) -> ()
    } {loop_directive = #hls.ld<pipeline=false, targetII=1, dataflow=true, flatten=false>, parallel}
    hls.dataflow.stream_write %arg1, %true : <i1, 1>, i1
    return
  }
  func.func @forward(%arg0: memref<64x56x56xi8, 12>, %arg1: memref<1000x64xi8, 12>, %arg2: memref<64x64xi8, 12>, %arg3: memref<64x64x3x3xi8, 12>, %arg4: memref<64x64x3x3xi8, 12>, %arg5: memref<1000xi8, 12>) attributes {func_directive = #hls.fd<pipeline=false, targetInterval=1, dataflow=true>, top_func} {
    %0 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
    call @forward_node29(%arg0, %0, %arg0) : (memref<64x56x56xi8, 12>, !hls.stream<i1, 1>, memref<64x56x56xi8, 12>) -> ()
    %1 = hls.dataflow.buffer {depth = 3 : i32} : memref<64x56x56xi8, 12>
    %2 = hls.dataflow.stream {depth = 3 : i32} : <i1, 3>
    %3 = hls.dataflow.buffer {depth = 1 : i32} : memref<64x56x56xi8, 12>
    %4 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
    call @forward_node28(%0, %arg0, %2, %1, %4, %3) : (!hls.stream<i1, 1>, memref<64x56x56xi8, 12>, !hls.stream<i1, 3>, memref<64x56x56xi8, 12>, !hls.stream<i1, 1>, memref<64x56x56xi8, 12>) -> ()
    %5 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64x28x28xi8, 12>
    %6 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
    call @forward_node22(%4, %3, %arg4, %5, %6, %5) : (!hls.stream<i1, 1>, memref<64x56x56xi8, 12>, memref<64x64x3x3xi8, 12>, memref<64x28x28xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>) -> ()
    %7 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64x28x28xi8, 12>
    %8 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
    call @forward_node16(%arg3, %6, %5, %7, %8, %7) : (memref<64x64x3x3xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64x28x28xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>) -> ()
    %9 = hls.dataflow.buffer {depth = 1 : i32} : memref<64x28x28xi8, 12>
    %10 = hls.dataflow.stream {depth = 1 : i32} : <i1, 1>
    %11 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64x28x28xi8, 12>
    call @forward_node8(%2, %1, %arg2, %8, %7, %11, %10, %9, %11) : (!hls.stream<i1, 3>, memref<64x56x56xi8, 12>, memref<64x64xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64x28x28xi8, 12>, !hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64x28x28xi8, 12>) -> ()
    %12 = hls.dataflow.buffer {depth = 1 : i32, init_value = -24 : i8} : memref<64xi8, 7>
    call @forward_node5(%10, %9, %12) : (!hls.stream<i1, 1>, memref<64x28x28xi8, 12>, memref<64xi8, 7>) -> ()
    call @forward_node0(%12, %arg1, %arg5, %arg5) : (memref<64xi8, 7>, memref<1000x64xi8, 12>, memref<1000xi8, 12>, memref<1000xi8, 12>) -> ()
    return
  }
}

