#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "utils-exp.h"
#include "stats-int.h"


/* From _Numerical Recipes in C_, p. 626 */
static float probks(alam)
float alam;
{
   int j;
   float a2, fac = 2.0, sum = 0.0, term, termbf = 0.0;

   a2 = -2.0 * alam * alam;
   for (j = 1; j <= 100; ++j)
   {
      term = fac * exp(a2 * j * j);
      sum += term;
      if (fabs((double) term) <= EPS1 * termbf || 
	  fabs((double) term) <= EPS2 * sum)
	 return(sum);
      fac = - fac;
      termbf = fabs((double) term);
   }

   /* failed to converge */
   return(1.0);
}


/* From _Numerical Recipes in C_, p. 625 */
void  kolomogorov_smirnov(data1, n1, data2, n2, d, prob)
float data1[];
int n1;
float data2[];
int n2;
float *d;
float *prob;
{
   int j1 = 0, j2 = 0;
   float d1, d2, dt, en1, en2, en, fn1 = 0.0, fn2 = 0.0;

   qsort((char *) data1, n1, sizeof(float), float_compare);
   qsort((char *) data2, n2, sizeof(float), float_compare);

   en1 = n1;
   en2 = n2;
   *d = 0.0;

   while (j1 < n1 && j2 < n2)
   {
      if ((d1 = data1[j1]) <= (d2 = data2[j2]))
      {
	 fn1 = 1.0 * (j1 + 1) / en1;
	 ++j1;
      }

      if (d2 <= d1)
      {
	 fn2 = 1.0 * (j2 + 1) / en2;
	 ++j2;
      }

      if ((dt = fabs(fn2 - fn1)) > *d)
	 *d = dt;
   }

   en = sqrt(en1 * en2 / (en1 + en2));
   *prob = probks((en + 0.12 + 0.11 / en) * (*d));
}


/* From _Numerical Recipes in C_, p. 214 */
static float gammln(z)
float z;
{
   double x, y, temp, ser;
   int i;
   static double cof[6] = {76.18009172947146, -86.50532032941677,
			   24.01409824083091, -1.231739572450155,
			   0.1208650973866179e-2, -0.5395239384953e-5};

   y = x = z;
   temp = x + 5.5;
   temp -= (x + 0.5) * log(temp);
   ser = 1.000000000190015;
   for (i = 0; i < 6; ++i)
      ser += cof[i] / ++y;
   return(-temp + log(2.5066282746310005 * ser / x));
}


/* From _Numerical Recipes in C_, p. 218 */
static void gser(gamser, a, x, gln)
float *gamser;
float a;
float x;
float *gln;
{
   int n;
   float sum, del, ap;

   *gln = gammln(a);
   if (x <= 0.0)
   {
      if (x < 0.0)
	 error("system error", "x less than 0 in gser", TRUE);
      *gamser = 0.0;
      return;
   }
   else
   {
      ap = a;
      del = sum = 1.0 / a;
      for (n = 0; n < ITMAX; ++n)
      {
	 ++ap;
	 del *= x / ap;
	 sum += del;
	 if (fabs(del) < fabs(sum) * EPS)
	 {
	    *gamser = sum * exp(-x + a * log(x) - (*gln));
	    return;
	 }
      }

      error("system error", "a too large, ITMAX too small in gser", TRUE);
      return;
   }
}


/* From _Numerical Recipes in C_, p. 219 */
static void gcf(gammcf, a, x, gln)
float *gammcf;
float a;
float x;
float *gln;
{
   int i;
   float an, b, c, d, del, h;

   *gln = gammln(a);
   b = x + 1.0 - a;
   c = 1.0 / FPMIN;
   d = 1.0 / b;
   h = d;
   for (i = 0; i < ITMAX; ++i)
   {
      an = -i * (i - a);
      b += 2.0;
      d = an * d + b;
      if (fabs(d) < FPMIN)
	 d = FPMIN;
      c = b + an / c;
      if (fabs(c) < FPMIN)
	 c = FPMIN;
      d = 1.0 / d;
      del = d * c;
      h *= del;
      if (fabs(del - 1.0) < EPS)
	 break;
   }

   if (i > ITMAX)
      error("system error", "a too large, ITMAX too small in gcf", TRUE);

   *gammcf = exp(-x + a * log(x) - (*gln)) * h;
}


/* From _Numerical Recipes in C_, p. 218 */
static float gammq(a, x)
float a;
float x;
{
   float gamser, gammcf, gln;

   if (x < 0.0 || a <= 0.0)
      error("system error", "gammq called with bad arguments", TRUE);

   if (x < (a + 1.0))
   {
      gser(&gamser, a, x, &gln);
      return(1.0 - gamser);
   }
   else
   {
      gcf(&gammcf, a, x, &gln);
      return(gammcf);
   }
}


/* From _Numerical Recipes in C_, p. 622 */
void chi_square(bins_1, bins_2, num_bins, constraints, degrees,
		chi_square_value, prob)
float bins_1[];
float bins_2[];
int num_bins;
int constraints;
int *degrees;
float *chi_square_value;
float *prob;
{
   int i;
   float temp;

   *degrees = num_bins - constraints;
   *chi_square_value = 0.0;

   for (i = 0; i < num_bins; ++i)
   {
      if (bins_1[i] == 0.0 && bins_2[i] == 0.0)
         --*degrees;
      else
      {
	 temp = bins_1[i] - bins_2[i];
	 *chi_square_value += temp * temp / (bins_1[i] + bins_2[i]);
      }
   }

   *prob = gammq(0.5 * *degrees, 0.5 * *chi_square_value);
}




/* From _Numerical Recipes in C_, p. 623 */
void chi_square_unequal(bins_1, bins_2, num_bins, constraints, degrees,
		        chi_square_value, prob)
float bins_1[];
float bins_2[];
int num_bins;
int constraints;
int *degrees;
float *chi_square_value;
float *prob;
{
   int i;
   float temp;
   float sum_bins_1, sum_bins_2;
   float a, b;

   *degrees = num_bins - constraints;
   *chi_square_value = 0.0;

   sum_bins_1 = sum_bins_2 = 0.0;
   for (i = 0; i < num_bins; ++i)
   {
      sum_bins_1 += bins_1[i];
      sum_bins_2 += bins_2[i];
   }
   a = sqrt((double) sum_bins_2 / sum_bins_1);
   b = sqrt((double) sum_bins_1 / sum_bins_2);

   for (i = 0; i < num_bins; ++i)
   {
      if (bins_1[i] == 0.0 && bins_2[i] == 0.0)
         --*degrees;
      else
      {
	 temp = a * bins_1[i] - b * bins_2[i];
	 *chi_square_value += temp * temp / (bins_1[i] + bins_2[i]);
      }
   }

   *prob = gammq(0.5 * *degrees, 0.5 * *chi_square_value);
}

