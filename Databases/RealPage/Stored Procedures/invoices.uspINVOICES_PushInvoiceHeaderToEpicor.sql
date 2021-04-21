SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_PushInvoiceHeaderToEpicor @IPVC_InvoiceID = 'I0000000002',@IPVC_EpicorBatchCode=100

*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_PushInvoiceHeaderToEpicor
-- Description     : This procedure select relevant info of Invoice Line Items to push to Epicor
-- Input Parameters: @IPVC_InvoiceID,@IPVC_EpicorBatchCode              
-- OUTPUT          : None.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_PushInvoiceHeaderToEpicor 
--                         @IPVC_InvoiceID = 'I0000000002',@IPVC_EpicorBatchCode=100
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 05/13/2011	   : Surya Kondapalli  Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_PushInvoiceHeaderToEpicor] (@IPVC_InvoiceID         varchar(50),
                                                            @IPVC_EpicorBatchCode   varchar(50)
                                                           )
as
BEGIN
  set nocount on  
  -----------------------------------------------------------------
  --Final Select For Invoice Header  
  -----------------------------------------------------------------
  select distinct @IPVC_EpicorBatchCode            as EpicorBatchCode,
         I.InvoiceIDSeq                            as TransactionIDSeq,   
         I.InvoiceIDSeq                            as ApplyToInvoiceIDSeq,   
         'I'                                       as TransactionType,  
         I.CreatedDate                             as TransactionCreatedDate,  
         I.InvoiceDate                             as DocumentDate,  
         I.InvoiceDueDate                          as InvoiceDueDate,  
         I.EpicorCustomerCode                      as EpicorCustomerCode,  
         'Sales'                                   as TransactionSubType,  
         I.InvoiceTerms                            as InvoiceTerms,  
         I.ILFChargeAmount                         as ILFChargeAmount,  
         I.AccessChargeAmount                      as AccessChargeAmount,  
         I.TransactionChargeAmount                 as TransactionChargeAmount,  
         I.ShippingandHandlingAmount               as ShippingandHandlingAmount,  
         I.TaxAmount                               as TaxAmount,   
         I.BillToAccountName                       as BillToAccountName,  
         I.BillToAddressLine1                      as BillToAddressLine1,  
         I.BillToAddressLine2                      as BillToAddressLine2,  
         I.BillToCity                              as BillToCity,  
         I.BillToState                             as BillToState,  
         I.BillToZip                               as BillToZipcode,  
         I.BillToCountry                           as BillToCountry,  
         I.BillToCountryCode                       as BillToCountryCode,  
         I.ShipToAccountName                       as ShipToAccountName,  
         I.ShipToAddressLine1                      as ShipToAddressLine1,  
         I.ShipToAddressLine2                      as ShipToAddressLine2,  
         I.ShipToCity                              as ShipToCity,  
         I.ShipToState                             as ShipToState,  
         I.ShipToZip                               as ShipToZipcode,  
         I.ShipToCountry                           as ShipToCountry,  
         I.ShipToCountryCode                       as ShipToCountryCode,  
         I.EpicorPostingCode                       as EpicorPostingCode,  
         I.TaxwareCompanyCode                      as TaxwareCompanyCode,
         case	when P.Familycode = 'DCN' and ADR.CountryCode = 'CAN'   
				then 'CAD'  
				else 'USD' end					   as CurrencyCode   
  from   INVOICES.dbo.Invoice I with (nolock)    
  Inner Join Invoices.dbo.InvoiceItem II with (nolock)  
       on     II.InvoiceIDSeq  = I.InvoiceIDSeq  
  Inner Join Products.dbo.Product P with (nolock)  
       on     II.ProductCode = P.Code  
       And    II.PriceVersion= P.PriceVersion  
  Inner Join CUSTOMERS.DBO.ADDRESS ADR WITH (nolock)  
       On    ADR.CompanyIDSeq    = I.CompanyIDSeq  
       And      ADR.AddressTypeCode = I.BillToAddressTypeCode   
       And		(  
				   (ADR.AddressTypeCode = I.BillToAddressTypeCode And   
						ADR.AddressTypeCode Like 'PB%'                 And   
						coalesce(ADR.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
				   )  
				   Or  
				   (	ADR.AddressTypeCode = I.BillToAddressTypeCode And   
						ADR.AddressTypeCode Not Like 'PB%'    
				   )  
				 )  
  where  I.InvoiceIDSeq       = @IPVC_InvoiceID
  and    I.SentToEpicorStatus = 'EPICOR PUSH PENDING'
  and    I.PrintFlag          = 1
  and    I.SentToEpicorFlag   = 0    
  and    I.InvoiceIDSeq       = @IPVC_InvoiceID

END
GO
