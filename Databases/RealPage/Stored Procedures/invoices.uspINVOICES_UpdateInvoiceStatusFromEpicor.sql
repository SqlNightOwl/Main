SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_UpdateInvoiceStatusFromEpicor 
@IPVC_InvoiceID = '',@IPVC_EpicorBatchCode=100,@IPVC_EpicorIntegrationStatus='BATCH'

exec INVOICES.dbo.uspINVOICES_UpdateInvoiceStatusFromEpicor 
@IPVC_InvoiceID = 'I0000000004',@IPVC_EpicorBatchCode=100,@IPVC_EpicorIntegrationStatus='COMPLETED'

exec INVOICES.dbo.uspINVOICES_UpdateInvoiceStatusFromEpicor 
@IPVC_InvoiceID = 'I0000000005',@IPVC_EpicorBatchCode=100,@IPVC_EpicorIntegrationStatus='FAILED'
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_UpdateInvoiceStatusFromEpicor
-- Description     : This procedure Updates Invoices (for Epicor integration)
-- Input Parameters: @IPVC_InvoiceID
--                   @IPVC_BatchCode
--                   @IPVC_EpicorIntegrationStatus -- 'BATCH','FAILED','COMPLETED'
-- OUTPUT          : None.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_UpdateInvoiceStatusFromEpicor
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 01/10/2010	   : Surya Kondapalli, Defect# 8010 - Send to Epicor Enhancement Needed
-- 04/26/2011	   : Task# 388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UpdateInvoiceStatusFromEpicor] (@IPVC_InvoiceID               varchar(50)='',
                                                                @IPVC_EpicorBatchCode         varchar(50),
                                                                @IPVC_CreatedBy               varchar(100)='MIS System',
                                                                @IPVC_CreatedByIDSeq          varchar(50) = NULL,   
                                                                @IPVC_EpicorIntegrationStatus varchar(50)='BATCH',
																@IPVC_CountryCode			  varchar(3),
                                                                @IPVC_EpicorMessage           varchar(400)=''
															   )
