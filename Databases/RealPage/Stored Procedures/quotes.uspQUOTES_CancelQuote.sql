SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_CancelQuote]
-- Description     : This procedure cancels the specified Quote. 
-- Input Parameters: @IPVC_QuoteIDSeq   VARCHAR(11)
-- 
-- OUTPUT          : 
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_CancelQuote]    @IPVC_QuoteIDSeq    = 'Q0000000001'
--                                                              
-- Revision History:
-- Author          : Kiran Kusumba
-- 09/04/2007      : Stored Procedure Created.
-- 08/06/2011      : TFS 295 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_CancelQuote]  (@IPVC_QuoteIDSeq      VARCHAR(50),     ---> MANDATORY : This is the QuoteID
                                                 @IPBI_UserIDSeq       bigint      =-1  ---> MANDATORY : User ID of the User Logged on and doing the operation.  
                                                )                                                
AS
BEGIN
  set nocount on;  
  ---------------------------------
  declare @LDT_SystemDate  datetime
  select  @LDT_SystemDate = Getdate()

  select @IPBI_UserIDSeq = (case when @IPBI_UserIDSeq is null or @IPBI_UserIDSeq in (0,-1) 
                                  then NULL          
                                else  @IPBI_UserIDSeq
                           end);
  --------------------------------------------------------  
  -- Update the Quote Status to Cancelled
  --------------------------------------------------------
  Update QUOTES.dbo.QUOTE
  set    QuoteStatusCode = 'CNL',
         CancelledDate   = @LDT_SystemDate,
         ApprovalDate    = NULL, 
         AcceptanceDate  = NULL,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate,
         ModifiedByIdSeq = coalesce(@IPBI_UserIDSeq,ModifiedByIdSeq)
  where  QuoteIDSeq      = @IPVC_QuoteIDSeq;
END
GO
