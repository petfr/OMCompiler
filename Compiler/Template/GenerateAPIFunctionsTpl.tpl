package GenerateAPIFunctionsTpl

import interface SimCodeTV;
import CodegenUtil.*;

template getCevalScriptInterface(list<DAE.Type> tys)
::=
  let funcs = tys |> ty as T_FUNCTION(source=path::_) => '<%getCevalScriptInterfaceFunc(pathLastIdent(path), ty.funcArg, ty.funcResultType)%><%\n%>'
  <<
  import Absyn;
  import CevalScript;
  import GlobalScript;
  import Parser;

  protected

  import Values;
  import ValuesUtil;
  constant Absyn.Msg dummyMsg = Absyn.MSG(SOURCEINFO("<interactive>",false,1,1,1,1,0.0));

  public

  <%funcs%>
  >>
end getCevalScriptInterface;

template getInType(DAE.Type ty)
::=
  match ty
    case T_STRING(__) then "String"
    case T_INTEGER(__) then "Integer"
    case T_BOOL(__) then "Boolean"
    case T_REAL(__) then "Real"
    case aty as T_ARRAY(__) then 'list<<%getInType(aty.ty)%>>'
    case T_CODE(ty=C_TYPENAME(__)) then "String"
    else error(sourceInfo(), 'getInType failed for <%unparseType(ty)%>')
end getInType;

template getInValue(Text name, DAE.Type ty)
::=
  match ty
    case T_STRING(__) then 'Values.STRING(<%name%>)'
    case T_INTEGER(__) then 'Values.INTEGER(<%name%>)'
    case T_BOOL(__) then 'Values.BOOL(<%name%>)'
    case T_REAL(__) then 'Values.REAL(<%name%>)'
    case aty as T_ARRAY(__) then 'ValuesUtil.makeArray(list(<%getInValue('<%name%>_iter', aty.ty)%> for <%name%>_iter in <%name%>))'
    case T_CODE(ty=C_TYPENAME(__)) then 'Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(<%name%>)))'
    else error(sourceInfo(), 'getInValue failed for <%unparseType(ty)%>')
end getInValue;

template getOutValue(Text name, DAE.Type ty, Text &varDecl, Text &postMatch)
::=
  match ty
    case T_STRING(__) then 'Values.STRING(<%name%>)'
    case T_INTEGER(__) then 'Values.INTEGER(<%name%>)'
    case T_BOOL(__) then 'Values.BOOL(<%name%>)'
    case T_REAL(__) then 'Values.REAL(<%name%>)'
    case aty as T_ARRAY(__) then
      let &varDecl += 'Values.Value <%name%>_arr;<%\n%>'
      let &postMatch += '<%name%> := <%getOutValueArray('<%name%>_arr', aty)%>;<%\n%>'
      '<%name%>_arr'

    case T_CODE(ty=C_TYPENAME(__)) then
      let &varDecl += 'Absyn.Path <%name%>_path;<%\n%>'
      let &postMatch += '<%name%> := Absyn.pathString(<%name%>_path);<%\n%>'
      'Values.CODE(Absyn.C_TYPENAME(path=<%name%>_path))'
    else error(sourceInfo(), 'getOutValue failed for <%unparseType(ty)%>')
end getOutValue;

template getOutValueArray(Text name, DAE.Type ty)
::=
  match ty
    case T_STRING(__) then 'match <%name%> case Values.STRING() then <%name%>.string; end match'
    case T_INTEGER(__) then 'match <%name%> case Values.INTEGER() then <%name%>.integer; end match'
    case T_BOOL(__) then 'match <%name%> case Values.BOOL() then <%name%>.boolean; end match'
    case T_REAL(__) then 'match <%name%> case Values.REAL() then <%name%>.real; end match'
    case aty as T_ARRAY(__) then
      'list(<%getOutValueArray('<%name%>_iter', aty.ty)%> for <%name%>_iter in ValuesUtil.arrayValues(<%name%>))'
    case T_CODE(ty=C_TYPENAME(__)) then
      'ValuesUtil.valString(<%name%>)'
    else error(sourceInfo(), 'getOutValueArray failed for <%unparseType(ty)%>')
end getOutValueArray;

