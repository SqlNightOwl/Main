SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : uspCREDITS_ReversalCreditInsert   
-- Description     : This procedure inserts Credit Reversal Details into CreditMemo and CreditMemoItem tables  
-- Input Parameters: @IPVC_CreditMemoIDSeq         varchar(22),
--					 @IPVC_ParentCreditMemoIDSeq   varchar(22), 
--					 @IPVC_ModifiedBy              varchar(70) 
--                     
-- Code Example    : Exec Invoices.dbo.uspCREDITS_ReversalCreditInsert 
--					 @IPVC_CreditMemoIDSeq        = 'R0805000077', 
--					 @IPVC_ParentCreditMemoIDSeq  = 'R0805000070',
--					 @IPVC_ModifiedBy             = 'Shashi Bhushan'                    
--   
-- Revision History:  
-- Author          : Shashi Bhushan  
-- 05/06/2008      : Stored Procedure Created.
-- 08/05/2010      : Shashi Bhushan - Defect#7952 - Credit Reversals in OMS
-- 06/22/2010	   : Surya Kondapalli - Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspCREDITS_ReversalCreditInsert] 
                                                         (                                                               
                                                           @IPVC_CreditMemoIDSeq         Varchar(50),  ----> This is the new reversal Credit Memo corresponding to Original Parent Credit Memo
                                                           @IPVC_ParentCreditMemoIDSeq   Varchar(50),  ----> This is the Original Parent Credit Memo
                                                           @IPVC_ModifiedBy              Varchar(70),  ----> This is the user who is initiating the Credit Reversal
                                                           @IPBI_UserIDSeq               Bigint = -1   ----> This is the userid of the person initiating this operation. UI to pass this value.
                                                         )  
