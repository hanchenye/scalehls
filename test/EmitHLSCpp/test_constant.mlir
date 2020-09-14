// RUN: scalehls-translate -emit-hlscpp %s | FileCheck %s

func @test_standard(%arg0: i32) -> i32 {

  // CHECK: ap_int<32> [[VAL_0:.*]][2][2] = {11, 0, 0, -42};
  // CHECK: float [[VAL_1:.*]][2][2] = {1.100000e+01, 0.000000e+00, 0.000000e+00, -4.200000e+01};
  // CHECK: ap_int<1> [[VAL_2:.*]][2][2] = {1, 0, 0, 1};
  %0 = constant dense<[[11, 0], [0, -42]]> : tensor<2x2xi32>
  %1 = constant dense<[[11.0, 0.0], [0.0, -42.0]]> : tensor<2x2xf32>
  %2 = constant dense<[[1, 0], [0, 1]]> : tensor<2x2xi1>

  // CHECK: ap_int<32> [[VAL_3:.*]][2] = {0, -42};
  // CHECK: float [[VAL_4:.*]][2] = {0.000000e+00, -4.200000e+01};
  // CHECK: ap_int<1> [[VAL_5:.*]][2] = {0, 1};
  %3 = constant dense<[0, -42]> : vector<2xi32>
  %4 = constant dense<[0.0, -42.0]> : vector<2xf32>
  %5 = constant dense<[0, 1]> : vector<2xi1>

  // CHECK: *[[ARG_1:.*]] = 11 + [[ARG_0:.*]];
  %c11 = constant 11 : i32
  %6 = addi %c11, %arg0 : i32
  return %6 : i32
}
