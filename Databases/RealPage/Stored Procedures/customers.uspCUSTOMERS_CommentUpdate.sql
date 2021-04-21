SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CommentUpdate
-- Description     : This procedure inserts a Comment Record.

-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CommentUpdate  
--                      @IPVC_CommentTypeCode = '',
--			@IPVC_Name= '' ,
--			@IPVC_Description= '',
--		        @IPVC_ModifiedByIDSeq= '',
---- 
-- Revision History:
-- Author          : Anand Chakravarthy
-- 24/05/2010      : Stored Procedure Created.
--
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CommentUpdate] 
                                                  (@IPVC_CommentTypeCode    varchar(10),
                                                   @IPVC_Name	 	    varchar(100),
                                                   @IPVC_Description	    varchar(4000),
                                                   @IPVC_ModifiedByIDSeq    bigint,
                                                   @IPBI_CommentIDSeq       bigint -->Primary Key Unique identifier for CustomerComment Record
                                                  )
	
	
AS
BEGIN
  set nocount on;  
  ------------------------------------------------------------------
  --                Update Comment Record                   --
  ------------------------------------------------------------------
  Update CUSTOMERS.DBO.CustomerComment
  Set  Name             = @IPVC_Name,
       Description      = @IPVC_Description,
       CommentTypeCode	= @IPVC_CommentTypeCode,					
       ModifiedByIDSeq  = @IPVC_ModifiedByIDSeq,
       ModifiedDate     = getdate(),
       SystemLogDate    = getdate()
  Where IDSeq  = @IPBI_CommentIDSeq		  	     
END
GO