AS  
BEGIN   
   set nocount on;
   ----------------------------------------------------------------------------------
   -- Declaring/Assigning values to Local Variables
   ----------------------------------------------------------------------------------
   Declare @LDT_SystemDate   datetime,
           @LVC_InvoiceIDSeq varchar(50)

   select @LDT_SystemDate  = getdate();
   ----------------------------------------------------------------------------------
   Select Top 1 @LVC_InvoiceIDSeq = CM.InvoiceIDSeq 
   From   Invoices.dbo.CreditMemo CM with (nolock) 
   Where  CM.CreditMemoIDSeq   = @IPVC_ParentCreditMemoIDSeq;
   ----------------------------------------------------------------------------------
   --Validation : A Original Parent Credit Memo Can have only one Child Credit Memo which a reversal Credit Memo. Reversal Credits are by default Approved.
   --             If UI happens to call this same proc again for the same @IPVC_ParentCreditMemoIDSeq, this check will prevent duplicates.
   if exists (select top 1 1
              from   Invoices.dbo.CreditMemo CM with (nolock) 
              where  CM.InvoiceIDSeq           = @LVC_InvoiceIDSeq
              and    CM.ApplyToCreditMemoIDSeq = @IPVC_ParentCreditMemoIDSeq
              and    CM.CreditStatusCode       = 'APPR'
             )
   begin
     ----> This means ParentCreditMemoIDSeq already has as Child Credit Memo already.
     ----  Quietly quit
     return;
   end
   ----------------------------------------------------------------------------------
   if (
       not exists (select top 1 1
                   from   Invoices.dbo.CreditMemo CM with (nolock)
                   where  CM.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq
                  )
         and
       not exists (select top 1 1
                   from   Invoices.dbo.CreditMemo CM with (nolock) 
                   where  CM.InvoiceIDSeq           = @LVC_InvoiceIDSeq
                   and    CM.ApplyToCreditMemoIDSeq = @IPVC_ParentCreditMemoIDSeq
                   and    CM.CreditStatusCode       = 'APPR'
                  ) 
     )
   begin
     ----------------------------------------------------------------------------------
     --Step 1: Inserting Data into the Credit Memo Table 
     ----------------------------------------------------------------------------------
     Insert Into Invoices.dbo.CreditMemo
                (
                  CreditMemoIDSeq,InvoiceIDSeq,TaxAmount,TotalNetCreditAmount,CreditStatusCode,CreditReasonCode,
                  RequestedBy,RequestedDate,Comments,CreditTypeCode,ILFCreditAmount,AccessCreditAmount,
                  DoNotPrintCreditReasonFlag,DoNotPrintCreditCommentsFlag,CreditMemoDate,CreditMemoReversalFlag,
                  ApplyToCreditMemoIDSeq,EpicorPostingCode,CreatedBy,CreatedByIDSeq,CreatedDate,
                  ApprovedBy,ApprovedDate,ApplyDate,PrintFlag,MarkAsPrintedFlag,SystemLogDate
                )
     Select       @IPVC_CreditMemoIDSeq as CreditMemoIDSeq,InvoiceIDSeq,-TaxAmount,-TotalNetCreditAmount,'APPR' as CreditStatusCode,CreditReasonCode,
                  RequestedBy,@LDT_SystemDate as RequestedDate,Comments,CreditTypeCode,-ILFCreditAmount,-AccessCreditAmount,
                  DoNotPrintCreditReasonFlag,DoNotPrintCreditCommentsFlag,@LDT_SystemDate as CreditMemoDate,1 as CreditMemoReversalFlag,
                  @IPVC_ParentCreditMemoIDSeq as ApplyToCreditMemoIDSeq,EpicorPostingCode,
                  @IPVC_ModifiedBy as CreatedBy,@IPBI_UserIDSeq  as CreatedByIDSeq,@LDT_SystemDate  as CreatedDate,                
                  @IPVC_ModifiedBy as ApprovedBy,@LDT_SystemDate as ApprovedDate,@LDT_SystemDate as ApplyDate,
                  1 as PrintFlag,1 as MarkAsPrintedFlag,@LDT_SystemDate as SystemLogDate
     From  Invoices.dbo.CreditMemo CM with (nolock)
     Where CM.CreditMemoIDSeq        = @IPVC_ParentCreditMemoIDSeq
     and   CM.InvoiceIDSeq           = @LVC_InvoiceIDSeq   
     ----------------------------------------------------------------------------------
     --Step 2 Inserting Data into CreditMemoItem Table
     ----------------------------------------------------------------------------------        
     Insert Into Invoices.dbo.CreditMemoItem
	   		  (
				CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,CustomBundleNameEnabledFlag,
				InvoiceItemIdSeq,UnitCreditAmount,EffectiveQuantity,ExtCreditAmount,DiscountCreditAmount,TaxPercent,
				TaxAmount, NetCreditAmount,RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,
				RevenueRecognitionCode,TaxwareCode,TaxwarePrimaryStateTaxPercent,TaxwarePrimaryStateTaxAmount,
				TaxwareSecondaryStateTaxPercent,TaxwareSecondaryStateTaxAmount,TaxwarePrimaryCityTaxPercent,TaxwarePrimaryCityTaxAmount,
				TaxwareSecondaryCityTaxPercent,TaxwareSecondaryCityTaxAmount,TaxwarePrimaryCountyTaxPercent,
				TaxwarePrimaryCountyTaxAmount,TaxwareSecondaryCountyTaxPercent,TaxwareSecondaryCountyTaxAmount,
				TaxwarePrimaryStateTaxBasisAmount,TaxwareSecondaryStateTaxBasisAmount,TaxwarePrimaryCityTaxBasisAmount,
				TaxwareSecondaryCityTaxBasisAmount,TaxwarePrimaryCountyTaxBasisAmount,TaxwareSecondaryCountyTaxBasisAmount,
				TaxwarePrimaryStateJurisdictionZipCode,TaxwareSecondaryStateJurisdictionZipCode,TaxwarePrimaryCityJurisdiction,
				TaxwareSecondaryCityJurisdiction,TaxwarePrimaryCountyJurisdiction,TaxwareSecondaryCountyJurisdiction,
				TaxwareCallOverrideFlag,ShippingAndHandlingCreditAmount,CreditMemoReversalFlag,ApplyToCreditMemoIDSeq,DefaultTaxwareCode,
                                TaxwareGSTCountryTaxAmount,TaxwareGSTCountryTaxPercent,	
				TaxwarePSTStateTaxAmount,TaxwarePSTStateTaxPercent
                                ,CreatedByIDSeq,CreatedDate,SystemLogDate 
			  )
     Select       @IPVC_CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,CustomBundleNameEnabledFlag,
	  			InvoiceItemIdSeq,-UnitCreditAmount,EffectiveQuantity,-ExtCreditAmount,-DiscountCreditAmount,TaxPercent,
				-TaxAmount,-NetCreditAmount,RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,
				RevenueRecognitionCode,TaxwareCode,TaxwarePrimaryStateTaxPercent,-TaxwarePrimaryStateTaxAmount,
				TaxwareSecondaryStateTaxPercent,-TaxwareSecondaryStateTaxAmount,TaxwarePrimaryCityTaxPercent,-TaxwarePrimaryCityTaxAmount,
				TaxwareSecondaryCityTaxPercent,-TaxwareSecondaryCityTaxAmount,TaxwarePrimaryCountyTaxPercent,
				-TaxwarePrimaryCountyTaxAmount,TaxwareSecondaryCountyTaxPercent,-TaxwareSecondaryCountyTaxAmount,
				-TaxwarePrimaryStateTaxBasisAmount,-TaxwareSecondaryStateTaxBasisAmount,-TaxwarePrimaryCityTaxBasisAmount,
				-TaxwareSecondaryCityTaxBasisAmount,-TaxwarePrimaryCountyTaxBasisAmount,-TaxwareSecondaryCountyTaxBasisAmount,
				TaxwarePrimaryStateJurisdictionZipCode,TaxwareSecondaryStateJurisdictionZipCode,TaxwarePrimaryCityJurisdiction,
				TaxwareSecondaryCityJurisdiction,TaxwarePrimaryCountyJurisdiction,TaxwareSecondaryCountyJurisdiction,
				TaxwareCallOverrideFlag,-ShippingAndHandlingCreditAmount,1,@IPVC_ParentCreditMemoIDSeq,DefaultTaxwareCode,
                                -TaxwareGSTCountryTaxAmount,TaxwareGSTCountryTaxPercent,	
				-TaxwarePSTStateTaxAmount,TaxwarePSTStateTaxPercent,
                                 @IPBI_UserIDSeq  as CreatedByIDSeq,@LDT_SystemDate  as CreatedDate,@LDT_SystemDate as SystemLogDate
     From  Invoices.dbo.CreditMemoItem CMI with (nolock)
     Where CMI.CreditMemoIDSeq = @IPVC_ParentCreditMemoIDSeq
     and   CMI.InvoiceIDSeq    = @LVC_InvoiceIDSeq;
     ----------------------------------------------------------------------------------
     --Step 3: Updating Reverse Data into the Credit Memo Table for Parent CreditID
     ----------------------------------------------------------------------------------    
     Update Invoices.dbo.CreditMemo
     set    ReversedBy     = @IPVC_ModifiedBy,
            ReversedDate   = @LDT_SystemDate,
            SystemLogDate  = @LDT_SystemDate
     Where CreditMemoIDSeq = @IPVC_ParentCreditMemoIDSeq
     and   InvoiceIDSeq    = @LVC_InvoiceIDSeq;
  end 
  ------------------------------------------------------------------------------------
  --Sync $$$ amount totals.
  ------------------------------------------------------------------------------------
  Exec Invoices.dbo.uspInvoices_SyncInvoiceTables @IPVC_InvoiceID = @LVC_InvoiceIDSeq;
  ------------------------------------------------------------------------------------
END  
GO