AS
BEGIN
  set nocount on 
  ----------------------------------------------------------------------------
  if @IPVC_EpicorIntegrationStatus = 'BATCH'
  begin
    BEGIN TRANSACTION I;
      -- Marking Invoices that has (PrintFlag = 1 and SentToEpicorFlag = 0) for the Given Batch.
        IF (@IPVC_CountryCode = 'CAN')
		  Update I    
		  set    I.SentToEpicorStatus = 'EPICOR PUSH PENDING',  
				 I.EpicorBatchCode    = @IPVC_EpicorBatchCode  
		  From INVOICES.dbo.Invoice I With (nolock)  
		  Inner Join Invoices.dbo.InvoiceItem IIC with (nolock)  
		   on     IIC.InvoiceIDSeq  = I.InvoiceIDSeq  
		  Inner Join Products.dbo.Product PC with (nolock)  
		   on     IIC.ProductCode = PC.Code  
		   And    IIC.PriceVersion= PC.PriceVersion  
		  Inner Join CUSTOMERS.DBO.ADDRESS ADC WITH (nolock)  
		   On    ADC.CompanyIDSeq    = I.CompanyIDSeq  
		   And      ADC.AddressTypeCode = I.BillToAddressTypeCode   
		   And     (  
		   (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
			ADC.AddressTypeCode Like 'PB%'                 And   
			coalesce(ADC.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
		   )  
			 Or  
			 (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
		   ADC.AddressTypeCode Not Like 'PB%'    
			 )  
			)  
		Where  I.SentToEpicorStatus Is Null   
		And    I.PrintFlag = 1  
		And    I.SentToEpicorFlag = 0  
		And    ADC.CountryCode = 'CAN'  
		And    PC.FamilyCode = 'DCN'  
		And    I.ShipToCountryCode = @IPVC_CountryCode  
		And    exists (select top 1 1   
						 from   INVOICES.DBO.InvoiceItem II with (nolock)  
						 where  II.InvoiceIDSeq = I.InvoiceIDSeq  
					  )  
        Else 
		  Update I    
		  Set    I.SentToEpicorStatus = 'EPICOR PUSH PENDING',  
				 I.EpicorBatchCode    = @IPVC_EpicorBatchCode  
		  From INVOICES.dbo.Invoice I With (nolock)  
		  Inner Join Invoices.dbo.InvoiceItem IIC with (nolock)  
		   on     IIC.InvoiceIDSeq  = I.InvoiceIDSeq  
		  Inner Join Products.dbo.Product PC with (nolock)  
		   on     IIC.ProductCode = PC.Code  
		   And    IIC.PriceVersion= PC.PriceVersion  
		  Inner Join CUSTOMERS.DBO.ADDRESS ADC WITH (nolock)  
		   On    ADC.CompanyIDSeq    = I.CompanyIDSeq  
		   And      ADC.AddressTypeCode = I.BillToAddressTypeCode   
		   And     (  
		   (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
			ADC.AddressTypeCode Like 'PB%'                 And   
			coalesce(ADC.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
		   )  
			 Or  
			 (ADC.AddressTypeCode = I.BillToAddressTypeCode And   
		   ADC.AddressTypeCode Not Like 'PB%'    
			 )  
			)  
		Where  I.SentToEpicorStatus Is Null   
		And    I.PrintFlag = 1  
		And    I.SentToEpicorFlag = 0  
		And    PC.FamilyCode <> 'DCN'  
		And    exists (select top 1 1   
						 from   INVOICES.DBO.InvoiceItem II with (nolock)  
						 where  II.InvoiceIDSeq = I.InvoiceIDSeq  
					  )  
    COMMIT TRANSACTION I;
    ------------------------------------------------------
    --Insert record for the Batch into BatchProcess Table
    Insert into INVOICES.dbo.BatchProcess(EpicorBatchCode,BatchType,Status,
                                          InvoiceCount,SuccessCount,FailureCount,CreatedDate,
                                          CreatedByIDSeq,CreatedBy,EpicorCompanyName)
    select @IPVC_EpicorBatchCode as EpicorBatchCode,'INVOICE' as BatchType,'EPICOR PUSH PENDING' as Status,
           count(I.InvoiceIDSeq) as InvoiceCount,0 as SuccessCount,0 as FailureCount,
           getdate() as CreatedDate,@IPVC_CreatedByIDSeq as CreatedByIDSeq,@IPVC_CreatedByIDSeq as CreatedBy,
		   case when @IPVC_CountryCode = 'USA' 
				then 'USD'
				when @IPVC_CountryCode = 'CAN'
				then 'CAD' end as EpicorCompanyName
    from   INVOICES.DBO.INVOICE I with (nolock)
    where  I.EpicorBatchCode    = @IPVC_EpicorBatchCode
    and    I.SentToEpicorStatus = 'EPICOR PUSH PENDING'
    and    I.PrintFlag          = 1
    and    I.SentToEpicorFlag   = 0    
    ------------------------------------------------------
  end
  else if @IPVC_EpicorIntegrationStatus <> 'BATCH' and (@IPVC_InvoiceID is not NULL and @IPVC_InvoiceID<>'')
  begin
    --Update Final Status for the Invoice for the given Batch.
    Update I  
    set    I.SentToEpicorStatus = @IPVC_EpicorIntegrationStatus,
           I.SentToEpicorFlag = (case when @IPVC_EpicorIntegrationStatus = 'COMPLETED' then 1
                                      else 0
                                 end
                                ),
           I.SentToEpicorMessage = @IPVC_EpicorMessage
    from   INVOICES.DBO.INVOICE I with (nolock)
    where  I.InvoiceIDSeq = @IPVC_InvoiceID
    and    I.SentToEpicorStatus = 'EPICOR PUSH PENDING'
    and    I.PrintFlag = 1
    and    I.EpicorBatchCode = @IPVC_EpicorBatchCode
    ------------------------------------------------------
    -- Update record for the Batch in BatchProcess Table
    -- for successcount and FailureCount
    if @IPVC_EpicorIntegrationStatus = 'COMPLETED'
    begin
      Update BP
      set    BP.SuccessCount = BP.SuccessCount+1 
      from   INVOICES.dbo.BatchProcess BP with (nolock)
      where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode
	end
    else if @IPVC_EpicorIntegrationStatus = 'FAILED'
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
			  
	  Insert into INVOICES.dbo.BatchProcessDetail(EpicorBatchCode,BatchType,BatchDate,
                                          InvoiceIDSeq,CreditMemoIDSeq,SentToEpicorFailureMessage,CreatedDate,
                                          CreatedByIDSeq,EpicorCompanyName)
      select @IPVC_EpicorBatchCode as EpicorBatchCode,'INVOICE' as BatchType,@BatchDate as BatchDate, @IPVC_InvoiceID as InvoiceIDSeq, NULL as CreditMemoIDSeq,
           @IPVC_EpicorMessage as SentToEpicorFailureMessage, getdate() as CreatedDate,@IPVC_CreatedByIDSeq as CreatedByIDSeq,
		   case when @IPVC_CountryCode = 'CAN' 
				then 'CAD'
				else 'USD' end as EpicorCompanyName

      Update BP
      set    BP.FailureCount = BP.FailureCount+1 
      from   INVOICES.dbo.BatchProcess BP with (nolock)
      where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
    end
    ------------------------------------------------------
  end  
END
GO
