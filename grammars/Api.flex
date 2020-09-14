package io.chengguo.api.debugger.lang.lexer;

import com.intellij.lexer.FlexLexer;
import com.intellij.psi.tree.IElementType;
import com.intellij.psi.TokenType;

import static io.chengguo.api.debugger.lang.psi.ApiTypes.*;

%%

%public
%class ApiLexer
%implements FlexLexer
%unicode
%function advance
%type IElementType
%eof{  return;
%eof}

%{
        private final ApiLexerMultipartBodyManipulator multipartBodyManipulator;

        /**
         * Creates a new scanner
         */
        public ApiLexer() {
            this(null);
        }

        {
            multipartBodyManipulator = new ApiLexerMultipartBodyManipulator();
        }

        public final CharSequence yytext(int offset) {
            return zzBuffer.subSequence(zzStartRead, zzMarkedPos + offset);
        }

        /**
         * 切换状态，会记录切换前的状态
         *
         * @param newState
         */
        public void pushState(int newState) {
            yypush();
            yybegin(newState);
        }

        /**
         * 切换至上一个状态
         */
        public void popState() {
            yypop();
        }

        /**
         * 当路径匹配完成，切换至下一个状态
         */
        private void onPathFinish() {
            if (yylength() == 1) {
                yypushback(yylength());
                pushState(IN_HEADER);
            } else {
                yypushback(yylength());
                pushState(BEFORE_BODY);
            }
        }

        /**
         * 处理ContentType
         */
        private void handleContentTypeHeader() {
            if(!multipartBodyManipulator.isStarted() && multipartBodyManipulator.isMultipartType(yytext())) {
                multipartBodyManipulator.start();
            }else {
                multipartBodyManipulator.trySetBoundary(yytext());
            }
        }

        private int inMessageBodyState() {
            if(multipartBodyManipulator.isStartedAndDefined()) {
                return IN_MESSAGE_MULTIPART;
            }
            return IN_MESSAGE_BODY;
        }

        private void reset() {
            multipartBodyManipulator.reset();
            pushState(YYINITIAL);
        }
%}

