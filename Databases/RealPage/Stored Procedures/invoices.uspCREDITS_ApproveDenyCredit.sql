SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name   : INVOICES
-- Procedure Name   : uspCREDITS_ApproveDenyCredit
-- Description      : This procedure approves or denies a requested credit.
-- Input Parameters : 1. @IPVC_CreditMemoIDSeq   as bigint, 
--                    2. @IPVC_CreditStatusCode  as varchar(4),  
--                    3. @IPVC_UserName          as varchar(70) 
-- 
-- OUTPUT           : The no. of rows affected by the update query.
--
-- Code Example     : Exec Invoices.DBO.uspCREDITS_ApproveDenyCredit  
--                          @IPVC_CreditMemoIDSeq   = 1, 
--                          @IPVC_CreditStatusCode  = 'APPR',  
--                          @IPVC_UserName          = '[Anonymous User]'
-- 
-- Revision History :
-- Author           : KRK
-- 01/19/2007       : Stored Procedure Created.
-- 02/08/2006       : Changed by STA. Approved Date is also updated.
-- 05/02/2008       : Naval Kishore Modified for deny credits
-- 08/05/2010       : Shashi Bhushan - Defect#7952 - Credit Reversals in OMS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspCREDITS_ApproveDenyCredit](
                                                      @IPVC_InvoiceIDSeq      varchar(50),     --> Mandatory : This is the InvoiceIDSeq for which FullCredit or TaxCredit or PartialCredit are associated with for approval or deny
                                                      @IPVC_CreditMemoIDSeq   varchar(50),     --> Mandatory : This is the CreditMemoIDSeq for which FullCredit or TaxCredit or PartialCredit are associated with for approval or deny
                                                      @IPVC_CreditStatusCode  varchar(4),      --> Mandatory : This is the CreditStatusCode (PAPR,APPR,DENY,RVSD etc)
                                                      @IPVC_UserName          varchar(70),     --> This is the Full User name of the person doing the operation. This will be decomissioned later.
                                                      @IPBI_UserIDSeq         bigint = -1      --> Mandatory : This is userID of the Person initiating this credit operation from UI.
                                                                                               --   UI already knows this value to pass in. 
                                                     )
AS
BEGIN
  set  nocount on;
  --------------------------------------------------------  
  declare @LDT_SystemDate      datetime;

  select @LDT_SystemDate       = GETDATE(),
         @IPVC_InvoiceIDSeq    = coalesce(nullif(ltrim(rtrim(@IPVC_InvoiceIDSeq)),''),'ABCDEFHIJK'),
         @IPVC_CreditMemoIDSeq = coalesce(nullif(ltrim(rtrim(@IPVC_CreditMemoIDSeq)),''),'ABCDEFHIJK');  
  --------------------------------------------------------
  if (@IPVC_CreditStatusCode = 'APPR')
  begin    
    update Invoices.dbo.CreditMemo 
    set    CreditStatusCode  = @IPVC_CreditStatusCode,
           ApprovedBy        = @IPVC_UserName,
           ApprovedDate      = @LDT_SystemDate,
           CancelledBy       = NULL,
           CancelledDate     = NULL, 
           ModifiedByIDSeq   = @IPBI_UserIDSeq,
           ModifiedDate      = @LDT_SystemDate,
           SystemLogDate     = @LDT_SystemDate          
    where  CreditMemoIDSeq   = @IPVC_CreditMemoIDSeq;
  end  
  else if (@IPVC_CreditStatusCode = 'RVSD' Or @IPVC_CreditStatusCode = 'PAPR')
  begin
    update Invoices.dbo.CreditMemo 
    set    CreditStatusCode  = (case when @IPVC_CreditStatusCode = 'RVSD' 
                                       then 'PAPR' 
                                     else @IPVC_CreditStatusCode
                                end),
           ApprovedBy        = NULL,
           ApprovedDate      = NULL,
           CancelledBy       = NULL,
           CancelledDate     = NULL,
           RevisedBy         = @IPVC_UserName,
           RevisedDate       = @LDT_SystemDate,
           ModifiedByIDSeq   = @IPBI_UserIDSeq,
           ModifiedDate      = @LDT_SystemDate,
           SystemLogDate     = @LDT_SystemDate
    where  CreditMemoIDSeq   = @IPVC_CreditMemoIDSeq;
  end
  else if  (@IPVC_CreditStatusCode = 'DENY' OR @IPVC_CreditStatusCode = 'CNCL')
  begin
    update  Invoices.dbo.CreditMemo 
    set     CreditStatusCode  = (case when @IPVC_CreditStatusCode = 'CNCL' 
                                       then 'DENY' 
                                     else @IPVC_CreditStatusCode
                                end),
            ApprovedBy        = NULL,
            ApprovedDate      = NULL,
            CancelledBy       = @IPVC_UserName,
            CancelledDate     = @LDT_SystemDate,
            ModifiedByIDSeq   = @IPBI_UserIDSeq,
            ModifiedDate      = @LDT_SystemDate,
            SystemLogDate     = @LDT_SystemDate
    where   CreditMemoIDSeq   = @IPVC_CreditMemoIDSeq;  
  end  
  -------------------------------------------------------- 
  --Sync Header and details for CreditMemos
  Exec Invoices.dbo.[uspCredits_SyncCreditTaxAmount] @IPVC_CreditMemoIDSeq =@IPVC_CreditMemoIDSeq;
  -------------------------------------------------------- 
END
GO