template getCevalScriptInterfaceFunc(String name, list<DAE.FuncArg> args, DAE.Type res)
::=
  let &varDecl = buffer ""
  let &postMatch = buffer ""
  let inVals = args |> arg as FUNCARG(__) => getInValue(arg.name, arg.ty) ; separator=", "
  let outVals = match res
    case T_TUPLE(__) then 'Values.TUPLE({<%types |> ty hasindex i fromindex 1 => getOutValue('res<%i%>', ty, &varDecl, &postMatch) ; separator=", "%>})'
    case T_NORETCALL(__) then "Values.NORETCALL()"
    else '<%getOutValue("res", res, &varDecl, &postMatch)%>'
  <<
  function <%name%>
    input GlobalScript.SymbolTable st;
    <%args |> arg as FUNCARG(__) =>
      'input <%getInType(arg.ty)%> <%arg.name%>;' ; separator="\n" %>
    output GlobalScript.SymbolTable outSymTab;
    <%
    match res
    case T_TUPLE(__) then (types |> ty hasindex i fromindex 1 => 'output <%getInType(ty)%> res<%i%>;' ; separator="\n")
    case T_NORETCALL(__) then ""
    else 'output <%getInType(res)%> res;'
    %>
  <%if varDecl then
  <<
  protected
    <%varDecl%>
  >>
  %>
  algorithm
    (_,<%outVals%>,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "<%name%>", {<%inVals%>}, st, dummyMsg);
    <%postMatch%>
  end <%name%>;<%\n%>
  >>
end getCevalScriptInterfaceFunc;

template getQtInterface(list<DAE.Type> tys, String classNameWithColons, String className)
::=
  let funcs = tys |> ty as T_FUNCTION(source=path::_) => '<%getQtInterfaceFunc(pathLastIdent(path), ty.funcArg, ty.funcResultType, classNameWithColons)%><%\n%>'
  <<
  #include <stdexcept>
  #include "OpenModelicaScriptingAPIQt.h"

  <%classNameWithColons%><%className%>(threadData_t *td, void *symbolTable)
    : threadData(td), st(symbolTable)
  {
  }
  <%funcs%>
  >>
end getQtInterface;

template getQtInterfaceHeaders(list<DAE.Type> tys, String className)
::=
  let heads = tys |> ty as T_FUNCTION(source=path::_) => '<%getQtInterfaceHeader(pathLastIdent(path), "", ty.funcArg, ty.funcResultType, className, true)%>;<%\n%>'
  <<
  #include <QtCore>
  #include "OpenModelicaScriptingAPI.h"

  class <%className%> : public QObject
  {
    Q_OBJECT
  public:
    threadData_t *threadData;
    void *st;
    <%className%>(threadData_t *td, void *symbolTable);
    <%heads%>
  signals:
    void logCommand(QString command, QTime *commandTime);
    void logResponse(QString response, QTime *responseTime);
    void throwException(QString exception);
  };
  >>
end getQtInterfaceHeaders;

template getQtType(DAE.Type ty)
::=
  match ty
    case T_STRING(__) then "QString"
    case T_INTEGER(__) then "modelica_integer"
    case T_BOOL(__) then "modelica_boolean"
    case T_REAL(__) then "modelica_real"
    case aty as T_ARRAY(__) then 'QList<<%getQtType(aty.ty)%> >'
    case T_CODE(ty=C_TYPENAME(__)) then "QString"
    else error(sourceInfo(), 'getQtType failed for <%unparseType(ty)%>')
end getQtType;

template getQtTupleTypeOutputNameHelper(Option<list<String>> names, Integer index)
::=
  match names
    case SOME(lst) then listGet(lst, index)
    else 'res<%index%>'
end getQtTupleTypeOutputNameHelper;

template getQtTupleTypeOutputName(DAE.Type ty, Integer index)
::=
  match ty
    case T_TUPLE(__) then getQtTupleTypeOutputNameHelper(names, index)
    else 'res<%index%>'
end getQtTupleTypeOutputName;

template structToString(DAE.Type res, DAE.Type ty, Integer index, Text name)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__)) then
      '<%name%>.append(<%getQtTupleTypeOutputName(res, index)%>);'
    case T_STRING(__) then
      '<%name%>.append("\"" + <%getQtTupleTypeOutputName(res, index)%> + "\"");'
    case T_INTEGER(__)
    case T_REAL(__) then
      '<%name%>.append(QString::number(<%getQtTupleTypeOutputName(res, index)%>));'
    case T_BOOL(__) then
      '<%name%>.append(<%getQtTupleTypeOutputName(res, index)%> ? "true" : "false");'
    case aty as T_ARRAY(__) then
    let varName = '<%getQtTupleTypeOutputName(res, index)%>'
    let elt = '<%varName%>_elt'
    let counter = '<%varName%>_i'
    <<
    <%name%>.append("{");
    int <%counter%> = 0;
    foreach(<%getQtType(aty.ty)%> <%elt%>, <%varName%>) {
      if (<%counter%>) {
        <%name%>.append(",");
      }
      <%getQtResponseLogText(elt, aty.ty, name)%>
      <%counter%>++;
    }
    <%name%>.append("}");
    >>
    else error(sourceInfo(), 'structToString failed for <%unparseType(ty)%>')
