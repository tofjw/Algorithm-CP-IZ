#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!C:\Strawberry\perl\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(CS_ERR_GETVALUE CS_ERR_NONE CS_INT_MAX CS_INT_MIN FALSE TRUE
	       __izwindllexport));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Algorithm::CP::IZ", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Algorithm::CP::IZ", $types);
__END__
   */

  switch (len) {
  case 4:
    if (memEQ(name, "TRUE", 4)) {
#ifdef TRUE
      *iv_return = TRUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 5:
    if (memEQ(name, "FALSE", 5)) {
#ifdef FALSE
      *iv_return = FALSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    /* Names all of length 10.  */
    /* CS_INT_MAX CS_INT_MIN */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'A':
      if (memEQ(name, "CS_INT_MAX", 10)) {
      /*                       ^        */
#ifdef CS_INT_MAX
        *iv_return = CS_INT_MAX;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "CS_INT_MIN", 10)) {
      /*                       ^        */
#ifdef CS_INT_MIN
        *iv_return = CS_INT_MIN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    if (memEQ(name, "CS_ERR_NONE", 11)) {
#ifdef CS_ERR_NONE
      *iv_return = CS_ERR_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    if (memEQ(name, "CS_ERR_GETVALUE", 15)) {
#ifdef CS_ERR_GETVALUE
      *iv_return = CS_ERR_GETVALUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    if (memEQ(name, "__izwindllexport", 16)) {
#ifdef __izwindllexport
      *iv_return = __izwindllexport;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

