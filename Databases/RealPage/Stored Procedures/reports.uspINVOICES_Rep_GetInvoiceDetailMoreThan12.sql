SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_Rep_GetInvoiceDetailMoreThan12
-- Description     : This procedure gets Invoice Details with more than 12 Invoice Items pertaining to passed InvoiceID
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(15)
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_Rep_GetInvoiceDetailMoreThan12 @IPVC_InvoiceID ='I0710000230'    
-- 
-- 
-- Revision History:
-- Author          : Vidhya Venkatapathy
-- 4/03/2007      : Stored Procedure Created. this is used only in SRS report Invoice From
-- 10/31/2007      : Naval Kishore Modified adding Order By  ChargeTypeCode
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspINVOICES_Rep_GetInvoiceDetailMoreThan12] (
                                                           @IPVC_InvoiceID  varchar(50)  
                                                         )
AS
BEGIN 

	set nocount on 
	Declare @results as table(IDSeq                   bigint not null identity(1,1),
				  BundleName              Varchar(200),						
				  ChargeTypeCode          varchar(3),
				  ChargeType              varchar(20),
				  ProductGroup            varchar(100),
				  ProductCode             varchar(30),
				  ProductName             varchar(70),
--          MeasureCode             varchar(20),
--          FrequencyCode           varchar(20),
          Quantity                decimal(18,2),
				  BillingPeriod           Varchar(50),
          TaxAmount               numeric(10,5),
				  NetAmount               numeric(10,5),
				  BillingPeriodFromDate   varchar(50),
				  BillingPeriodEndDate    varchar(50),
          BundleCode              char(2),
				  SortOrder               INT,
				  CustomBundleEnabledFlag int				
				 )
  
  Declare @LI_CustomBundleNameEnabledFlag int
  DECLARE @LC_GroupIDSeq                  bigint

  SELECT @LI_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag,
         @LC_GroupIDSeq = IDSeq FROM Invoices..InvoiceGroup 
  WHERE InvoiceIDSeq =  @IPVC_InvoiceID 
 
	insert into @results (BundleName,ChargeTypeCode,ChargeType,ProductCode,ProductName,--MeasureCode,FrequencyCode,
                        Quantity,BillingPeriod,TaxAmount,NetAmount,BillingPeriodFromDate,BillingPeriodEndDate,BundleCode,SortOrder, CustomBundleEnabledFlag)
	Select	      IG.[Name]                                                      as BundleName,
                II.ChargeTypeCode                                              as ChargeTypeCode,
                C.Name                                                         as ChargeType, 
                (case when IG.CustomBundleNameEnabledFlag = 1 then ''
                      else II.ProductCode
                 end )                                                         as ProductCode, 
		           (case when IG.CustomBundleNameEnabledFlag = 1 then IG.[Name]
                      else P.DisplayName
                end )	                                                         as ProductName,
--                II.MeasureCode                                                 as MeasureCode,
--                II.FrequencyCode                                               as FrequencyCode,         
                II.Quantity                                                    as Quantity,
                Convert(varchar(50),II.BillingPeriodFromDate,101) + ' - ' + 
                       Convert(varchar(12),II.BillingPeriodToDate,101)       as BillingPeriod,
                Sum(II.TaxAmount)                                              as TaxAmount,
		            Sum(II.NetChargeAmount)                                        as NetChargeAmount,
		            Convert(varchar(50),II.BillingPeriodFromDate,101)              as BillingPeriodFromDate,
		            Convert(varchar(52),II.BillingPeriodToDate,101)              as BillingPeriodEndDate,
                (case when IG.CustomBundleNameEnabledFlag = 1 then 'CB'
                      else 'PR'
                 end )                                                         as BundleCode,
                (Case when II.ChargeTypeCode = 'ILF' then 1 
                      when II.ChargeTypeCode = 'ACS' then 2
                      else 3 
                 end)                                                          as SortOrder,
				IG.CustomBundleNameEnabledFlag								   as CustomBundleEnabledFlag			
	from       Invoices.dbo.Invoice      I   with (nolock)
	Inner Join Invoices.dbo.InvoiceGroup IG  with (nolock)
        on         IG.InvoiceIDSeq = I.InvoiceIDSeq
	Inner Join Invoices.dbo.InvoiceItem II   with (nolock)
        on         II.InvoiceGroupIDSeq=IG.IDSeq
	and        IG.OrderIDSeq = II.OrderIDSeq 
        and        IG.OrderGroupIDSeq = II.OrderGroupIDSeq
	Inner Join Products.dbo.Product      P   with (nolock) 
        on         P.Code=II.ProductCode 
        and        P.PriceVersion = II.PriceVersion
	Inner Join Products.dbo.ChargeType C (nolock) on C.Code = II.ChargeTypeCode 
	Where I.InvoiceIDSeq = @IPVC_InvoiceID
        AND II.InvoiceIDSeq  = @IPVC_InvoiceID
        Group By IG.[Name],II.ChargeTypeCode,C.Name,
                 (case when IG.CustomBundleNameEnabledFlag = 1 then ''
                       else II.ProductCode
                  end),
                 (case when IG.CustomBundleNameEnabledFlag = 1 then IG.[Name]
                       else P.DisplayName
                 end ),
