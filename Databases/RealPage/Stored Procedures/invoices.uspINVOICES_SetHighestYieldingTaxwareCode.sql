SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_SetHighestYieldingTaxwareCode]
-- Description     : This procedure accepts necessary parameters and set highest yeilding TaxwareCode in InvoiceItem
--                   Mainly used for Custom Bundles with multiple prodicts
-- Input Parameters: @IPBI_BillingCycleClosedByUserIDSeq
-- Code Example    : 
/*
                    EXEC INVOICES.dbo.uspINVOICES_SetHighestYieldingTaxwareCode 
                                      @IPVC_InvoiceIDSeq = 'Ixxxxxxxxx',
                                      @IPBI_InvoiceGroupIDSeq = '999999'
                                      @IPVC_TaxwareCode  = 'XYZABC',
                                      @IPXML_InvoiceItemIDSeqXML ='<invoiceitems>
                                                                      <invoiceitemid>123</invoiceitemid>
                                                                      <invoiceitemid>456</invoiceitemid>
                                                                   </invoiceitems>'

*/
--Author           : SRS
--history          : Created 02/22/2010 Defect 7547

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_SetHighestYieldingTaxwareCode] (@IPVC_InvoiceIDSeq         varchar(50),
                                                                    @IPBI_InvoiceGroupIDSeq    bigint,
                                                                    @IPVC_TaxwareCode          varchar(50),
                                                                    @IPXML_InvoiceItemIDSeqXML XML
                                                                   )
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  ---------------------------
  declare @LT_HighestYieldingTaxInvoiceItems table(InvoiceItemIDSeq bigint)
  ----------------------------------------------------------------------------------- 
  --OPENXML to read XML and Insert Data into @LT_HighestYieldingTaxInvoiceItems
  -----------------------------------------------------------------------------------   
  begin TRY  
  insert into @LT_HighestYieldingTaxInvoiceItems(InvoiceItemIDSeq)
  select NULLIF(ltrim(rtrim(convert(varchar(100),EXD.NewDataSet.query('data(.)')))),'') as invoiceitemid
  from  @IPXML_InvoiceItemIDSeqXML.nodes('/invoiceitems/invoiceitemid') as EXD(NewDataSet)
  end TRY
  begin CATCH    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc: uspINVOICES_SetHighestYieldingTaxwareCode : //invoiceitems/invoiceitemid XML ReadSection failed'    
    return
  end CATCH;  
  ------------------------------------------------------------------
  ---Update for Highest Taxware Code
  ------------------------------------------------------------------
  begin try
    UPDATE II     
    Set    II.TaxwareCode  = @IPVC_TaxwareCode
    from   [INVOICES].dbo.[InvoiceItem]       II    with (nolock)
    inner join
           @LT_HighestYieldingTaxInvoiceItems IIXML 
    on     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and    II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq
    and    II.IDSeq             = IIXML.InvoiceItemIDSeq
  end try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_SetHighestYieldingTaxwareCode. Update for highest yeilding TaxwareCode Failed.'
    return
  end   Catch
END --: Main Procedure END
GO
