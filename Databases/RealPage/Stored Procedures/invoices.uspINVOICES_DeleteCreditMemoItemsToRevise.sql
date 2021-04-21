SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_DeleteCreditMemoItemsToRevise
-- PreRequisites   : This Proc will be called only UI when Credit-->Action-->Revise is invoked.

-- Description     : This Proc will be called only UI when Credit-->Action-->Revise is invoked.
-- Input Parameters: @IPVC_InvoiceIDSeq Varchar(50),@IPBI_UserIDSeq bigint
-- Syntax          : 
/*
EXEC INVOICES.dbo.uspINVOICES_DeleteCreditMemoItemsToRevise  @IPVC_InvoiceIDSeq = 'I1105025854',@IPVC_CreditMemoIDSeq='R1109000229',@IPBI_UserIDSeq=123
*/
-- Revision History:
-- Author          : SRS : Task # 918: 
-- 09/28/2011      : 
-----------------------------------------------------------------------------------------------------------------------------
Create Procedure [invoices].[uspINVOICES_DeleteCreditMemoItemsToRevise] (@IPVC_InvoiceIDSeq    varchar(50),     --->  Mandatory : This is the InvoiceIDSeq for which FullCredit or TaxCredit or PartialCredit are intiated by User.
                                                                                                            -->  UI already Knows this Value to pass in.
                                                                    @IPVC_CreditMemoIDSeq varchar(50),     --->  Mandatory: This the CreditMemoIDSeq for which Corresponding CreditMemoitems are to be deleted before Insert Revised items are called from UI.
                                                                    @IPBI_UserIDSeq       bigint = -1       -->  Mandatory : This is userID of the Person initiating this credit operation from UI.
                                                                   )
as
BEGIN ----> Main BEGIN
  set nocount on;
  select @IPVC_InvoiceIDSeq    = coalesce(nullif(ltrim(rtrim(@IPVC_InvoiceIDSeq)),''),'ABCDEFHIJK');
  select @IPVC_CreditMemoIDSeq = coalesce(nullif(ltrim(rtrim(@IPVC_CreditMemoIDSeq)),''),'ABCDEFHIJK');
  --------------------------------------------------------
  if exists (select Top 1 1
             from   Invoices.dbo.CreditMemo CM with (nolock)
             where  CM.InvoiceIDSeq     = @IPVC_InvoiceIDSeq
             and    CM.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq
             and    CM.CreditStatusCode = 'PAPR'
            )
  begin
    Delete D 
    from   INVOICES.dbo.CreditMemoItemNote D with (nolock)
    where  D.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq;

    Delete D 
    from   INVOICES.dbo.CreditMemoItem D with (nolock)
    where  D.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq;    
  end
  --------------------------------------------------------
END ----> Main END
GO
