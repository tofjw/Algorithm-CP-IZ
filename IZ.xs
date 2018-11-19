#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <iz.h>

#include "const-c.inc"

static const char* PACKAGE_INT = "Algorithm::CP::IZ::Int";

/*
 * Helper functinos for cs_search, cs_searchCriteria, cs_findAll
 */

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

static SV* criteriaPerlFunc;

static int criteriaPerlWrapper(int index, int val)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(index)));
  XPUSHs(sv_2mortal(newSViv(val)));

  PUTBACK;
  int count = call_sv(criteriaPerlFunc, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("criteriaPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return ret;
}

/*
 * Helper functinos for cs_findAll
 */
static SV* foundPerlFunc;

static void foundPerlWrapper(CSint **allVars, int nbVars)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  PUTBACK;
  call_sv(foundPerlFunc, G_VOID);
  SPAGAIN;

  FREETMPS;
  LEAVE;
}

/*
 * Helper functinos for cs_backtrack
 */

typedef void backtrackCallback(CSint *vint, int index);

static SV* backtrackPerlFunc;

static void backtrackPerlWrapper(CSint *vint, int index)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  /* index is pointing to context in perl code */
  XPUSHs(sv_2mortal(newSViv(index)));

  PUTBACK;
  call_sv(backtrackPerlFunc, G_VOID);
  SPAGAIN;

  FREETMPS;
  LEAVE;
}

/*
 * Helper functinos for demon funcrions
 */

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



#if (IZ_VERSION_MAJOR == 3 && IZ_VERSION_MINOR >= 6)

/* Helper functions for Algorithm::CP::IZ::ValueSelector::Simple */

/*
 * Callback functions don't take class parameter therefore useer defined
 * value selectors distincted by its index (when search function is called).
 */

typedef struct {
  SV* init;
  SV* next;
  SV* end;
} vsSimple;

static vsSimple* vsSimpleArray = NULL;
static size_t vsSimpleArraySize = 0;

static int vsSimpleObjRef = 0;
static CSvalueSelector* vsSimpleObj = NULL;

static IZBOOL prepareSimpleVS(int index) {
  if (!vsSimpleArray) {
    size_t size = (size_t)index * 2;
    size_t i;

    if (size < 1000)
      size = 1000;

    Newx(vsSimpleArray, size, vsSimple);
    if (!vsSimpleArray)
      return FALSE;

    vsSimpleArraySize = size;

    for (i = 0; i < size; i++) {
      vsSimpleArray[i].init = NULL;
      vsSimpleArray[i].next = NULL;
      vsSimpleArray[i].end = NULL;
    }
  }
  else {
    size_t newSize = vsSimpleArraySize + 1000;
    size_t i;

    vsSimple* newArray;
    Newx(newArray, newSize, vsSimple);
    if (!newArray)
      return FALSE;

    memcpy(newArray, vsSimpleArray, sizeof(vsSimple) * vsSimpleArraySize);

    for (i = vsSimpleArraySize; i < newSize; i++) {
      newArray[i].init = NULL;
      newArray[i].next = NULL;
      newArray[i].end = NULL;
    }

    Safefree(vsSimpleArray);
    vsSimpleArray = newArray;
    vsSimpleArraySize = newSize;
  }

  return TRUE;
}

static IZBOOL vsSimpleInit(int index, CSint** vars, int size, void* pData) {
  void** pp = (void**)pData;
  SV* obj = NULL;

  {
    SV* paramVar;
    int count;

    dTHX;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    paramVar = sv_newmortal();
    sv_setuv(newSVrv(paramVar, PACKAGE_INT), (UV)vars[index]);
    XPUSHs(paramVar);
    XPUSHs(sv_2mortal(newSViv(index)));

    PUTBACK;
    if (vsSimpleArray[index].init)
      count = call_sv(vsSimpleArray[index].init, G_ARRAY);
    else
      count = 0;

    SPAGAIN;

    if (count > 0) {
      obj = POPs;
      SvREFCNT_inc(obj);
      PUTBACK;
    }

    FREETMPS;
    LEAVE;
  }

  if (!obj)
    return FALSE;

  *pp = obj;

  return TRUE;
}

