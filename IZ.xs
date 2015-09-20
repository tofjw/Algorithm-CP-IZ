#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <iz.h>

#include "const-c.inc"

typedef int array2index(CSint **allVars, int nbVars);

static array2index* currentArray2IndexFunc;
static SV* findFreeVarPerlFunc;

static CSint* findFreeVarWrapper(CSint **allVars, int nbVars)
{
  int idx = currentArray2IndexFunc(allVars, nbVars);
  if (idx < 0)
    return 0;

  return allVars[idx];
}

static int findFreeVarPerlWrapper(CSint **allVars, int nbVars)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  PUTBACK;
  int count = call_sv(findFreeVarPerlFunc, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("findFreeVarPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return ret;
}

static int findFreeVarDefault(CSint **allVars, int nbVars)
{
  int i;

  for (i=0; i<nbVars; i++) {
    if (cs_isFree(allVars[i]))
      return i;
  }

  return -1;
}

static int findFreeVarNbElements(CSint **allVars, int nbVars)
{
  int i;
  int ret = -1;
  int minElem = INT_MAX;

  for (i=0; i<nbVars; i++) {
    int nElem = cs_getNbElements(allVars[i]);
    if (nElem > 1 && nElem < minElem) {
      ret = i;
      minElem = nElem;
    }
  }

  return ret;
}

array2index* findFreeVarTbl[] = {
  findFreeVarDefault,
  findFreeVarNbElements,
};


static IZBOOL eventAllKnownPerlWrapper(CSint **tint, int size, void *ext)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  PUTBACK;
  int count = call_sv((SV*)ext, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("eventAllKnownPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return (IZBOOL)ret;
}

static IZBOOL eventKnownPerlWrapper(int val, int index, CSint **tint, int size, void *ext)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(val)));
  XPUSHs(sv_2mortal(newSViv(index)));

  PUTBACK;
  int count = call_sv((SV*)ext, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("eventKnownPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return (IZBOOL)ret;
}

static IZBOOL eventNewMinMaxNeqPerlWrapper(CSint* vint, int index, int oldValue, CSint **tint, int size, void *ext)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(index)));
  XPUSHs(sv_2mortal(newSViv(oldValue)));

  PUTBACK;
  int count = call_sv((SV*)ext, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("eventNewMinMaxNeqPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return (IZBOOL)ret;
}

MODULE = Algorithm::CP::IZ		PACKAGE = Algorithm::CP::IZ		

INCLUDE: const-xs.inc

void*
alloc_var_array(av)
    AV *av;
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);
    RETVAL = array;

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvRV(*pptr);
    }
OUTPUT:
    RETVAL

void*
alloc_int_array(av)
    AV *av;
PREINIT:
    int* array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, int);
    RETVAL = array;

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvIV(*pptr);
    }
OUTPUT:
    RETVAL


void
free_array(ptr)
    void* ptr;
CODE:
    Safefree(ptr);

void
cs_init()
CODE:
    cs_init();

void
cs_end()
CODE:
    cs_end();

int
cs_saveContext()
CODE:
    RETVAL = cs_saveContext();
OUTPUT:
    RETVAL

void
cs_restoreContext()
CODE:
    cs_restoreContext();

void
cs_restoreAll()
CODE:
    cs_restoreAll();

void*
cs_createCSint(min, max)
    int min
    int max
CODE:
    RETVAL = cs_createCSint(min, max);
OUTPUT:
    RETVAL

void*
cs_createCSintFromDomain(parray, size)
    void* parray
    int size
PREINIT:
	int i;
CODE:
    RETVAL = cs_createCSintFromDomain(parray, size);
OUTPUT:
    RETVAL

