SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [customers].[uspCUSTOMERS_ErrorLogInsert](
                                                          @IPVC_UserName varchar(50),
                                                          @IPVC_ErrorMessage varchar(2000),
                                                          @IPVC_SourceQueryString    varchar(200),
                                                          @IPVC_SourceMethod    varchar(1000),
                                                          @IPVC_DBServerName    varchar(200),
                                                          @IPVC_DBQuery    varchar(3000),
                                                          @IPVC_StackTrace    varchar(3000),
                                                          @IPVC_sExceptionType    varchar(100),
                                                          @IPBI_sSqlExceptionNumber bigint
                                                     ) 

AS
BEGIN

 INSERT INTO [Customers]..[ErrorLog] (ApplicationUserName, ErrorMessage, SourceQueryString,
				SourceMethod, DBServerName, DBQuery, StackTrace, ExceptionType, SqlErrorNumber)
  values (@IPVC_UserName, @IPVC_ErrorMessage, @IPVC_SourceQueryString, @IPVC_SourceMethod,
        @IPVC_DBServerName, @IPVC_DBQuery, @IPVC_StackTrace, @IPVC_sExceptionType, @IPBI_sSqlExceptionNumber)

 SELECT @@identity

END

GO
