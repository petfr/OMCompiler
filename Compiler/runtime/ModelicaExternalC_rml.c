/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "rml.h"
#include "memory_pool.h"
#include "meta_modelica.h"

void (*omc_assert)(threadData_t*,FILE_INFO info,const char *msg,...) __attribute__ ((noreturn)) = omc_assert_function;
void (*omc_terminate)(FILE_INFO info,const char *msg,...) = omc_terminate_function;
void (*omc_throw)(threadData_t*) __attribute__ ((noreturn)) = omc_throw_function;

void ModelicaInternal_print(const char*,const char*);
const char* ModelicaInternal_readLine(const char*,int,int*);
int ModelicaInternal_countLines(const char*);
const char* ModelicaInternal_fullPathName(const char*);
int ModelicaInternal_stat(const char*);
void ModelicaStreams_closeFile(const char*);
int ModelicaStrings_compare(const char*,const char*,int);
void ModelicaStrings_scanReal(const char*,int,int,int*,double*);
int ModelicaStrings_skipWhiteSpace(const char*,int);

void ModelicaExternalC_5finit(void)
{
}

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fprint)
{
  int fail=1;
  char* str = RML_STRINGDATA(rmlA0);
  char* fileName = RML_STRINGDATA(rmlA1);
  MMC_TRY_TOP();
    ModelicaInternal_print(str,fileName);
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5freadLine)
{
  char* fileName = RML_STRINGDATA(rmlA0), *res = 0;
  long line = RML_UNTAGFIXNUM(rmlA1);
  int endOfFile = 0, fail = 1;
  MMC_TRY_TOP();
    res = (char*)ModelicaInternal_readLine(fileName,line,&endOfFile);
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(res);
  rmlA1 = mk_icon(endOfFile);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fcountLines)
{
  int fail = 1;
  char* fileName = RML_STRINGDATA(rmlA0);
  MMC_TRY_TOP();
    rmlA0 = mk_icon(ModelicaInternal_countLines(fileName));
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__File_5ffullPathName)
{
  char* fileName = RML_STRINGDATA(rmlA0), *res = 0;
  int fail = 1;
  MMC_TRY_TOP();
    res = (char*)ModelicaInternal_fullPathName(fileName);
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_scon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__File_5fstat)
{
  char* name = RML_STRINGDATA(rmlA0);
  int res = 0, fail = 1;
  MMC_TRY_TOP();
    res = ModelicaInternal_stat(name);
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(res);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Streams_5fclose)
{
  char* fileName = RML_STRINGDATA(rmlA0);
  int fail = 1;
  MMC_TRY_TOP();
    ModelicaStreams_closeFile(fileName);
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Strings_5fcompare)
{
  char* str1 = RML_STRINGDATA(rmlA0);
  char* str2 = RML_STRINGDATA(rmlA1);
  int i = RML_UNTAGFIXNUM(rmlA2), fail = 1;
  MMC_TRY_TOP();
    i = ModelicaStrings_compare(str1,str2,i);
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(i);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Strings_5fadvanced_5fscanReal)
{
  char* str = RML_STRINGDATA(rmlA0);
  int i = RML_UNTAGFIXNUM(rmlA1);
  int unsign = RML_UNTAGFIXNUM(rmlA2);
  int next_ix=0, fail=1;
  double val=0;
  MMC_TRY_TOP();
    ModelicaStrings_scanReal(str,i,unsign,&next_ix,&val);
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  rmlA0 = mk_icon(next_ix);
  rmlA1 = mk_rcon(val);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(ModelicaExternalC__Strings_5fadvanced_5fskipWhiteSpace)
{
  char* str = RML_STRINGDATA(rmlA0);
  int i = RML_UNTAGFIXNUM(rmlA1), fail = 1;
  MMC_TRY_TOP();
    rmlA0 = mk_icon(ModelicaStrings_skipWhiteSpace(str,i));
    fail = 0;
  MMC_CATCH_TOP();
  if (fail) RML_TAILCALLK(rmlFC);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
