SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_PushCreditMemoHeaderToEpicor @IPVC_InvoiceID = 'I0000000002',@IPVC_EpicorBatchCode=100

*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_PushCreditMemoHeaderToEpicor
-- Description     : This procedure select relevant info of Invoice Line Items to push to Epicor
-- Input Parameters: @IPVC_InvoiceID,@IPVC_EpicorBatchCode              
-- OUTPUT          : None.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_PushCreditMemoHeaderToEpicor 
--                         @IPVC_InvoiceID = 'I0000000002',@IPVC_EpicorBatchCode=100
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 05/13/2011	   : Surya Kondapalli  Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_PushCreditMemoHeaderToEpicor] (@IPVC_InvoiceID         varchar(50),
                                                               @IPVC_CreditMemoID      varchar(50),
                                                               @IPVC_EpicorBatchCode   varchar(50)
                                                              )
as
BEGIN
  set nocount on  
  -----------------------------------------------------------------
  --Final Select For Credit Memo Header  
  ----------------------------------------------------------------
  select distinct @IPVC_EpicorBatchCode                     as EpicorBatchCode,
         CM.CreditMemoIDSeq                        as TransactionIDSeq, 
         CM.InvoiceIDSeq                           as ApplyToInvoiceIDSeq, 
         'C'                                       as TransactionType,
         convert(varchar(12),CM.CreatedDate,101)   as TransactionCreatedDate,
         convert(varchar(12),CM.ApprovedDate,101)  as DocumentDate,
         convert(varchar(12),I.InvoiceDueDate,101) as InvoiceDueDate, -- This is not applicable for credits in epicor
         I.EpicorCustomerCode                      as EpicorCustomerCode,
         case CM.CreditTypeCode
          when 'PARC' then 'PC'
          when 'FULC' then 'FC'
          when 'TAXC' then 'TC' 
         end                                       as TransactionSubType,
         I.InvoiceTerms                            as InvoiceTerms,
         CM.TotalNetCreditAmount                   as ILFChargeAmount,
         0                                         as AccessChargeAmount,
         0                                         as TransactionChargeAmount,
         --CM.ILFCreditAmount                        as ILFChargeAmount,
         --CM.AccessCreditAmount                     as AccessChargeAmount,
         --CM.TransactionCreditAmount                as TransactionChargeAmount,
         CM.ShippingAndHandlingCreditAmount       as ShippingandHandlingAmount,
         CM.TaxAmount                             as TaxAmount, 
         I.BillToAccountName                      as BillToAccountName,
         I.BillToAddressLine1                     as BillToAddressLine1,
         I.BillToAddressLine2                     as BillToAddressLine2,
         I.BillToCity                             as BillToCity,
         I.BillToState                            as BillToState,
         I.BillToZip                              as BillToZipcode,
         I.BillToCountry                          as BillToCountry,
         I.BillToCountryCode                      as BillToCountryCode,
         I.ShipToAccountName                      as ShipToAccountName,
         I.ShipToAddressLine1                     as ShipToAddressLine1,
         I.ShipToAddressLine2                     as ShipToAddressLine2,
         I.ShipToCity                             as ShipToCity,
         I.ShipToState                            as ShipToState,
         I.ShipToZip                              as ShipToZipcode,
         I.ShipToCountry                          as ShipToCountry,
         I.ShipToCountryCode                      as ShipToCountryCode,
         CM.CreditMemoReversalFlag                as CreditMemoReversalFlag,
         CM.EpicorPostingCode                     as EpicorPostingCode,
         CM.TaxwareCompanyCode                    as TaxwareCompanyCode,
		 case	when P.Familycode = 'DCN' and ADR.CountryCode = 'CAN'   
				then 'CAD'  
				else 'USD' end					   as CurrencyCode   
  from   INVOICES.dbo.CreditMemo CM with (nolock)  
  inner join
         Invoices.dbo.Invoice  I with (nolock)
  on     CM.InvoiceIDSeq       = @IPVC_InvoiceID
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
  
  where    CM.InvoiceIDSeq       = I.InvoiceIDSeq
  and    I.InvoiceIDSeq        = @IPVC_InvoiceID
  and    CM.CreditMemoIDSeq    = @IPVC_CreditMemoID
  and    CM.SentToEpicorStatus = 'EPICOR PUSH PENDING'  
  and    CM.SentToEpicorFlag   = 0 
  and    CM.CreditMemoReversalFlag = 0 --> This denotes it is CreditMemo
  and    CM.CreditStatusCode   = 'APPR' 

END
GO