NL=[\r\n]
WS=[ \t\f]
LETTER = [a-zA-Z]
DIGIT =  [0-9]
END_OF_LINE_COMMENT=("//")[^\r\n]*
MULTILINE_COMMENT = "/*" ( ([^"*"]|[\r\n])* ("*"+ [^"*""/"] )? )* ("*" | "*"+"/")?
OPTIONS = "OPTIONS"
GET = "GET"
HEAD = "HEAD"
POST = "POST"
PUT = "PUT"
DELETE = "DELETE"
TRACE = "TRACE"
CONNECT = "CONNECT"
PATCH = "PATCH"
METHOD = {OPTIONS} | {GET} | {HEAD} | {POST} | {PUT} | {DELETE} | {TRACE} | {CONNECT} | {PATCH}
LBRACES = "{{"
RBRACES = "}}"
ID = ({LETTER} | "_") ({LETTER} | {DIGIT} | "_")*
SEPARATOR = "###"
HEADER_FIELD_NAME = [^ \r\n\t\f:] ([^\r\n\t\f:{]* [^ \r\n\t\f:{])?
HEADER_FIELD_VALUE = [^ \r\n\t\f;] ([^\r\n;{]* [^ \r\n\t\f;{])?
BODY_SEPARATOR = {WS}* {NL} {NL} ({WS} | {NL})*
MESSAGE_TEXT = [^ \t\f\r\n\#\<] ([^\r\n]* ([\r\n]+ [^\r\n\#\<])? )*
MESSAGE_TEXT_BOUNDARY = [^ \t\f\r\n\-\<\#] ([^\r\n]* ([\r\n]+ [^\r\n\-\<\#])? )*
MESSAGE_BOUNDARY = "--" [^ \r\n\t\f]*
MESSAGE_BOUNDARY_END = "--" [^ \r\n\t\f]* "--"
INPUT_SIGNAL = "< "
INPUT_FILE_PATH = [^\t\f\r\n]+


%state IN_HTTP_REQUEST
%state IN_HTTP_TARGET
%state IN_HTTP_REQUEST_HOST
%state IN_HTTP_REQUEST_PORT
%state IN_HTTP_PATH_SEGMENT
%state IN_HTTP_QUERY
%state IN_HTTP_QUERY_VALUE
%state IN_HEADER
%state IN_HEADER_VALUE
%state BEFORE_BODY
%state IN_MESSAGE_BODY
%state IN_MESSAGE_MULTIPART
%state IN_INPUT_FILE_PATH
%state IN_VARIABLE
%state IN_DESCRIPTION
%state IN_DESCRIPTION_KEY
%state IN_DESCRIPTION_VALUE

%%
<YYINITIAL> {
    ({WS} | {NL})+                              { return TokenType.WHITE_SPACE; }
    {END_OF_LINE_COMMENT}                       { return Api_LINE_COMMENT; }
    {MULTILINE_COMMENT}                         { return Api_MULTILINE_COMMENT; }
    {SEPARATOR} [^\r\n]*                        { return Api_SEPARATOR; }
    {METHOD}                                    { yypushback(yylength()); pushState(IN_HTTP_REQUEST); }
    "-"                                         { yypushback(yylength()); pushState(IN_DESCRIPTION); }
}

<IN_DESCRIPTION> {
    {WS}+                                       { return TokenType.WHITE_SPACE; }
    "-"                                         { pushState(IN_DESCRIPTION_KEY); return Api_HYPHEN; }
    ":"                                         { pushState(IN_DESCRIPTION_VALUE); return Api_COLON; }
    {NL}                                        { popState(); return TokenType.WHITE_SPACE; }
}

<IN_DESCRIPTION_KEY> {
    {WS}+                                       { return TokenType.WHITE_SPACE; }
    [^ \r\n:] ([^\r\n:]* [^ \r\n:])?            { popState(); return Api_DESCRIPTION_KEY; } // 排除两边的空格
}

<IN_DESCRIPTION_VALUE> {
    {WS}+                                       { return TokenType.WHITE_SPACE; }
    [^ \r\n] [^\r\n]*                           { return Api_LINE_TEXT; }
    {NL}                                        { yypushback(yylength()); popState(); }
}

<IN_VARIABLE> {
    {ID}                                        { return Api_IDENTIFIER; }
    {RBRACES}                                   { popState(); return Api_RBRACES;}
}

<IN_HTTP_REQUEST> {
    {OPTIONS}                                   { return Api_OPTIONS; }
    {GET}                                       { return Api_GET; }
    {HEAD}                                      { return Api_HEAD; }
    {POST}                                      { return Api_POST; }
    {PUT}                                       { return Api_PUT; }
    {DELETE}                                    { return Api_DELETE; }
    {TRACE}                                     { return Api_TRACE; }
    {CONNECT}                                   { return Api_CONNECT; }
    {PATCH}                                     { return Api_PATCH; }
    {WS}+                                       { pushState(IN_HTTP_TARGET); return TokenType.WHITE_SPACE; }
}

<IN_HTTP_TARGET> {
    "https"                                     { return Api_HTTPS; }
    "http"                                      { return Api_HTTP; }
    "://"                                       { return Api_SCHEME_SEPARATOR; }
    [^\r\n:/?#]+                                { yypushback(yylength()); pushState(IN_HTTP_REQUEST_HOST); }
    ":"                                         { pushState(IN_HTTP_REQUEST_PORT); return Api_COLON; }
    "/"                                         { pushState(IN_HTTP_PATH_SEGMENT); return Api_SLASH; }
    "?"                                         { pushState(IN_HTTP_QUERY); return Api_QUESTION_MARK; }
    {NL}+                                       { onPathFinish(); }
}

<IN_HTTP_REQUEST_HOST> {
    {LBRACES}                                   { pushState(IN_VARIABLE); return Api_LBRACES; }
    [^\r\n:/?#"{{"]+                            { return Api_HOST_VALUE; }
    [:/?#] | {NL}+                              { yypushback(yylength()); popState(); }
}

<IN_HTTP_REQUEST_PORT> {
    {LBRACES}                                   { pushState(IN_VARIABLE); return Api_LBRACES; }
    {DIGIT}+                                    { return Api_PORT_SEGMENT; }
    [\r\n/?#]                                   { yypushback(yylength()); popState(); } //Default 80
}

<IN_HTTP_PATH_SEGMENT> {
    [^\r\n/?#]+                                 { return Api_SEGMENT; }
    {NL}+                                       { yypushback(yylength()); popState(); }
    [/?#]                                       { yypushback(yylength()); popState(); } //Segment can be empty
}

<IN_HTTP_QUERY> {
    {LBRACES}                                   { pushState(IN_VARIABLE); return Api_LBRACES; }
    [^\r\n="{{"]+                               { return Api_QUERY_NAME; }// Key
    "="                                         { pushState(IN_HTTP_QUERY_VALUE); return Api_EQUALS; }
    {NL}+                                       { yypushback(yylength()); popState(); }
}

<IN_HTTP_QUERY_VALUE> {
    {LBRACES}                                   { pushState(IN_VARIABLE); return Api_LBRACES; }
    [^\r\n&"{{"]+                               { return Api_QUERY_VALUE; }
    "&"                                         { popState(); return Api_AMPERSAND;}
    {NL}+                                       { yypushback(yylength()); popState(); }
}

<IN_HEADER> {
    {WS}+                                       { return TokenType.WHITE_SPACE; }
    {LBRACES}                                   { pushState(IN_VARIABLE); return Api_LBRACES; }
    {NL}                                        { return TokenType.WHITE_SPACE; }
    {HEADER_FIELD_NAME}                         { return Api_HEADER_FIELD_NAME; } // 排除起始和末尾位置的空格
    ":"                                         { pushState(IN_HEADER_VALUE); return Api_COLON; }
    {BODY_SEPARATOR}                            { yypushback(yylength()); pushState(BEFORE_BODY); }
}

<IN_HEADER_VALUE> {
    {WS}+                                       { return TokenType.WHITE_SPACE; }
    {NL}                                        { popState(); return TokenType.WHITE_SPACE; }
    {BODY_SEPARATOR}                            { yypushback(yylength()); popState(); }
    {LBRACES}                                   { pushState(IN_VARIABLE); return Api_LBRACES; }
    ";"                                         { return Api_SEMICOLON; }
    {HEADER_FIELD_VALUE}                        { handleContentTypeHeader(); return Api_HEADER_FIELD_VALUE; } // 排除起始位置的空格
}

<BEFORE_BODY> {
    {BODY_SEPARATOR}                            { pushState(inMessageBodyState()); return TokenType.WHITE_SPACE; }// 判断进入普通body还是multipart body
}

<IN_MESSAGE_BODY> {
    ({WS} | {NL})+                              { return TokenType.WHITE_SPACE; }
    {SEPARATOR}                                 { yypushback(yylength()); reset(); }
    {MESSAGE_TEXT}                              { return Api_MESSAGE_TEXT; }
    {INPUT_SIGNAL}                              { pushState(IN_INPUT_FILE_PATH); return Api_INPUT_SIGNAL; }
}

<IN_INPUT_FILE_PATH> {
    {INPUT_FILE_PATH}                           { popState(); return Api_RELATIVE_FILE_PATH; }
}

<IN_MESSAGE_MULTIPART> {
    ({WS} | {NL})+                              { return TokenType.WHITE_SPACE; }
    {SEPARATOR}                                 { yypushback(yylength()); reset(); }
    {MESSAGE_TEXT_BOUNDARY}                     { return Api_MESSAGE_TEXT; }
    {INPUT_SIGNAL}                              { pushState(IN_INPUT_FILE_PATH); return Api_INPUT_SIGNAL; }
    {MESSAGE_BOUNDARY_END}                      { reset(); return Api_MESSAGE_BOUNDARY_END; }
    {MESSAGE_BOUNDARY}                          { pushState(IN_HEADER); return Api_MESSAGE_BOUNDARY; }
}

[^]                                             { return TokenType.BAD_CHARACTER; }