--                 II.MeasureCode,II.FrequencyCode, 
                 II.BillingPeriodFromDate,II.BillingPeriodToDate,IG.CustomBundleNameEnabledFlag,II.Quantity  
        Order by SortOrder,II.ChargeTypeCode,ProductName,II.BillingPeriodFromDate,II.BillingPeriodToDate

  IF (@LI_CustomBundleNameEnabledFlag = 1)
  BEGIN
    insert into @results (BundleName,ChargeTypeCode,ChargeType,ProductCode,ProductName,--MeasureCode,FrequencyCode,
                          Quantity,BillingPeriod,TaxAmount,NetAmount,BillingPeriodFromDate,BillingPeriodEndDate,
                          BundleCode,SortOrder, CustomBundleEnabledFlag)
	Select	      IG.[Name]                                                      as BundleName,
                II.ChargeTypeCode                                              as ChargeTypeCode,
                C.Name                                                         as ChargeType, 
                II.ProductCode                                                 as ProductCode, 
		            P.DisplayName                                                  as ProductName,
--                II.MeasureCode                                                 as MeasureCode,
--                II.FrequencyCode                                               as FrequencyCode,         
                II.Quantity                                                    as Quantity,
                Convert(varchar(50),II.BillingPeriodFromDate,101) + ' - ' + 
                       Convert(varchar(12),II.BillingPeriodToDate,101)       as BillingPeriod,
                0                                                              as TaxAmount,
		            0                                                              as NetChargeAmount,
		            Convert(varchar(50),II.BillingPeriodFromDate,101)              as BillingPeriodFromDate,
		            Convert(varchar(52),II.BillingPeriodToDate,101)              as BillingPeriodEndDate,
                'PC'                                                           as BundleCode,
                (Case when II.ChargeTypeCode = 'ILF' then 1 
                      when II.ChargeTypeCode = 'ACS' then 2
                      else 3 
                 end)                                                          as SortOrder,
				@LI_CustomBundleNameEnabledFlag								   as CustomBundleEnabledFlag			
	from       Invoices.dbo.InvoiceItem      II   with (nolock)
	Inner Join Invoices.dbo.InvoiceGroup IG  with (nolock)
        on         IG.InvoiceIDSeq = II.InvoiceIDSeq
	Inner Join Products.dbo.Product      P   with (nolock) 
        on         P.Code=II.ProductCode 
        and        P.PriceVersion = II.PriceVersion
	Inner Join Products.dbo.ChargeType C (nolock) on C.Code = II.ChargeTypeCode 
	Where II.InvoiceIDSeq = @IPVC_InvoiceID AND II.InvoiceGroupIDSeq = @LC_GroupIDSeq
        AND IG.CustomBundleNameEnabledFlag = 1
        Group By IG.[Name],II.ChargeTypeCode,C.Name,
                 (case when IG.CustomBundleNameEnabledFlag = 1 then ''
                       else II.ProductCode
                  end),
                 (case when IG.CustomBundleNameEnabledFlag = 1 then IG.[Name]
                       else P.DisplayName
                 end ),
--                 II.MeasureCode,II.FrequencyCode, 
                 II.BillingPeriodFromDate,II.BillingPeriodToDate,II.ProductCode,P.DisplayName,II.Quantity  
        Order by SortOrder,II.ChargeTypeCode,ProductName,II.BillingPeriodFromDate,II.BillingPeriodToDate

  END

	Select Top 12 ChargeTypeCode, BundleName, ChargeType,--MeasureCode,FrequencyCode,
              Quantity,ProductGroup,ProductCode,ProductName,
               BillingPeriod,
               NetAmount as UnformattedNetAmount,
               INVOICES.DBO.fn_FormatCurrency(NetAmount,1,2) as NetAmount,
               TaxAmount as UnformattedTaxAmount,
               INVOICES.DBO.fn_FormatCurrency(TaxAmount,1,2) as TaxAmount,
               BillingPeriodFromDate,BillingPeriodEndDate,BundleCode, SortOrder, CustomBundleEnabledFlag
  from     @results 
  Group By CustomBundleEnabledFlag, ChargeTypeCode, BundleName, ChargeType,--MeasureCode,FrequencyCode,
              Quantity,ProductGroup,ProductCode,ProductName,
               BillingPeriod,
               NetAmount,
               INVOICES.DBO.fn_FormatCurrency(NetAmount,1,2),
               TaxAmount,
               INVOICES.DBO.fn_FormatCurrency(TaxAmount,1,2),
               BillingPeriodFromDate,BillingPeriodEndDate,BundleCode, SortOrder
   Order By ChargeTypeCode desc
	
END 


--exec uspINVOICES_Rep_GetInvoiceDetail 'I0000001396'
--exec uspINVOICES_Rep_GetInvoiceDetail 'I0000001225'
GO