static IZBOOL vsSimpleNext(CSvalueSelection* r, int index, CSint** vars, int size, void* pData) {
  void** pp = (void**)pData;
  SV* obj = (SV*)*pp;
  IZBOOL ret;

  {
    SV* paramVar;
    int count;

    dTHX;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    paramVar = sv_newmortal();
    sv_setuv(newSVrv(paramVar, PACKAGE_INT), (UV)vars[index]);
    XPUSHs(obj);
    XPUSHs(paramVar);
    XPUSHs(sv_2mortal(newSViv(index)));

    PUTBACK;
    count = call_method("next", G_ARRAY);
    SPAGAIN;

    if (count >= 2) {
      r->value = POPi;
      r->method = POPi;
      ret = TRUE;
    }
    else {
      ret = FALSE;
    }

    PUTBACK;

    FREETMPS;
    LEAVE;
  }

  return ret;
}

static IZBOOL vsSimpleEnd(int index, CSint** vars, int size, void* pData) {
  void** pp = (void**)pData;
  SV* obj = (SV*)*pp;

  {
    dTHX;
    SvREFCNT_dec(obj);
  }

  return TRUE;
}

static SV* maxFailPerlFunc;
static int maxFailFuncPerlWrapper(void* dummy)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  PUTBACK;
  int count = call_sv(maxFailPerlFunc, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count < 0) {
    croak("maxFailFuncPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return ret;
}

static IZBOOL noGoodSetPrefilterPerlWrapper(CSnoGoodSet* ngs, CSnoGood* ng, CSint** vars, int size, void* ext)
{
  SV* ngsObj = (SV*)ext;
  IZBOOL ret = FALSE;

  {
    int i, n;
    AV* elements;
    SV* r;
    HV* ngeh;

    dTHX;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(ngsObj);

    elements = newAV();
    n = cs_getNbNoGoodElements(ng);
    ngeh = gv_stashpv("Algorithm::CP::IZ::NoGoodElement", 0);

    for (i = 0; i < n; i++) {
      AV* elem = newAV();
      int idx;
      CSvalueSelection vs;

      cs_getNoGoodElementAt(&idx, &vs, ng, i);
      av_push(elem, newSViv(idx));
      av_push(elem, newSViv(vs.method));
      av_push(elem, newSViv(vs.value));

      r = (SV*)newRV_noinc((SV*)elem);
      r = sv_bless(r, ngeh);
      av_push(elements, r);
    }

    r = newRV_noinc((SV*)elements);
    XPUSHs((SV*)r);

    PUTBACK;
    {
      int count = call_method("_prefilter", G_ARRAY);
      SPAGAIN;
      if (count > 0) {
	ret = POPi;
      }
    }

    FREETMPS;
    LEAVE;
  }

  return ret;
}

static void noGoodSetDestoryPerlWrapper(CSnoGoodSet* ngs, void* ext)
{
  SV* ngsObj = (SV*)ext;

  {
    dTHX;
    dSP;

    ENTER;
    SAVETMPS;

    SvREFCNT_dec(ngsObj);

    FREETMPS;
    LEAVE;
  }
}

#endif /* (IZ_VERSION_MAJOR == 3 && IZ_VERSION_MINOR >= 6) */

MODULE = Algorithm::CP::IZ		PACKAGE = Algorithm::CP::IZ		

INCLUDE: const-xs.inc

INCLUDE: cs_vadd.inc
INCLUDE: cs_vmul.inc
INCLUDE: cs_vsub.inc
INCLUDE: cs_reif2.inc

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
      array[i] = (void*)SvUV(*pptr);
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
cs_restoreContextUntil(label)
    int label
CODE:
    cs_restoreContextUntil(label);

void
cs_restoreAll()
CODE:
    cs_restoreAll();

void
cs_acceptContext()
CODE:
    cs_acceptContext();

void
cs_acceptAll()
CODE:
    cs_acceptAll();

int get_nb_fails(iz)
    void* iz
CODE:
    RETVAL = cs_getNbFails();
OUTPUT:
    RETVAL

int get_nb_choice_points(iz)
    void* iz
CODE:
    RETVAL = cs_getNbChoicePoints();
OUTPUT:
    RETVAL

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
CODE:
    if (size <= 0)
        RETVAL = 0;
    else
        RETVAL = cs_createCSintFromDomain(parray, size);
OUTPUT:
    RETVAL

int
cs_search(av, func_id, func_ref, max_fail)
    AV *av
    int func_id
    SV* func_ref
    int max_fail
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = (void*)SvUV(*pptr);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;

    if (func_id < 0) {
      findFreeVarPerlFunc = SvRV(func_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (func_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("search: Bad FindFreeVar value");
      }
      currentArray2IndexFunc = findFreeVarTbl[func_id];
    }

    if (max_fail < 0)
      max_fail = INT_MAX;

    RETVAL = cs_searchFail((CSint**)array,
			   (int)alen, findFreeVarWrapper, max_fail);
    Safefree(array);
OUTPUT:
    RETVAL

int
cs_searchCriteria(av, findvar_id, findvar_ref, criteria_ref, max_fail)
    AV *av
    int findvar_id
    SV* findvar_ref
    SV* criteria_ref
    int max_fail
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = (void*)SvUV(*pptr);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;
    criteriaPerlFunc = SvRV(criteria_ref);

    if (findvar_id < 0) {
      findFreeVarPerlFunc = SvRV(findvar_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (findvar_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("search: Bad FindFreeVar value");
      }
      currentArray2IndexFunc = findFreeVarTbl[findvar_id];
    }

    if (max_fail < 0)
        max_fail = INT_MAX;

    RETVAL = cs_searchCriteriaFail((CSint**)array,
				   (int)alen,
				   currentArray2IndexFunc,
				   criteriaPerlWrapper,
				   max_fail);
    Safefree(array);
OUTPUT:
    RETVAL

int
cs_findAll(av, findvar_id, findvar_ref, found_ref)
    AV *av
    int findvar_id
    SV* findvar_ref
    SV* found_ref
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = (void*)SvUV(*pptr);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;

    foundPerlFunc = SvRV(found_ref);

    if (findvar_id < 0) {
      findFreeVarPerlFunc = SvRV(findvar_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (findvar_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("findAll: Bad FindFreeVar value");
      }

      currentArray2IndexFunc = findFreeVarTbl[findvar_id];
    }

    RETVAL = cs_findAll((CSint**)array, (int)alen,
			findFreeVarWrapper, foundPerlWrapper);
    Safefree(array);
OUTPUT:
    RETVAL

void
cs_backtrack(vint, index, handler)
  void* vint
  int index
  SV* handler
CODE:
  backtrackPerlFunc = SvRV(handler);
  cs_backtrack(vint, index, backtrackPerlWrapper);

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
cs_AllNeq(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_AllNeq(tint, size);
OUTPUT:
    RETVAL

int
cs_InArray(vint, array, size)
    void* vint
    void* array
    int size
CODE:
    RETVAL = cs_InArray(vint, array, size);
OUTPUT:
    RETVAL

int
cs_NotInArray(vint, array, size)
    void* vint
    void* array
    int size
CODE:
    RETVAL = cs_NotInArray(vint, array, size);
OUTPUT:
    RETVAL

int
cs_InInterval(vint, minVal, maxVal)
    void* vint
    int minVal
    int maxVal
CODE:
    RETVAL = cs_InInterval(vint, minVal, maxVal);
OUTPUT:
    RETVAL

int
cs_NotInInterval(vint, minVal, maxVal)
    void* vint
    int minVal
    int maxVal
CODE:
    RETVAL = cs_NotInInterval(vint, minVal, maxVal);
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
cs_Mul(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Mul(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Sub(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Sub(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Div(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Div(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Sigma(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_Sigma(tint, size);
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

void*
cs_Abs(vint)
    void* vint
CODE:
    RETVAL = cs_Abs(vint);
OUTPUT:
    RETVAL

void*
cs_Min(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_Min(tint, size);
OUTPUT:
    RETVAL

void*
cs_Max(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_Max(tint, size);
OUTPUT:
    RETVAL

int
cs_IfEq(vint1, vint2, val1, val2)
    void* vint1
    void* vint2
    int val1
    int val2
CODE:
    RETVAL = cs_IfEq(vint1, vint2, val1, val2);
OUTPUT:
    RETVAL

int
cs_IfNeq(vint1, vint2, val1, val2)
    void* vint1
    void* vint2
    int val1
    int val2
CODE:
    RETVAL = cs_IfNeq(vint1, vint2, val1, val2);
OUTPUT:
    RETVAL

void*
cs_OccurDomain(val, array, size)
    int val
    void* array
    int size
CODE:
    RETVAL = cs_OccurDomain(val, array, size);
OUTPUT:
    RETVAL

int
cs_OccurConstraints(vint, val, array, size)
    void* vint
    int val
    void* array
    int size
CODE:
    RETVAL = cs_OccurConstraints(vint, val, array, size);
OUTPUT:
    RETVAL

void*
cs_Index(array, size, val)
    void* array
    int size
    int val
CODE:
    RETVAL = cs_Index(array, size, val);
OUTPUT:
    RETVAL

void*
cs_Element(index, values, size)
    void* index
    void* values
    int size
CODE:
    RETVAL = cs_Element(index, values, size);
OUTPUT:
    RETVAL

void*
cs_VarElement(index, values, size)
    void* index
    void* values
    int size
CODE:
    RETVAL = cs_VarElement(index, values, size);
OUTPUT:
    RETVAL

void*
cs_VarElementRange(index, values, size)
    void* index
    void* values
    int size
CODE:
    RETVAL = cs_VarElementRange(index, values, size);
OUTPUT:
    RETVAL

int
cs_Cumulative(s, d, r, size, limit)
    void* s
    void* d
    void* r
    int size
    void* limit
CODE:
    RETVAL = cs_Cumulative(s, d, r, size, limit);
OUTPUT:
    RETVAL

int
cs_Disjunctive(s, d, size)
    void* s
    void* d
    int size
CODE:
    RETVAL = cs_Disjunctive(s, d, size);
OUTPUT:
    RETVAL

int
iz_getEndValue(vint, val)
    void* vint
    int val
PREINIT:
    int maxValue;
    int prev;
    int cur;
CODE:
    maxValue = cs_getMax(vint);
    if (val >= maxValue) {
        RETVAL = maxValue;
    }
    else if (cs_isIn(vint, val)) {
        cur = val;

	while (1) {
	    if (cur == maxValue) {
	        RETVAL = maxValue;
		break;
	    }

	    prev = cur;
	    cur++;
	    if (!cs_isIn(vint, cur)) {
	        RETVAL = prev;
		break;
	    }
	}
    }
    else {
        RETVAL = cs_getNextValue(vint, val);
    }
OUTPUT:
    RETVAL

#if (IZ_VERSION_MAJOR == 3 && IZ_VERSION_MINOR >= 6)

void
cancel_search(iz)
    void* iz
CODE:
    cs_cancelSearch();

void*
cs_getValueSelector(vs)
    int vs
CODE:
    RETVAL = (void*)cs_getValueSelector(vs);
OUTPUT:
    RETVAL

void*
valueSelector_init(vs, index, array, size)
    void* vs;
    int index
    void* array
    int size
PREINIT:
    void* ext;
CODE:
    if (sizeof(void*) > sizeof(int))
      Newx(ext, 1, void*);
    else
      Newx(ext, 1, int);
    if (ext) {
      cs_initValueSelector(vs, index, array, size, ext);
    }
    RETVAL = ext;
OUTPUT:
    RETVAL

void
cs_selectNextValue(vs, index, array, size, ext)
    void* vs
    int index
    void* array
    int size
    void* ext
PREINIT:
    CSvalueSelection r;
    int rc;
PPCODE:
    rc = cs_selectNextValue(&r, vs, index, array, size, ext);
    if (rc) {
      XPUSHs(sv_2mortal(newSViv(r.method)));
      XPUSHs(sv_2mortal(newSViv(r.value)));
    }
    
int
cs_endValueSelector(vs, index, array, size, ext)
    void* vs
    int index
    void* array
    int size
    void* ext
PREINIT:
    int rc;
CODE:
    rc = cs_endValueSelector(vs, index, array, size, ext);
    Safefree(ext);
    RETVAL = rc;
OUTPUT:
    RETVAL

void*
createSimpleValueSelector()
CODE:
    if (vsSimpleObjRef == 0) {
      vsSimpleObj = cs_createValueSelector(vsSimpleInit, vsSimpleNext, vsSimpleEnd);
    }
    vsSimpleObjRef++;
    RETVAL = vsSimpleObj;
OUTPUT:
    RETVAL

void
deleteSimpleValueSelector()
CODE:
    vsSimpleObjRef--;

    if (vsSimpleObjRef == 0) {
      cs_freeValueSelector(vsSimpleObj);
      vsSimpleObj = NULL;

      if (vsSimpleArray) {
	Safefree(vsSimpleArray);
	vsSimpleArray = NULL;
	vsSimpleArraySize = 0;
      }
    }

int
registerSimpleValueSelectorClass(index, init)
     int index;
     SV* init;
CODE:
    if (prepareSimpleVS(index)) {
      vsSimpleArray[index].init = init;
      RETVAL = TRUE;
    }
    else {
      RETVAL = FALSE;
    }
OUTPUT:
    RETVAL

void*
cs_createNoGoodSet(av, size, prefilter_is_defined, max_no_good, ngsObj)
    void* av
    int size
    int prefilter_is_defined
    int max_no_good
    SV* ngsObj
CODE:
    SvREFCNT_inc(ngsObj);
    RETVAL = cs_createNoGoodSet(av, size,
				(prefilter_is_defined
				 ? noGoodSetPrefilterPerlWrapper : NULL),
				max_no_good,
				noGoodSetDestoryPerlWrapper, ngsObj);
OUTPUT:
    RETVAL


int
cs_getNbNoGoods(ngs)
    void* ngs
CODE:
    RETVAL = cs_getNbNoGoods(ngs);
OUTPUT:
    RETVAL

int
cs_searchValueSelectorFail(av, vs, findvar_id, findvar_ref, max_fail, nf_ref)
    AV *av
    AV *vs
    int findvar_id
    SV* findvar_ref
    int max_fail
    SV* nf_ref
PREINIT:
    void** array;
    void** vs_array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);
    Newx(vs_array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      SV** vsptr = av_fetch(vs, i, 0);
      SV** vsvs = hv_fetch((HV*)SvRV((*vsptr)), "_vs", 3, 0);

      array[i] = (void*)SvUV(*pptr);
      vs_array[i] = (void*)SvUV(*vsvs);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;

    if (findvar_id < 0) {
      findFreeVarPerlFunc = SvRV(findvar_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (findvar_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("search: Bad FindFreeVar value");
      }
      currentArray2IndexFunc = findFreeVarTbl[findvar_id];
    }

    if (max_fail < 0)
        max_fail = INT_MAX;

    RETVAL = cs_searchValueSelectorFail((CSint**)array,
					(const CSvalueSelector**)vs_array,
					(int)alen,
					currentArray2IndexFunc,
					max_fail,
					NULL);
    Safefree(array);
    Safefree(vs_array);
OUTPUT:
    RETVAL

int
cs_searchValueSelectorRestartNG(av, vs, findvar_id, findvar_ref, max_fail_func, max_fail, ngs, nf_ref)
    AV *av
    AV *vs
    int findvar_id
    SV* findvar_ref
    SV* max_fail_func
    int max_fail
    SV* ngs
    SV* nf_ref
PREINIT:
    void** array;
    void** vs_array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);
    Newx(vs_array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      SV** vsptr = av_fetch(vs, i, 0);
      SV** vsvs = hv_fetch((HV*)SvRV((*vsptr)), "_vs", 3, 0);

      array[i] = (void*)SvUV(*pptr);
      vs_array[i] = (void*)SvUV(*vsvs);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;

    if (findvar_id < 0) {
      findFreeVarPerlFunc = SvRV(findvar_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (findvar_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("search: Bad FindFreeVar value");
      }
      currentArray2IndexFunc = findFreeVarTbl[findvar_id];
    }

    if (max_fail < 0)
        max_fail = INT_MAX;

    maxFailPerlFunc = max_fail_func;

    RETVAL = cs_searchValueSelectorRestartNG((CSint**)array,
					     (const CSvalueSelector**)vs_array,
					     (int)alen,
					     currentArray2IndexFunc,
					     maxFailFuncPerlWrapper,
					     NULL,
					     max_fail,
					     (CSnoGoodSet*)SvUV(ngs),
					     NULL);
    Safefree(array);
    Safefree(vs_array);
OUTPUT:
    RETVAL


int
cs_selectValue(rv, method, value)
    SV *rv
    int method
    int value
PREINIT:
    void* vint;
    CSvalueSelection vs;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    vs.method = method;
    vs.value = value;
    RETVAL = cs_selectValue(vint, &vs);
OUTPUT:
    RETVAL


    
#endif /* (IZ_VERSION_MAJOR == 3 && IZ_VERSION_MINOR >= 6) */

MODULE = Algorithm::CP::IZ		PACKAGE = Algorithm::CP::IZ::Int

int
nb_elements(rv)
    SV* rv;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_getNbElements(vint);
OUTPUT:
    RETVAL

int
min(rv)
    SV* rv;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_getMin(vint);
OUTPUT:
    RETVAL

int
max(rv)
    SV* rv;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_getMax(vint);
OUTPUT:
    RETVAL

int
value(rv)
    SV* rv;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_getValue(vint);
OUTPUT:
    RETVAL

int
is_free(rv)
    SV* rv;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_isFree(vint);
OUTPUT:
    RETVAL

int
is_instantiated(rv)
    SV* rv;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_isInstantiated(vint);
OUTPUT:
    RETVAL

int
get_next_value(rv, val)
    SV* rv;
    int val;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_getNextValue(vint, val);
OUTPUT:
    RETVAL

int
get_previous_value(rv, val)
    SV* rv;
    int val;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_getPreviousValue(vint, val);
OUTPUT:
    RETVAL

int
is_in(rv, val)
    SV* rv;
    int val;
PREINIT:
    void* vint;
CODE:
    vint = (void*)SvUV(SvRV(rv));
    RETVAL = cs_isIn(vint, val);
OUTPUT:
    RETVAL

int
Eq(rv, val)
    SV* rv;
    SV* val;
PREINIT:
    void* vint1;
    void* vint2;
CODE:
    vint1 = (void*)SvUV(SvRV(rv));
    if (sv_isobject(val) && sv_derived_from(val, PACKAGE_INT)) {
        vint2 = (void*)SvUV(SvRV(val));
        RETVAL = cs_Eq(vint1, vint2);
    }
    else {
        RETVAL = cs_EQ(vint1, (int)SvIV(val));
    }
OUTPUT:
    RETVAL

int
Neq(rv, val)
    SV* rv;
    SV* val;
PREINIT:
    void* vint1;
    void* vint2;
CODE:
    vint1 = (void*)SvUV(SvRV(rv));
    if (sv_isobject(val) && sv_derived_from(val, PACKAGE_INT)) {
        vint2 = (void*)SvUV(SvRV(val));
        RETVAL = cs_Neq(vint1, vint2);
    }
    else {
        RETVAL = cs_NEQ(vint1, (int)SvIV(val));
    }
OUTPUT:
    RETVAL

int
Le(rv, val)
    SV* rv;
    SV* val;
PREINIT:
    void* vint1;
    void* vint2;
CODE:
    vint1 = (void*)SvUV(SvRV(rv));
    if (sv_isobject(val) && sv_derived_from(val, PACKAGE_INT)) {
        vint2 = (void*)SvUV(SvRV(val));
        RETVAL = cs_Le(vint1, vint2);
    }
    else {
        RETVAL = cs_LE(vint1, (int)SvIV(val));
    }
OUTPUT:
    RETVAL

int
Lt(rv, val)
    SV* rv;
    SV* val;
PREINIT:
    void* vint1;
    void* vint2;
CODE:
    vint1 = (void*)SvUV(SvRV(rv));
    if (sv_isobject(val) && sv_derived_from(val, PACKAGE_INT)) {
        vint2 = (void*)SvUV(SvRV(val));
        RETVAL = cs_Lt(vint1, vint2);
    }
    else {
        RETVAL = cs_LT(vint1, (int)SvIV(val));
    }
OUTPUT:
    RETVAL

int
Ge(rv, val)
    SV* rv;
    SV* val;
PREINIT:
    void* vint1;
    void* vint2;
CODE:
    vint1 = (void*)SvUV(SvRV(rv));
    if (sv_isobject(val) && sv_derived_from(val, PACKAGE_INT)) {
        vint2 = (void*)SvUV(SvRV(val));
        RETVAL = cs_Ge(vint1, vint2);
    }
    else {
        RETVAL = cs_GE(vint1, (int)SvIV(val));
    }
OUTPUT:
    RETVAL

int
Gt(rv, val)
    SV* rv;
    SV* val;
PREINIT:
    void* vint1;
    void* vint2;
CODE:
    vint1 = (void*)SvUV(SvRV(rv));
    if (sv_isobject(val) && sv_derived_from(val, PACKAGE_INT)) {
        vint2 = (void*)SvUV(SvRV(val));
        RETVAL = cs_Gt(vint1, vint2);
    }
    else {
        RETVAL = cs_GT(vint1, (int)SvIV(val));
    }
OUTPUT:
    RETVAL

AV *
domain(rv)
    SV* rv;
PREINIT:
    void* vint;
    int i;
    int val;
    int maxVal;
CODE:
    vint = (void*)SvUV(SvRV(rv));

    RETVAL = newAV();
    av_extend(RETVAL, cs_getNbElements(vint));

    maxVal = cs_getMax(vint);
    i = 0;
    for (val = cs_getMin(vint); val <= maxVal; val++) {
        if (!cs_isIn(vint, val)) continue;
        av_store(RETVAL, i++, newSViv(val));
    }
OUTPUT:
    RETVAL
