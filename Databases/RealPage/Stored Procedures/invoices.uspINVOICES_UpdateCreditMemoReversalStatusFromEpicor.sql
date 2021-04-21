SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_UpdateCreditMemoReversalStatusFromEpicor 
@IPVC_InvoiceID = '',@IPVC_CreditMemoID='',@IPVC_EpicorBatchCode=100,@IPVC_CashReceiptEpicorBatchCode=200,@IPVC_EpicorIntegrationStatus='BATCH'

exec INVOICES.dbo.uspINVOICES_UpdateCreditMemoReversalStatusFromEpicor 
@IPVC_InvoiceID = 'I0000000004',@IPVC_CreditMemoID = 'RI0000000015',@IPVC_EpicorBatchCode=100,@IPVC_CashReceiptEpicorBatchCode=200,@IPVC_EpicorIntegrationStatus='COMPLETED'

exec INVOICES.dbo.uspINVOICES_UpdateCreditMemoReversalStatusFromEpicor 
@IPVC_InvoiceID = 'I0000000005',@IPVC_CreditMemoID = 'RI0000000015',@IPVC_EpicorBatchCode=100,@IPVC_CashReceiptEpicorBatchCode=200,@IPVC_EpicorIntegrationStatus='FAILED'
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_UpdateCreditMemoReversalStatusFromEpicor
-- Description     : This procedure Updates CreditMemo Reversal approved records (for Epicor integration)
-- Input Parameters: @IPVC_InvoiceID
--                   @IPVC_CreditMemoID
--                   @IPVC_EpicorBatchCode
--                   @IPVC_CashReceiptEpicorBatchCode
--                   @IPVC_EpicorIntegrationStatus -- 'BATCH','FAILED','COMPLETED'
--                   @IPVC_EpicorMessage
-- OUTPUT          : None.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_UpdateCreditMemoReversalStatusFromEpicor
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 01/04/2010      : Surya Kondapalli - Defect# 8783: Create the Epicor integration for Credit Reversals
-- 01/10/2010      : Surya Kondapalli - Defect# 8010: Send to Epicor Enhancement Needed
-- 04/27/2011	   : Surya Kondapalli	Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
-- 05/26/2011	   : Surya Kondapalli -	Task# 335	 - Create the Epicor integration for Credit Reversals
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UpdateCreditMemoReversalStatusFromEpicor]
                                                               (@IPVC_InvoiceID                   varchar(50)='',
                                                                @IPVC_CreditMemoID                varchar(50)='',
                                                                @IPVC_EpicorBatchCode             varchar(50),  -----> Mandatory : This is EpicorBatchCode returned by call of EPICOR proc Proddata.dbo.custom_uspInsertBatchCtl @TransactionType = 'A' --> This is for cash receipt adjustment
                                                                @IPVC_CashReceiptEpicorBatchCode  varchar(50),  -----> Mandatory : This is EpicorBatchCode returned by call of EPICOR proc Proddata.dbo.custom_uspInsertBatchCtl @TransactionType = 'R' --> This is for cash receipt 
                                                                @IPVC_CreatedBy                   varchar(100)='MIS System',
                                                                @IPVC_CreatedByIDSeq              varchar(50) = NULL,   
                                                                @IPVC_EpicorIntegrationStatus     varchar(50)='BATCH',
                                                                @IPVC_CountryCode				  varchar(3),
                                                                @IPVC_EpicorMessage				  varchar(400)=''
															   )