end structToString;

template getQtInterfaceHeader(String name, String prefix, list<DAE.FuncArg> args, DAE.Type res, String className, Boolean addStructs)
::=
  let inTypes = args |> arg as FUNCARG(__) => '<%getQtType(arg.ty)%> <%arg.name%>' ; separator=", "
  let outType = match res
    case T_TUPLE(__) then
      if addStructs then
      <<
      typedef struct {
        <%types |> ty hasindex i fromindex 1 => '<%getQtType(ty)%> <%getQtTupleTypeOutputName(res, i)%>;' ; separator="\n" %>
        QString toString() {
          QString resultBuffer = "(";
          <%types |> ty hasindex i fromindex 1 => '<%structToString(res, ty, i, 'resultBuffer')%>' ; separator="\n" + 'resultBuffer.append(",");' + "\n" %>
          resultBuffer.append(")");
          return resultBuffer;
        }
      } <%name%>_res;
      <%name%>_res
      >>
      else
      '<%prefix%><%name%>_res'
    case T_NORETCALL(__) then "void"
    else '<%getQtType(res)%>'
  <<
  <%outType%> <%prefix%><%name%>(<%inTypes%>)
  >>
end getQtInterfaceHeader;

template getQtInArg(Text name, DAE.Type ty, Text &varDecl)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__))
    case T_STRING(__) then
      let &varDecl += 'QByteArray <%name%>_utf8 = <%name%>.toUtf8();<%\n%>'
      'mmc_mk_scon(<%name%>_utf8.data())'
    case T_INTEGER(__)
    case T_BOOL(__)
    case T_REAL(__) then name
    case aty as T_ARRAY(__) then
      let &varDecl2 = buffer ""
      let elt = '<%name%>_elt'
      let body = getQtInArgBoxed(getQtInArg(elt, aty.ty, varDecl2), aty.ty)
      let i = '<%name%>_i'
      let &varDecl +=
      <<
      void *<%name%>_lst = mmc_mk_nil();
      for (int <%i%> = <%name%>.size()-1; <%i%>>=0; <%i%>--) {
        <%getQtType(aty.ty)%> <%elt%> = <%name%>[<%i%>];
        <%varDecl2%>
        <%name%>_lst = mmc_mk_cons(<%body%>, <%name%>_lst);
      }<%\n%>
      >>
      '<%name%>_lst'
    else error(sourceInfo(), 'getQtInArg failed for <%unparseType(ty)%>')
end getQtInArg;

template getQtInArgBoxed(Text name, DAE.Type ty)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__))
    case T_STRING(__)
    case T_ARRAY(__) then name
    case T_INTEGER(__)
    case T_BOOL(__) then 'mmc_mk_icon(<%name%>)'
    case T_REAL(__) then 'mmc_mk_rcon(<%name%>)'
    else error(sourceInfo(), 'getQtInArgBoxed failed for <%unparseType(ty)%>')
end getQtInArgBoxed;

template getQtCommandLogText(Text name, DAE.Type ty)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__))
    case T_STRING(__) then '<%name%>'
    case T_INTEGER(__)
    case T_REAL(__) then 'QString::number(<%name%>)'
    case T_BOOL(__) then 'QString(<%name%> ? "true" : "false")'
    case aty as T_ARRAY(__) then 'QString("### Handle array arguments ###")'
    else error(sourceInfo(), 'getQtCommandLogText failed for <%unparseType(ty)%>')
end getQtCommandLogText;

template getQtOutArg(Text name, Text shortName, DAE.Type ty, Text &varDecl, Text &postCall)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__))
    case T_STRING(__) then
      let &varDecl += 'void *<%shortName%>_mm = NULL;<%\n%>'
      let &postCall += '<%name%> = QString::fromUtf8(MMC_STRINGDATA(<%shortName%>_mm));<%\n%>'
      '&<%shortName%>_mm'
    case T_INTEGER(__)
    case T_BOOL(__)
    case T_REAL(__) then '&<%name%>'
    case aty as T_ARRAY(__) then
      let &varDecl += 'void *<%shortName%>_mm = NULL;<%\n%>'
      let &postCall += getQtOutArgArray(name, shortName, '<%shortName%>_mm', aty)
      '&<%shortName%>_mm'
    else error(sourceInfo(), 'getQtOutArg failed for <%unparseType(ty)%>')
end getQtOutArg;

