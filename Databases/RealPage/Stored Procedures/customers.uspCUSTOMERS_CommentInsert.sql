SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CommentInsert
-- Description     : This procedure inserts a Comment Record.

-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CommentInsert  
--                      @IPVC_CommentTypeCode = '',
--					    @IPVC_AccountTypeCode= '',
--					    @@IPVC_Name= '' ,
--						@IPVC_Description= '',
--						@IPVC_CompanyIDSeq= '',
--						@IPVC_PropertyIDSeq= '',
--						@IPVC_AccountIDSeq= '',
--						@IPVC_CreatedByIDSeq= '',
--						@IPVC_CreatedDate= ''
---- 
-- Revision History:
-- Author          : Anand Chakravarthy
-- 24/05/2010      : Stored Procedure Created.
--
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CommentInsert] 
                                                  (@IPVC_CommentTypeCode    varchar(10),
                                                   @IPVC_AccountTypeCode    varchar(10),
                                                   @IPVC_Name               varchar(100),
                                                   @IPVC_Description        varchar(4000),
                                                   @IPVC_CompanyIDSeq	    varchar(50) ,
                                                   @IPVC_PropertyIDSeq      varchar(50) = NULL,
                                                   @IPVC_AccountIDSeq       varchar(50) = NULL,
                                                   @IPVC_CreatedByIDSeq     bigint                                                   
                                                  )
	
	
AS
BEGIN
  set nocount on;
  ------------------------------------------------------------------  
  set @IPVC_PropertyIDSeq    = nullif(LTRIM(RTRIM(@IPVC_PropertyIDSeq)),'')
  set @IPVC_AccountIDSeq     = nullif(LTRIM(RTRIM(@IPVC_AccountIDSeq)),'')
  ------------------------------------------------------------------
  --                Insert Comment Record                   --
  ------------------------------------------------------------------
  insert into CUSTOMERS.DBO.CustomerComment(CommentTypeCode,AccountTypeCode,[Name], 
                                            [Description],CompanyIDSeq,
                                            PropertyIDSeq,AccountIDSeq,
                                            CreatedByIDSeq,CreatedDate
                                           )
  select @IPVC_CommentTypeCode              as CommentTypeCode,
         @IPVC_AccountTypeCode              as AccountTypeCode,
         LTRIM(RTRIM(UPPER(@IPVC_Name)))    as [Name],
         @IPVC_Description                  as [Description],
         @IPVC_CompanyIDSeq                 as CompanyIDSeq,
         @IPVC_PropertyIDSeq                as PropertyIDSeq,
         @IPVC_AccountIDSeq                 as AccountIDSeq,
         @IPVC_CreatedByIDSeq               as CreatedByIDSeq,
         getdate()                          as CreatedDate					     
END
GO