int
cs_search(av, func_id, func_ref, fail_max)
    AV *av
    int func_id
    SV* func_ref
    int fail_max
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvRV(*pptr);
    }

    currentArray2IndexFunc = 0;

    if (func_id < 0) {
      findFreeVarPerlFunc = SvRV(func_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (func_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("search: Bad FindFreeVar value");
	RETVAL = -1;
      }
      else {
	currentArray2IndexFunc = findFreeVarTbl[func_id];
      }
    }

    if (currentArray2IndexFunc) {
      if (fail_max < 0)
	fail_max = INT_MAX;

      RETVAL = cs_searchFail((CSint**)array,
			     (int)alen, findFreeVarWrapper, fail_max);
      Safefree(array);
    }
OUTPUT:
    RETVAL


int
cs_search_findFreeVar(av, func_ref, fail_max)
    AV *av;
    SV* func_ref;
    int fail_max;
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvRV(*pptr);
    }

    findFreeVarPerlFunc = SvRV(func_ref);
    currentArray2IndexFunc = findFreeVarPerlWrapper;
    if (fail_max < 0)
      fail_max = INT_MAX;

    RETVAL = cs_searchFail((CSint**)array,
			   (int)alen, findFreeVarWrapper, fail_max);
    Safefree(array);
OUTPUT:
    RETVAL


int
cs_eventAllKnown(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    RETVAL = cs_eventAllKnown(tint, size,
			      eventAllKnownPerlWrapper, SvRV(handler));
OUTPUT:
    RETVAL

int
cs_eventKnown(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    RETVAL = cs_eventKnown(tint, size,
			   eventKnownPerlWrapper, SvRV(handler));
OUTPUT:
    RETVAL

void
cs_eventNewMin(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    cs_eventNewMin(tint, size,
		   eventNewMinMaxNeqPerlWrapper, SvRV(handler));

void
cs_eventNewMax(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    cs_eventNewMax(tint, size,
		   eventNewMinMaxNeqPerlWrapper, SvRV(handler));

void
cs_eventNeq(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    cs_eventNeq(tint, size,
		eventNewMinMaxNeqPerlWrapper, SvRV(handler));

int
cs_getNbElements(vint)
    void* vint
CODE:
    RETVAL = cs_getNbElements(vint);
OUTPUT:
    RETVAL

int
cs_getMin(vint)
    void* vint
CODE:
    RETVAL = cs_getMin(vint);
OUTPUT:
    RETVAL

int
cs_getMax(vint)
    void* vint
CODE:
    RETVAL = cs_getMax(vint);
OUTPUT:
    RETVAL

int
cs_getValue(vint)
    void* vint
CODE:
    if (cs_isFree(vint))
      croak("variable is not unstantiated.");

    RETVAL = cs_getValue(vint);
OUTPUT:
    RETVAL

int
cs_isIn(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_isIn(vint, val);
OUTPUT:
    RETVAL

int
cs_isFree(vint)
    void* vint
CODE:
    RETVAL = cs_isFree(vint);
OUTPUT:
    RETVAL

int
cs_isInstantiated(vint)
    void* vint
CODE:
    RETVAL = cs_isInstantiated(vint);
OUTPUT:
    RETVAL

void
cs_domain(vint, av)
    void* vint
    AV *av
PREINIT:
    int i;
    int* dom = cs_getDomain(vint);
    int n = cs_getNbElements(vint);
CODE:
    for (i = 0; i < n; i++) {
      av_store(av, i, newSViv(dom[i]));
    }
    free(dom);    

int
cs_getNextValue(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_getNextValue(vint, val);
OUTPUT:
    RETVAL

int
cs_getPreviousValue(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_getPreviousValue(vint, val);
OUTPUT:
    RETVAL

int
cs_is_in(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_isIn(vint, val);
OUTPUT:
    RETVAL

int
cs_AllNeq(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_AllNeq(tint, size);
OUTPUT:
    RETVAL

int
cs_EQ(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_EQ(vint, val);
OUTPUT:
    RETVAL

int
cs_Eq(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Eq(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_NEQ(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_NEQ(vint, val);
OUTPUT:
    RETVAL

int
cs_Neq(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Neq(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_LE(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_LE(vint, val);
OUTPUT:
    RETVAL

int
cs_Le(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Le(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_LT(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_LT(vint, val);
OUTPUT:
    RETVAL

int
cs_Lt(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Lt(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_GE(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_GE(vint, val);
OUTPUT:
    RETVAL

int
cs_Ge(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Ge(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_GT(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_GT(vint, val);
OUTPUT:
    RETVAL

int
cs_Gt(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Gt(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Add(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Add(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_ScalProd(vars, coeffs, n)
    void* vars
    void* coeffs
    int n
CODE:
    RETVAL = cs_ScalProd(vars, coeffs, n);
OUTPUT:
    RETVAL
