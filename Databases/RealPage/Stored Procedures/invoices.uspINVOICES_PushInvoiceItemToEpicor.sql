SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_PushInvoiceItemToEpicor @IPVC_InvoiceID = 'I0901000009',@IPVC_EpicorBatchCode=100

*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_PushInvoiceItemToEpicor
-- Description     : This procedure select relevant info of Invoice Line Items to push to Epicor
-- Input Parameters: @IPVC_InvoiceID,@IPVC_EpicorBatchCode              
-- OUTPUT          : None.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_PushInvoiceItemToEpicor
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 09/08/2009      : Shashi Bhushan		#6992 altered to select TaxableCountryCode column value
-- 05/12/2010      : Shashi Bhushan		#7785 altered to select lastbillingperiodfromdate column value when the chargetypecode is ILF
-- 05/13/2010      : Shashi Bhushan		#7785 altered to to update comments
-- 08/19/2010      : Scott Hensley		#8312 is a modification for #7785, which was known to bring back more than more record
-- 11/17/2010      : Scott Hensley		#8778 Correct ILF Billing Period Date
-- 04/27/2011	   : Surya Kondapalli	Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_PushInvoiceItemToEpicor] (@IPVC_InvoiceID         varchar(50),
                                                          @IPVC_EpicorBatchCode   varchar(50)
                                                         )
as
BEGIN
  set nocount on
  -----------------------------------------------------------------  
  if exists (select top 1 1 from INVOICES.dbo.Invoice I with (nolock)
             where I.InvoiceIDSeq       = @IPVC_InvoiceID
             and   I.EpicorBatchCode    = @IPVC_EpicorBatchCode
             and   I.SentToEpicorStatus = 'EPICOR PUSH PENDING'
             and   I.PrintFlag          = 1
             and   I.SentToEpicorFlag   = 0  
             )
  begin

-- Get Country Code to identify Currency Code
Declare @CountryCode Varchar(3) 

Select  Top 1 @CountryCode =AD.CountryCode 
From INVOICES.dbo.Invoice I With (nolock)  
Inner Join Invoices.dbo.InvoiceItem II with (nolock)  
      on     II.InvoiceIDSeq  = I.InvoiceIDSeq  