AS
BEGIN
  set nocount on 
  ----------------------------------------------------------------------------
  if @IPVC_EpicorIntegrationStatus = 'BATCH'
  begin
    BEGIN TRANSACTION CMR;
      -- Marking CreditMemos Reversals that has (CreditMemoReversalFlag = 1 and SentToEpicorFlag = 0 and CreditStatusCode = 'APPR' ) for the Given Batch.
	  IF (@IPVC_CountryCode = 'CAN')
      Update CMR 
      set    CMR.SentToEpicorStatus = 'EPICOR PUSH PENDING',
             CMR.EpicorBatchCode    = @IPVC_EpicorBatchCode
      from   INVOICES.DBO.CreditMemo CMR with (nolock)
	  join   INVOICES.DBO.Invoice I with (nolock)
		On	 I.InvoiceIDSeq = CMR.InvoiceIDSeq
	  Join Invoices.dbo.InvoiceItem IIC with (nolock)  
		on     IIC.InvoiceIDSeq  = I.InvoiceIDSeq  
	  Join Products.dbo.Product PC with (nolock)  
		on     IIC.ProductCode = PC.Code  
		And    IIC.PriceVersion= PC.PriceVersion  
	 Join CUSTOMERS.DBO.ADDRESS ADC WITH (nolock)  
		on    ADC.CompanyIDSeq    = I.CompanyIDSeq  
		And   ADC.AddressTypeCode = I.BillToAddressTypeCode   
		And   (  
			   (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
				ADC.AddressTypeCode Like 'PB%'                 And   
				coalesce(ADC.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
			   )  
			 Or  
			  (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
			   ADC.AddressTypeCode Not Like 'PB%'    
			  )  
			)
      where  CMR.SentToEpicorStatus is null
      and    CMR.SentToEpicorFlag = 0 
      and    CMR.CreditMemoReversalFlag = 1 --> This denotes it is CreditMemo Reversal
      and    CMR.CreditStatusCode = 'APPR'
	  and    I.ShipToCountryCode = @IPVC_CountryCode
	  and    ADC.CountryCode = 'CAN'  
	  and    PC.FamilyCode = 'DCN'
      and    exists (select top 1 1 
                     from   INVOICES.DBO.CreditMemoItem CMI with (nolock)
                     where  CMI.CreditMemoIDSeq = CMR.CreditMemoIDSeq
                    )
	ELSE
		Update CM   
		  set    CM.SentToEpicorStatus = 'EPICOR PUSH PENDING',  
				 CM.EpicorBatchCode    = @IPVC_EpicorBatchCode  
		  from   INVOICES.DBO.CreditMemo CM with (nolock)  
		  join   INVOICES.DBO.Invoice I with (nolock)  
			on  I.InvoiceIDSeq = CM.InvoiceIDSeq  
		  Join Invoices.dbo.InvoiceItem IIC with (nolock)  
			on     IIC.InvoiceIDSeq  = I.InvoiceIDSeq  
		  Join Products.dbo.Product PC with (nolock)  
			on     IIC.ProductCode = PC.Code  
			And    IIC.PriceVersion= PC.PriceVersion  
		  Join CUSTOMERS.DBO.ADDRESS ADC WITH (nolock)  
			on    ADC.CompanyIDSeq    = I.CompanyIDSeq  
			And   ADC.AddressTypeCode = I.BillToAddressTypeCode   
			And   (  
			   (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
				ADC.AddressTypeCode Like 'PB%'                 And   
				coalesce(ADC.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
			   )  
				 Or  
				 (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
			   ADC.AddressTypeCode Not Like 'PB%'    
				 )  
				)  
		  where  CM.SentToEpicorStatus is null  
		  and    CM.SentToEpicorFlag = 0   
		  and    CM.CreditMemoReversalFlag = 1 --> This denotes it is CreditMemo Reversal  
		  and    CM.CreditStatusCode = 'APPR' 
		  and    PC.FamilyCode <> 'DCN' 
		  and    exists (select top 1 1   
						 from   INVOICES.DBO.CreditMemoItem CMI with (nolock)  
						 where  CMI.CreditMemoIDSeq = CM.CreditMemoIDSeq  
						) 
    COMMIT TRANSACTION CMR;
    ------------------------------------------------------
    --Insert record for the Batch into BatchProcess Table
    Insert into INVOICES.dbo.BatchProcess(EpicorBatchCode,CashReceiptEpicorBatchCode,BatchType,Status,
                                          InvoiceCount,SuccessCount,FailureCount,CreatedDate,
                                          CreatedByIDSeq,CreatedBy, EpicorCompanyName)
    select @IPVC_EpicorBatchCode  as EpicorBatchCode,@IPVC_CashReceiptEpicorBatchCode as CashReceiptEpicorBatchCode,
           'REVERSE CREDIT'       as BatchType,
           'EPICOR PUSH PENDING'  as Status,
           count(CMR.CreditMemoIDSeq) as InvoiceCount,0 as SuccessCount,0 as FailureCount,
           getdate() as CreatedDate,@IPVC_CreatedByIDSeq as CreatedByIDSeq,@IPVC_CreatedByIDSeq as CreatedBy,
		   case when @IPVC_CountryCode = 'USA' 
				then 'USD'
				when @IPVC_CountryCode = 'CAN'
				then 'CAD' end as EpicorCompanyName
    from   INVOICES.DBO.CREDITMEMO CMR with (nolock)
    where  CMR.EpicorBatchCode    = @IPVC_EpicorBatchCode
    and    CMR.SentToEpicorStatus = 'EPICOR PUSH PENDING'    
    and    CMR.SentToEpicorFlag   = 0 
    and    CMR.CreditMemoReversalFlag = 1 --> This denotes it is CreditMemo Reversal
    and    CMR.CreditStatusCode = 'APPR'    
    ------------------------------------------------------
  end
  else if @IPVC_EpicorIntegrationStatus <> 'BATCH' and (@IPVC_InvoiceID is not NULL and @IPVC_InvoiceID<>'')
  begin
    --Update Final Status for the Invoice for the given Batch.
    Update CM  
    set    CM.SentToEpicorStatus = replace(@IPVC_EpicorIntegrationStatus,'INVOICE','CREDIT'),
           CM.SentToEpicorFlag = (case when @IPVC_EpicorIntegrationStatus = 'COMPLETED' then 1
                                      else 0
                                 end
                                ),
           CM.SentToEpicorMessage = @IPVC_EpicorMessage
    from   INVOICES.DBO.CREDITMEMO CM with (nolock)
    where  CM.InvoiceIDSeq           = @IPVC_InvoiceID
    and    CM.CreditMemoIDSeq = @IPVC_CreditMemoID 
    and    CM.CreditMemoReversalFlag = 1 --> This denotes it is CreditMemo Reversal
    and    CM.SentToEpicorStatus     = 'EPICOR PUSH PENDING'
    and    CM.EpicorBatchCode        = @IPVC_EpicorBatchCode
    ------------------------------------------------------
    --Update record for the Batch in BatchProcess Table
    -- for successcount and FailureCount
    if @IPVC_EpicorIntegrationStatus = 'COMPLETED'
    begin
      Update BP
      set    BP.SuccessCount = BP.SuccessCount+1 
      from   INVOICES.dbo.BatchProcess BP with (nolock)
      where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
      and    BP.BatchType      ='REVERSE CREDIT'
    end
    else if (@IPVC_EpicorIntegrationStatus = 'FAILED' or @IPVC_EpicorIntegrationStatus = 'EPICOR INVOICE NOT POSTED')
    begin
    
    -- For Defect# 8010 - Send to Epicor Enhancement Needed: Insert failures for history data
	  
	  Declare @BatchDate DateTime
	  
	  Select @BatchDate = CreatedDate
	  From	 INVOICES.dbo.BatchProcess with (nolock)
      where  EpicorBatchCode=@IPVC_EpicorBatchCode
      
      IF (@IPVC_CreatedByIDSeq IS NULL OR @IPVC_CreatedByIDSeq = '')
		SELECT @IPVC_CreatedByIDSeq = CreatedByIDSeq
		FROM INVOICES.dbo.BatchProcess BP with (nolock)
		WHERE  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
		AND    BP.BatchType      ='REVERSE CREDIT'
	  
	  Insert into INVOICES.dbo.BatchProcessDetail(EpicorBatchCode,BatchType,BatchDate,
                                          InvoiceIDSeq,CreditMemoIDSeq,SentToEpicorFailureMessage,CreatedDate,
                                          CreatedByIDSeq,EpicorCompanyName)
      select @IPVC_EpicorBatchCode as EpicorBatchCode,'REVERSE CREDIT' as BatchType, @BatchDate as BatchDate, @IPVC_InvoiceID as InvoiceIDSeq, @IPVC_CreditMemoID as CreditMemoIDSeq,
           @IPVC_EpicorMessage as SentToEpicorFailureMessage, getdate() as CreatedDate,@IPVC_CreatedByIDSeq as CreatedByIDSeq, 
		   case when @IPVC_CountryCode = 'USA' 
				then 'USD'
				when @IPVC_CountryCode = 'CAN'
				then 'CAD' end as EpicorCompanyName
          
      Update BP
      set    BP.FailureCount = BP.FailureCount+1 
      from   INVOICES.dbo.BatchProcess BP with (nolock)
      where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
      and    BP.BatchType      ='REVERSE CREDIT'
    end
    ------------------------------------------------------
  end  
END
GO
