
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

/// This is top function.
/// Latency=98, interval=98
/// DSP=175
void matrix_vector_product_with_bias_input_layer(
  double v0[64],
  double v1[832],
  double v2[64],
  double v3[13],
  double v4[1]
) {	// L5, [0,98)
  #pragma HLS interface s_axilite port=return bundle=ctrl
  #pragma HLS interface bram port=v0
  #pragma HLS interface bram port=v1
  #pragma HLS interface bram port=v2

  #pragma HLS resource variable=v0 core=ram_1p_bram

  #pragma HLS array_partition variable=v1 cyclic factor=104 dim=1
  #pragma HLS resource variable=v1 core=ram_s2p_bram

  #pragma HLS array_partition variable=v2 cyclic factor=8 dim=1
  #pragma HLS resource variable=v2 core=ram_s2p_bram

  #pragma HLS array_partition variable=v3 cyclic factor=13 dim=1

  for (int v5 = 0; v5 < 8; v5 += 1) {	// L8, [0,95), iterCycle=72, II=3
    #pragma HLS pipeline II=3
    double v6 = v1[(v5 * 104)];	// L9, [0,2)
    double v7 = v3[0];	// L10, [0,2)
    double v8 = v6 * v7;	// L11, [2,6)
    double v9 = v8 + 0.000000;	// L12, [6,11)
    double v10 = v1[((v5 * 104) + 13)];	// L13, [0,2)
    double v11 = v10 * v7;	// L14, [2,6)
    double v12 = v11 + 0.000000;	// L15, [6,11)
    double v13 = v1[((v5 * 104) + 26)];	// L16, [0,2)
    double v14 = v13 * v7;	// L17, [2,6)
    double v15 = v14 + 0.000000;	// L18, [6,11)
    double v16 = v1[((v5 * 104) + 39)];	// L19, [0,2)
    double v17 = v16 * v7;	// L20, [2,6)
    double v18 = v17 + 0.000000;	// L21, [6,11)
    double v19 = v1[((v5 * 104) + 52)];	// L22, [0,2)
    double v20 = v19 * v7;	// L23, [2,6)
    double v21 = v20 + 0.000000;	// L24, [6,11)
    double v22 = v1[((v5 * 104) + 65)];	// L25, [0,2)
    double v23 = v22 * v7;	// L26, [2,6)
    double v24 = v23 + 0.000000;	// L27, [6,11)
    double v25 = v1[((v5 * 104) + 78)];	// L28, [0,2)
    double v26 = v25 * v7;	// L29, [2,6)
    double v27 = v26 + 0.000000;	// L30, [6,11)
    double v28 = v1[((v5 * 104) + 91)];	// L31, [0,2)
    double v29 = v28 * v7;	// L32, [2,6)
    double v30 = v29 + 0.000000;	// L33, [6,11)
    double v31 = v1[((v5 * 104) + 1)];	// L34, [5,7)
    double v32 = v3[1];	// L35, [5,7)
    double v33 = v31 * v32;	// L36, [7,11)
    double v34 = v9 + v33;	// L37, [11,16)
    double v35 = v1[((v5 * 104) + 14)];	// L38, [5,7)
    double v36 = v35 * v32;	// L39, [7,11)
    double v37 = v12 + v36;	// L40, [11,16)
    double v38 = v1[((v5 * 104) + 27)];	// L41, [5,7)
    double v39 = v38 * v32;	// L42, [7,11)
    double v40 = v15 + v39;	// L43, [11,16)
    double v41 = v1[((v5 * 104) + 40)];	// L44, [5,7)
    double v42 = v41 * v32;	// L45, [7,11)
    double v43 = v18 + v42;	// L46, [11,16)
    double v44 = v1[((v5 * 104) + 53)];	// L47, [5,7)
    double v45 = v44 * v32;	// L48, [7,11)
    double v46 = v21 + v45;	// L49, [11,16)
    double v47 = v1[((v5 * 104) + 66)];	// L50, [5,7)
    double v48 = v47 * v32;	// L51, [7,11)
    double v49 = v24 + v48;	// L52, [11,16)
    double v50 = v1[((v5 * 104) + 79)];	// L53, [5,7)
    double v51 = v50 * v32;	// L54, [7,11)
    double v52 = v27 + v51;	// L55, [11,16)
    double v53 = v1[((v5 * 104) + 92)];	// L56, [5,7)
    double v54 = v53 * v32;	// L57, [7,11)
    double v55 = v30 + v54;	// L58, [11,16)
    double v56 = v1[((v5 * 104) + 2)];	// L59, [10,12)
    double v57 = v3[2];	// L60, [10,12)
    double v58 = v56 * v57;	// L61, [12,16)
    double v59 = v34 + v58;	// L62, [16,21)
    double v60 = v1[((v5 * 104) + 15)];	// L63, [10,12)
    double v61 = v60 * v57;	// L64, [12,16)
    double v62 = v37 + v61;	// L65, [16,21)
    double v63 = v1[((v5 * 104) + 28)];	// L66, [10,12)
    double v64 = v63 * v57;	// L67, [12,16)
    double v65 = v40 + v64;	// L68, [16,21)
    double v66 = v1[((v5 * 104) + 41)];	// L69, [10,12)
    double v67 = v66 * v57;	// L70, [12,16)
    double v68 = v43 + v67;	// L71, [16,21)
    double v69 = v1[((v5 * 104) + 54)];	// L72, [10,12)
    double v70 = v69 * v57;	// L73, [12,16)
    double v71 = v46 + v70;	// L74, [16,21)
    double v72 = v1[((v5 * 104) + 67)];	// L75, [10,12)
    double v73 = v72 * v57;	// L76, [12,16)
    double v74 = v49 + v73;	// L77, [16,21)
    double v75 = v1[((v5 * 104) + 80)];	// L78, [10,12)
    double v76 = v75 * v57;	// L79, [12,16)
    double v77 = v52 + v76;	// L80, [16,21)
    double v78 = v1[((v5 * 104) + 93)];	// L81, [10,12)
    double v79 = v78 * v57;	// L82, [12,16)
    double v80 = v55 + v79;	// L83, [16,21)
    double v81 = v1[((v5 * 104) + 3)];	// L84, [15,17)
    double v82 = v3[3];	// L85, [15,17)
    double v83 = v81 * v82;	// L86, [17,21)
    double v84 = v59 + v83;	// L87, [21,26)
    double v85 = v1[((v5 * 104) + 16)];	// L88, [15,17)
    double v86 = v85 * v82;	// L89, [17,21)
    double v87 = v62 + v86;	// L90, [21,26)
    double v88 = v1[((v5 * 104) + 29)];	// L91, [15,17)
    double v89 = v88 * v82;	// L92, [17,21)
    double v90 = v65 + v89;	// L93, [21,26)
    double v91 = v1[((v5 * 104) + 42)];	// L94, [15,17)
    double v92 = v91 * v82;	// L95, [17,21)
    double v93 = v68 + v92;	// L96, [21,26)
    double v94 = v1[((v5 * 104) + 55)];	// L97, [15,17)
    double v95 = v94 * v82;	// L98, [17,21)
    double v96 = v71 + v95;	// L99, [21,26)
    double v97 = v1[((v5 * 104) + 68)];	// L100, [15,17)
    double v98 = v97 * v82;	// L101, [17,21)
    double v99 = v74 + v98;	// L102, [21,26)
    double v100 = v1[((v5 * 104) + 81)];	// L103, [15,17)
    double v101 = v100 * v82;	// L104, [17,21)
    double v102 = v77 + v101;	// L105, [21,26)
    double v103 = v1[((v5 * 104) + 94)];	// L106, [15,17)
    double v104 = v103 * v82;	// L107, [17,21)
    double v105 = v80 + v104;	// L108, [21,26)
    double v106 = v1[((v5 * 104) + 4)];	// L109, [20,22)
    double v107 = v3[4];	// L110, [20,22)
    double v108 = v106 * v107;	// L111, [22,26)
    double v109 = v84 + v108;	// L112, [26,31)
    double v110 = v1[((v5 * 104) + 17)];	// L113, [20,22)
    double v111 = v110 * v107;	// L114, [22,26)
    double v112 = v87 + v111;	// L115, [26,31)
    double v113 = v1[((v5 * 104) + 30)];	// L116, [20,22)
    double v114 = v113 * v107;	// L117, [22,26)
    double v115 = v90 + v114;	// L118, [26,31)
    double v116 = v1[((v5 * 104) + 43)];	// L119, [20,22)
    double v117 = v116 * v107;	// L120, [22,26)
    double v118 = v93 + v117;	// L121, [26,31)
    double v119 = v1[((v5 * 104) + 56)];	// L122, [20,22)
    double v120 = v119 * v107;	// L123, [22,26)
    double v121 = v96 + v120;	// L124, [26,31)
    double v122 = v1[((v5 * 104) + 69)];	// L125, [20,22)
    double v123 = v122 * v107;	// L126, [22,26)
    double v124 = v99 + v123;	// L127, [26,31)
    double v125 = v1[((v5 * 104) + 82)];	// L128, [20,22)
    double v126 = v125 * v107;	// L129, [22,26)
    double v127 = v102 + v126;	// L130, [26,31)
    double v128 = v1[((v5 * 104) + 95)];	// L131, [20,22)
    double v129 = v128 * v107;	// L132, [22,26)
    double v130 = v105 + v129;	// L133, [26,31)
    double v131 = v1[((v5 * 104) + 5)];	// L134, [25,27)
    double v132 = v3[5];	// L135, [25,27)
    double v133 = v131 * v132;	// L136, [27,31)
    double v134 = v109 + v133;	// L137, [31,36)
    double v135 = v1[((v5 * 104) + 18)];	// L138, [25,27)
    double v136 = v135 * v132;	// L139, [27,31)
    double v137 = v112 + v136;	// L140, [31,36)
    double v138 = v1[((v5 * 104) + 31)];	// L141, [25,27)
    double v139 = v138 * v132;	// L142, [27,31)
    double v140 = v115 + v139;	// L143, [31,36)
    double v141 = v1[((v5 * 104) + 44)];	// L144, [25,27)
    double v142 = v141 * v132;	// L145, [27,31)
    double v143 = v118 + v142;	// L146, [31,36)
    double v144 = v1[((v5 * 104) + 57)];	// L147, [25,27)
    double v145 = v144 * v132;	// L148, [27,31)
    double v146 = v121 + v145;	// L149, [31,36)
    double v147 = v1[((v5 * 104) + 70)];	// L150, [25,27)
    double v148 = v147 * v132;	// L151, [27,31)
    double v149 = v124 + v148;	// L152, [31,36)
    double v150 = v1[((v5 * 104) + 83)];	// L153, [25,27)
    double v151 = v150 * v132;	// L154, [27,31)
    double v152 = v127 + v151;	// L155, [31,36)
    double v153 = v1[((v5 * 104) + 96)];	// L156, [25,27)
    double v154 = v153 * v132;	// L157, [27,31)
    double v155 = v130 + v154;	// L158, [31,36)
    double v156 = v1[((v5 * 104) + 6)];	// L159, [30,32)
    double v157 = v3[6];	// L160, [30,32)
    double v158 = v156 * v157;	// L161, [32,36)
    double v159 = v134 + v158;	// L162, [36,41)
    double v160 = v1[((v5 * 104) + 19)];	// L163, [30,32)
    double v161 = v160 * v157;	// L164, [32,36)
    double v162 = v137 + v161;	// L165, [36,41)
    double v163 = v1[((v5 * 104) + 32)];	// L166, [30,32)
    double v164 = v163 * v157;	// L167, [32,36)
    double v165 = v140 + v164;	// L168, [36,41)
    double v166 = v1[((v5 * 104) + 45)];	// L169, [30,32)
    double v167 = v166 * v157;	// L170, [32,36)
    double v168 = v143 + v167;	// L171, [36,41)
    double v169 = v1[((v5 * 104) + 58)];	// L172, [30,32)
    double v170 = v169 * v157;	// L173, [32,36)
    double v171 = v146 + v170;	// L174, [36,41)
    double v172 = v1[((v5 * 104) + 71)];	// L175, [30,32)
    double v173 = v172 * v157;	// L176, [32,36)
    double v174 = v149 + v173;	// L177, [36,41)
    double v175 = v1[((v5 * 104) + 84)];	// L178, [30,32)
    double v176 = v175 * v157;	// L179, [32,36)
    double v177 = v152 + v176;	// L180, [36,41)
    double v178 = v1[((v5 * 104) + 97)];	// L181, [30,32)
    double v179 = v178 * v157;	// L182, [32,36)
    double v180 = v155 + v179;	// L183, [36,41)
    double v181 = v1[((v5 * 104) + 7)];	// L184, [35,37)
    double v182 = v3[7];	// L185, [35,37)
    double v183 = v181 * v182;	// L186, [37,41)
    double v184 = v159 + v183;	// L187, [41,46)
    double v185 = v1[((v5 * 104) + 20)];	// L188, [35,37)
    double v186 = v185 * v182;	// L189, [37,41)
    double v187 = v162 + v186;	// L190, [41,46)
    double v188 = v1[((v5 * 104) + 33)];	// L191, [35,37)
    double v189 = v188 * v182;	// L192, [37,41)
    double v190 = v165 + v189;	// L193, [41,46)
    double v191 = v1[((v5 * 104) + 46)];	// L194, [35,37)
    double v192 = v191 * v182;	// L195, [37,41)
    double v193 = v168 + v192;	// L196, [41,46)
    double v194 = v1[((v5 * 104) + 59)];	// L197, [35,37)
    double v195 = v194 * v182;	// L198, [37,41)
    double v196 = v171 + v195;	// L199, [41,46)
    double v197 = v1[((v5 * 104) + 72)];	// L200, [35,37)
    double v198 = v197 * v182;	// L201, [37,41)
    double v199 = v174 + v198;	// L202, [41,46)
    double v200 = v1[((v5 * 104) + 85)];	// L203, [35,37)
    double v201 = v200 * v182;	// L204, [37,41)
    double v202 = v177 + v201;	// L205, [41,46)
    double v203 = v1[((v5 * 104) + 98)];	// L206, [35,37)
    double v204 = v203 * v182;	// L207, [37,41)
    double v205 = v180 + v204;	// L208, [41,46)
    double v206 = v1[((v5 * 104) + 8)];	// L209, [40,42)
    double v207 = v3[8];	// L210, [40,42)
    double v208 = v206 * v207;	// L211, [42,46)
    double v209 = v184 + v208;	// L212, [46,51)
    double v210 = v1[((v5 * 104) + 21)];	// L213, [40,42)
    double v211 = v210 * v207;	// L214, [42,46)
    double v212 = v187 + v211;	// L215, [46,51)
    double v213 = v1[((v5 * 104) + 34)];	// L216, [40,42)
    double v214 = v213 * v207;	// L217, [42,46)
    double v215 = v190 + v214;	// L218, [46,51)
    double v216 = v1[((v5 * 104) + 47)];	// L219, [40,42)
    double v217 = v216 * v207;	// L220, [42,46)
    double v218 = v193 + v217;	// L221, [46,51)
    double v219 = v1[((v5 * 104) + 60)];	// L222, [40,42)
    double v220 = v219 * v207;	// L223, [42,46)
    double v221 = v196 + v220;	// L224, [46,51)
    double v222 = v1[((v5 * 104) + 73)];	// L225, [40,42)
    double v223 = v222 * v207;	// L226, [42,46)
    double v224 = v199 + v223;	// L227, [46,51)
    double v225 = v1[((v5 * 104) + 86)];	// L228, [40,42)
    double v226 = v225 * v207;	// L229, [42,46)
    double v227 = v202 + v226;	// L230, [46,51)
    double v228 = v1[((v5 * 104) + 99)];	// L231, [40,42)
    double v229 = v228 * v207;	// L232, [42,46)
    double v230 = v205 + v229;	// L233, [46,51)
    double v231 = v1[((v5 * 104) + 9)];	// L234, [45,47)
    double v232 = v3[9];	// L235, [45,47)
    double v233 = v231 * v232;	// L236, [47,51)
    double v234 = v209 + v233;	// L237, [51,56)
    double v235 = v1[((v5 * 104) + 22)];	// L238, [45,47)
    double v236 = v235 * v232;	// L239, [47,51)
    double v237 = v212 + v236;	// L240, [51,56)
    double v238 = v1[((v5 * 104) + 35)];	// L241, [45,47)
    double v239 = v238 * v232;	// L242, [47,51)
    double v240 = v215 + v239;	// L243, [51,56)
    double v241 = v1[((v5 * 104) + 48)];	// L244, [45,47)
    double v242 = v241 * v232;	// L245, [47,51)
    double v243 = v218 + v242;	// L246, [51,56)
    double v244 = v1[((v5 * 104) + 61)];	// L247, [45,47)
    double v245 = v244 * v232;	// L248, [47,51)
    double v246 = v221 + v245;	// L249, [51,56)
    double v247 = v1[((v5 * 104) + 74)];	// L250, [45,47)
    double v248 = v247 * v232;	// L251, [47,51)
    double v249 = v224 + v248;	// L252, [51,56)
    double v250 = v1[((v5 * 104) + 87)];	// L253, [45,47)
    double v251 = v250 * v232;	// L254, [47,51)
    double v252 = v227 + v251;	// L255, [51,56)
    double v253 = v1[((v5 * 104) + 100)];	// L256, [45,47)
    double v254 = v253 * v232;	// L257, [47,51)
    double v255 = v230 + v254;	// L258, [51,56)
    double v256 = v1[((v5 * 104) + 10)];	// L259, [50,52)
    double v257 = v3[10];	// L260, [50,52)
    double v258 = v256 * v257;	// L261, [52,56)
    double v259 = v234 + v258;	// L262, [56,61)
    double v260 = v1[((v5 * 104) + 23)];	// L263, [50,52)
    double v261 = v260 * v257;	// L264, [52,56)
    double v262 = v237 + v261;	// L265, [56,61)
    double v263 = v1[((v5 * 104) + 36)];	// L266, [50,52)
    double v264 = v263 * v257;	// L267, [52,56)
    double v265 = v240 + v264;	// L268, [56,61)
    double v266 = v1[((v5 * 104) + 49)];	// L269, [50,52)
    double v267 = v266 * v257;	// L270, [52,56)
    double v268 = v243 + v267;	// L271, [56,61)
    double v269 = v1[((v5 * 104) + 62)];	// L272, [50,52)
    double v270 = v269 * v257;	// L273, [52,56)
    double v271 = v246 + v270;	// L274, [56,61)
    double v272 = v1[((v5 * 104) + 75)];	// L275, [50,52)
    double v273 = v272 * v257;	// L276, [52,56)
    double v274 = v249 + v273;	// L277, [56,61)
    double v275 = v1[((v5 * 104) + 88)];	// L278, [50,52)
    double v276 = v275 * v257;	// L279, [52,56)
    double v277 = v252 + v276;	// L280, [56,61)
    double v278 = v1[((v5 * 104) + 101)];	// L281, [50,52)
    double v279 = v278 * v257;	// L282, [52,56)
    double v280 = v255 + v279;	// L283, [56,61)
    double v281 = v1[((v5 * 104) + 11)];	// L284, [55,57)
    double v282 = v3[11];	// L285, [55,57)
    double v283 = v281 * v282;	// L286, [57,61)
    double v284 = v259 + v283;	// L287, [61,66)
    double v285 = v1[((v5 * 104) + 24)];	// L288, [55,57)
    double v286 = v285 * v282;	// L289, [57,61)
    double v287 = v262 + v286;	// L290, [61,66)
    double v288 = v1[((v5 * 104) + 37)];	// L291, [55,57)
    double v289 = v288 * v282;	// L292, [57,61)
    double v290 = v265 + v289;	// L293, [61,66)
    double v291 = v1[((v5 * 104) + 50)];	// L294, [55,57)
    double v292 = v291 * v282;	// L295, [57,61)
    double v293 = v268 + v292;	// L296, [61,66)
    double v294 = v1[((v5 * 104) + 63)];	// L297, [55,57)
    double v295 = v294 * v282;	// L298, [57,61)
    double v296 = v271 + v295;	// L299, [61,66)
    double v297 = v1[((v5 * 104) + 76)];	// L300, [55,57)
    double v298 = v297 * v282;	// L301, [57,61)
    double v299 = v274 + v298;	// L302, [61,66)
    double v300 = v1[((v5 * 104) + 89)];	// L303, [55,57)
    double v301 = v300 * v282;	// L304, [57,61)
    double v302 = v277 + v301;	// L305, [61,66)
    double v303 = v1[((v5 * 104) + 102)];	// L306, [55,57)
    double v304 = v303 * v282;	// L307, [57,61)
    double v305 = v280 + v304;	// L308, [61,66)
    double v306 = v1[((v5 * 104) + 12)];	// L309, [60,62)
    double v307 = v3[12];	// L310, [60,62)
    double v308 = v306 * v307;	// L311, [62,66)
    double v309 = v284 + v308;	// L312, [66,71)
    v2[(v5 * 8)] = v309;	// L313, [71,72)
    double v310 = v1[((v5 * 104) + 25)];	// L314, [60,62)
    double v311 = v310 * v307;	// L315, [62,66)
    double v312 = v287 + v311;	// L316, [66,71)
    v2[((v5 * 8) + 1)] = v312;	// L317, [71,72)
    double v313 = v1[((v5 * 104) + 38)];	// L318, [60,62)
    double v314 = v313 * v307;	// L319, [62,66)
    double v315 = v290 + v314;	// L320, [66,71)
    v2[((v5 * 8) + 2)] = v315;	// L321, [71,72)
    double v316 = v1[((v5 * 104) + 51)];	// L322, [60,62)
    double v317 = v316 * v307;	// L323, [62,66)
    double v318 = v293 + v317;	// L324, [66,71)
    v2[((v5 * 8) + 3)] = v318;	// L325, [71,72)
    double v319 = v1[((v5 * 104) + 64)];	// L326, [60,62)
    double v320 = v319 * v307;	// L327, [62,66)
    double v321 = v296 + v320;	// L328, [66,71)
    v2[((v5 * 8) + 4)] = v321;	// L329, [71,72)
    double v322 = v1[((v5 * 104) + 77)];	// L330, [60,62)
    double v323 = v322 * v307;	// L331, [62,66)
    double v324 = v299 + v323;	// L332, [66,71)
    v2[((v5 * 8) + 5)] = v324;	// L333, [71,72)
    double v325 = v1[((v5 * 104) + 90)];	// L334, [60,62)
    double v326 = v325 * v307;	// L335, [62,66)
    double v327 = v302 + v326;	// L336, [66,71)
    v2[((v5 * 8) + 6)] = v327;	// L337, [71,72)
    double v328 = v1[((v5 * 104) + 103)];	// L338, [60,62)
    double v329 = v328 * v307;	// L339, [62,66)
    double v330 = v305 + v329;	// L340, [66,71)
    v2[((v5 * 8) + 7)] = v330;	// L341, [71,72)
  }
  v4[0] = 42.424242;	// L343, [95,96)
}