template getQtOutArgArray(Text name, Text shortName, Text mm, DAE.Type ty)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__))
    case T_STRING(__) then '<%name%> = MMC_STRINGDATA(<%mm%>);<%\n%>'
    case T_INTEGER(__) then '<%name%> = mmc_unbox_integer(<%mm%>);<%\n%>'
    case T_BOOL(__) then '<%name%> = mmc_unbox_boolean(<%mm%>);<%\n%>'
    case T_REAL(__) then '<%name%> = mmc_unbox_real(<%mm%>);<%\n%>'
    case aty as T_ARRAY(__) then
    let elt = '<%shortName%>_elt'
    <<
    <%name%>.clear();
    while (!listEmpty(<%mm%>)) {
      <%getQtType(aty.ty)%> <%elt%>;
      <%getQtOutArgArray(elt, elt, 'MMC_CAR(<%mm%>)', aty.ty)%>
      <%name%>.push_back(<%elt%>);
      <%mm%> = MMC_CDR(<%mm%>);
    }<%\n%>
    >>
    else error(sourceInfo(), 'getOutValueArray failed for <%unparseType(ty)%>')
end getQtOutArgArray;

template getQtResponseLogText(Text name, DAE.Type ty, Text responseLog)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__)) then '<%responseLog%>.append(<%name%>);' + "\n"
    case T_STRING(__) then '<%responseLog%>.append("\"" + <%name%> + "\"");' + "\n"
    case T_INTEGER(__)
    case T_REAL(__) then '<%responseLog%>.append(QString::number(<%name%>));' + "\n"
    case T_BOOL(__) then '<%responseLog%>.append(<%name%> ? "true" : "false");' + "\n"
    case T_TUPLE(__) then '<%responseLog%>.append(<%name%>.toString());' + "\n"
    case aty as T_ARRAY(__) then
    let elt = '<%name%>_elt'
    let counter = '<%name%>_i'
    <<
    <%responseLog%>.append("{");
    int <%counter%> = 0;
    foreach(<%getQtType(aty.ty)%> <%elt%>, <%name%>) {
      if (<%counter%>) {
        responseLog.append(",");
      }
      <%getQtResponseLogText(elt, aty.ty, responseLog)%>
      <%counter%>++;
    }
    <%responseLog%>.append("}");
    >>
    else error(sourceInfo(), 'getQtResponseLogText failed for <%unparseType(ty)%>')
end getQtResponseLogText;

template getQtInterfaceFunc(String name, list<DAE.FuncArg> args, DAE.Type res, String className)
::=
  let &varDecl = buffer ""
  let &responseLog = buffer ""
  let &postCall = buffer ""
  let inArgs = args |> arg as FUNCARG(__) => ', <%getQtInArg(arg.name, arg.ty, varDecl)%>'
  let commandArgs = args |> arg as FUNCARG(__) => getQtCommandLogText(arg.name, arg.ty) ; separator='+"," +'
  let outArgs = (match res
    case T_NORETCALL(__) then
      ""
    case t as T_TUPLE(__) then
      let &varDecl += '<%name%>_res result;<%\n%>'
      let &responseLog += '<%getQtResponseLogText('result', res, 'responseLog')%>'
      (types |> t hasindex i1 fromindex 1 => ', <%getQtOutArg('result.<%getQtTupleTypeOutputName(res, i1)%>', 'out<%i1%>', t, varDecl, postCall)%>')
    else
      let &varDecl += '<%getQtType(res)%> result;<%\n%>'
      let &responseLog += '<%getQtResponseLogText('result', res, 'responseLog')%>'
      ', <%getQtOutArg('result', 'result', res, varDecl, postCall)%>'
    )
  <<
  <%getQtInterfaceHeader(name, '<%className%>', args, res, className, false)%>
  {
    <%varDecl%>

    try {
      MMC_TRY_TOP_INTERNAL()
    
      QTime commandTime;
      commandTime.start();
      emit logCommand("<%replaceDotAndUnderscore(name)%>("+<%if intGt(listLength(args), 0) then commandArgs else 'QString("")'%>+")", &commandTime);
      st = omc_OpenModelicaScriptingAPI_<%replaceDotAndUnderscore(name)%>(threadData, st<%inArgs%><%outArgs%>);
      <%postCall%>
      QString responseLog;
      <%responseLog%>
      emit logResponse(responseLog, &commandTime);

      MMC_CATCH_TOP()
    } catch(std::exception &exception) {
      emit throwException(QString("<%replaceDotAndUnderscore(name)%> failed. %1").arg(exception.what()));
    }

    <%if outArgs then "return result;"%>
  }
  >>
end getQtInterfaceFunc;

annotation(__OpenModelica_Interface="backend");
end GenerateAPIFunctionsTpl;

// vim: filetype=susan sw=2 sts=2