Inner Join CUSTOMERS.DBO.ADDRESS AD WITH (nolock)  
      On    AD.CompanyIDSeq    = I.CompanyIDSeq  
      And      AD.AddressTypeCode = I.BillToAddressTypeCode   
      And     
    (  
      (AD.AddressTypeCode = I.BillToAddressTypeCode And   
       AD.AddressTypeCode Like 'PB%'                 And   
       coalesce(AD.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
      )  
      Or  
      (AD.AddressTypeCode = I.BillToAddressTypeCode And   
       AD.AddressTypeCode Not Like 'PB%'    
      )  
     )  
Where  I.InvoiceIDSeq = @IPVC_InvoiceID

    Select Finaltbl.* 
    from  
     (select @IPVC_EpicorBatchCode                     as EpicorBatchCode,              
            II.InvoiceIDSeq                            as TransactionIDSeq,  
            II.IDSeq                                   as TransactionItemIDSeq,  
            II.OrderItemIDSeq                          as OrderItemIDSeq,  
            'I'                                        as TransactionType,   
            P.DisplayName                              as ProductDisplayName,  
            II.chargetypecode                          as chargetypecode,  
            II.EffectiveQuantity                       as EffectiveQuantity,  
            ---------------------------------------------------------------  
            II.ChargeAmount                            as ChargeAmount,  
            ---------------------------------------------------------------  
            II.ExtChargeAmount                         as ExtChargeAmount,  
            ---------------------------------------------------------------  
            II.RevenueAccountCode                      as RevenueAccountCode,  
            II.DeferredRevenueAccountCode              as DeferredRevenueAccountCode,   
             ---------------------------------------------------------------  
            II.DiscountAmount                          as DiscountAmount,              
            II.TaxAmount                               as TaxAmount,  
            II.NetChargeAmount                         as NetChargeAmount,  
             ---------------------------------------------------------------  
            (Case when II.Measurecode = 'TRAN'
                    then convert(varchar(12),coalesce(II.TransactionDate,OI.ActivationStartDate),101)
              Else convert(varchar(12),OI.ActivationStartDate,101) 
             end)                                             as AccessStartDate, 
            (Case when II.Measurecode = 'TRAN'
                    then convert(varchar(12),coalesce(Dateadd(year,1,II.TransactionDate)-1,OI.ActivationEndDate),101)
              Else convert(varchar(12),OI.ActivationEndDate,101) 
             end)                                             as AccessEndDate,            
            ------------------------------------------------------------------                 
            II.RevenueRecognitionCode                  as RevenueRecognitionCode,  
            II.ProductCode                             as ProductCode,  
            II.RevenueTierCode                         as RevenueTierCode,  
             --------------------------------------------------------------- 
            (Case when II.Measurecode = 'TRAN'
                    then convert(varchar(12),coalesce(II.TransactionDate,II.BillingPeriodFromDate),101)
                  when II.chargetypecode = 'ACS'
                    then convert(varchar(12),II.BillingPeriodFromDate,101) 
                  when II.chargetypecode = 'ILF'
                    then isnull(   -- code change for defect #7785 begins here. For OPS, Invoices will be prorated if needed,but when a DRA is created 
                                (  -- for ILF item, then the DRA startdate should be taken as ACS 1st prorated/partial billing period, 
                                   -- else BillingPeriodFromDate should be passed to EPICOR
                                 select --MIN(convert(varchar(12),OrdItem.LastBillingPeriodFromDate,101)) 
                                 convert(varchar(12),MIN(OrdItem.LastBillingPeriodFromDate),101) --8778
                                 from ORDERS.dbo.ORDERITEM OrdItem with (nolock)
                                 where OrdItem.orderidseq      = OI.OrderIDSeq
                                   and OrdItem.OrderGroupIDSeq = OI.OrderGroupIDSeq
                                   and OrdItem.productcode     = OI.ProductCode
                                   and II.OrderIDSeq           = OrdItem.OrderIDSeq  
                                   and II.OrderGroupIDSeq      = OrdItem.OrderGroupIDSeq   
                                   and II.ProductCode          = OrdItem.ProductCode  
                                   and OrdItem.ChargeTypeCode  = 'ACS'
                                 ),convert(varchar(12),II.BillingPeriodFromDate,101)) -- code change for defect #7785 Ends here.for more info refer QC:7785
              Else convert(varchar(12),II.BillingPeriodFromDate,101) 
             end)                                             as BilledFromDate,  
            convert(varchar(12),II.BillingPeriodToDate,101)   as BilledToDate,   
             ---------------------------------------------------------------  
            OILF.IDSeq                                 as ILFOrderItemIDSeq,  
            II.InvoiceIDSeq                            as ApplyToInvoiceIDSeq,  
            II.IDSeq                                   as ApplyToInvoiceItemIDSeq,            
            -----------------------------------------------------------------
            case  II.chargetypecode when 'ILF' then 1
                                    when 'ACS' then 2
                                    else 3
             end                                       as SortOrder,
            -----------------------------------------------------------------
            P.Familycode                               as Familycode,
            II.TaxableState                            as TaxableState,
            II.TaxableCountryCode                      as TaxableCountryCode,
			case when P.Familycode = 'DCN' and @CountryCode = 'CAN' 
				 then 'CAD'
				 else 'USD'	
			end										  as CurrencyCode	
            -----------------------------------------------------------------
    from   INVOICES.dbo.InvoiceItem II with (nolock)   
    inner join ORDERS.dbo.ORDERITEM OI with (nolock)  
    on    II.InvoiceIDSeq  = @IPVC_InvoiceID  
    and   II.OrderIDSeq    = OI.OrderIDSeq  
    and   II.OrderGroupIDSeq=OI.OrderGroupIDSeq   
    and   II.OrderItemIDSeq= OI.IDSeq  
    and   II.ProductCode   = OI.ProductCode  
    and   II.ChargeTypeCode= OI.ChargeTypeCode  
    and   II.FrequencyCode = OI.FrequencyCode  
    and   II.MeasureCode   = OI.MeasureCode          
    inner  Join  
           PRODUCTS.dbo.Product P with (nolock)  
    on     II.InvoiceIDSeq = @IPVC_InvoiceID  
    and    II.Productcode  = P.Code  
    and    II.PriceVersion = P.PriceVersion  
    and    OI.ProductCode  = P.Code  
    and    OI.PriceVersion = P.PriceVersion  
    left outer join ORDERS.dbo.ORDERITEM OILF with (nolock)  
    on    II.InvoiceIDSeq     = @IPVC_InvoiceID  
    and   II.OrderIDSeq       = OILF.OrderIDSeq  
    and   II.OrderGroupIDSeq  = OILF.OrderGroupIDSeq       
    and   II.ProductCode      = OILF.ProductCode  
    and   OILF.ChargeTypeCode = 'ILF'
    where II.InvoiceIDSeq     = @IPVC_InvoiceID
    )as Finaltbl 
    Order by SortOrder ASC,ProductDisplayName ASC,AccessStartDate ASC,BilledFromDate ASC
  end
END
GO
