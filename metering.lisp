; metering the benchmarks
; 13-Oct-2016 SVS

(cl-bench.bignum:run-pari-200-5) is especially slow compared to SBCL.
Takes 20 seconds on CCL; .03 seconds (yes, point-oh-three) in SBCL.

(with-metering (+ * lcm ccl::lcm-2 gcd ccl::gcd-2 abs
                  ccl::%bignum-bignum-gcd
                  ccl::%positive-bignum-bignum-gcd
                  ccl::bignum-fixnum-gcd
                  ccl::bignum-compare
                  ccl::%alloc-misc
                  ccl::%copy-ivector-to-ivector ;; ccl::bignum-replace
                  ccl::bignum-subtract-loop
                  ccl::%bignum-count-trailing-zero-bits
                  ccl::%normalize-bignum-2 ;; %mostly-normalize-bignum-macro
                  )
  (:exclusive 0.0)
  (cl-bench.bignum:run-pari-200-5))


                                                     Cons
                            %     %                    Per      Total    Total
Function or Method       Time  Cons  Calls  Sec/Call  Call       Time     Cons
------------------------------------------------------------------------------
CCL::%BIGNUM-BIGNUM-GCD  0.99  0.03   1710  0.006937    39  11.862902    66720
CCL::LCM-2               0.01  0.92   3000  0.000027   710   0.080227  2129520
CCL::GCD-2               0.00  0.05   3001  0.000013    41   0.038053   123360
ABS                      0.00  0.00   3397  0.000001     0   0.004643        0
+                        0.00  0.00      2  0.000006     0   0.000012        0
------------------------------------------------------------------------------
Total:                   1.00  1.00  11110                  11.985837  2319600
Estimated total metering overhead: 0.026663 seconds
The following metered functions were not called:
 * GCD LCM

                                                                       Cons
                                          %     %                       Per       Total    Total
Function or Method                     Time  Cons     Calls  Sec/Call  Call        Time     Cons
------------------------------------------------------------------------------------------------
CCL::%BIGNUM-BIGNUM-GCD                0.74  0.01      1710  0.046242     7   79.074486    12720
CCL::BIGNUM-SUBTRACT-LOOP              0.11  0.00   3908295  0.000003     0   12.032583        0
CCL::%NORMALIZE-BIGNUM-2               0.10  0.00   7835460  0.000001     0   10.614283        0
CCL::%BIGNUM-COUNT-TRAILING-ZERO-BITS  0.05  0.00   3911715  0.000001     0    5.297104        0
CCL::LCM-2                             0.00  0.92      3000  0.000046   710    0.138124  2129520
CCL::BIGNUM-COMPARE                    0.00  0.00     57240  0.000001     0    0.079825        0
CCL::BIGNUM-FIXNUM-GCD                 0.00  0.08      2385  0.000020    74    0.048309   177360
CCL::GCD-2                             0.00  0.00      3001  0.000006     0    0.018078        0
CCL::%COPY-IVECTOR-TO-IVECTOR          0.00  0.00      3806  0.000002     0    0.007071        0
ABS                                    0.00  0.00      3000  0.000002     0    0.004796        0
+                                      0.00  0.00         2  0.000005     0    0.000009        0
------------------------------------------------------------------------------------------------
Total:                                 1.00  1.00  15729614                  107.314674  2319600
Estimated total metering overhead: 24.937103 seconds
The following metered functions were not called:
 %ALLOC-MISC * GCD LCM
NIL
