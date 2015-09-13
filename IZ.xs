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

array2index* findFreeVarTbl[] = {
  findFreeVarDefault,
};

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

int
cs_search_preset(av, func_id, fail_max)
    AV *av;
    int func_id;
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

    if (func_id < 0 || func_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0]))
      croak("bad fundFreeVar func_id");

    currentArray2IndexFunc = findFreeVarTbl[func_id];
    if (fail_max < 0)
      fail_max = INT_MAX;

    RETVAL = cs_searchFail((CSint**)array,
			   (int)alen, findFreeVarWrapper, fail_max);
    Safefree(array);
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

int
cs_AllNeq(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_AllNeq(tint, size);
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
