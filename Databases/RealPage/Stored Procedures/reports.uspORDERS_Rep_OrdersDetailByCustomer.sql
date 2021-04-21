SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : [uspORDERS_Rep_OrdersDetailByCustomer]      
-- Description     : This procedure gets Orders Details based on Customer.
-- Input Parameters: All Input Parameters are Optional
-- Code Example    : exec [dbo].[uspORDERS_Rep_OrdersDetailByCustomer]    
--													@IPD_StartDate     = '',
--													@IPD_EndDate       = '',
--													@IPVC_CompanyID    = 'C0812000008',
--													@IPVC_CustomerName = '',
--													@IPVC_OrderStatus  = '',
--													@IPVC_ReportingType= '',
--													@IPVC_AccountID    = '',
--													@IPVC_AccountName  = '',
--													@IPVC_State        = '', 
--													@IPVC_PlatformCode = '',
--													@IPVC_FamilyCode   = '',
--													@IPVC_ProductName  = ''
--				
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 12/18/2008      : Stored Procedure Created.
-- 08/23/2010      : Naval Kishore Modified to add Column AnnualizedNet. Defect # 7788. 
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_OrdersDetailByCustomer]      
(      
 @IPD_StartDate      datetime     = '',
 @IPD_EndDate        datetime     = '',
 @IPVC_CompanyID     varchar(50)  = '',
 @IPVC_CustomerName  varchar(100) = '',
 @IPVC_OrderStatus   varchar(70)  = '',
 @IPVC_ReportingType varchar(4)   = '',
 @IPVC_AccountID     varchar(50)  = '',
 @IPVC_AccountName   varchar(100) = '',
 @IPVC_State         varchar(3)   = '', 
 @IPVC_PlatformCode  varchar(3)   = '',
 @IPVC_FamilyCode    varchar(3)   = '',
 @IPVC_ProductName   varchar(255) = ''
)      
As      
Begin         
Set nocount on   
 --------------------------------------------------------------------------
  set @IPVC_CompanyID     = nullif(@IPVC_CompanyID,'')
  set @IPVC_OrderStatus   = nullif(@IPVC_OrderStatus,'')
  set @IPVC_ReportingType = nullif(@IPVC_ReportingType,'')
  set @IPVC_AccountID     = nullif(@IPVC_AccountID,'')
  set @IPVC_AccountName   = @IPVC_AccountName
  set @IPVC_State         = nullif(@IPVC_State,'')
  set @IPVC_PlatformCode  = nullif(@IPVC_PlatformCode,'')
  set @IPVC_FamilyCode    = nullif(@IPVC_FamilyCode,'')
--------------------------------------------------------------------------
Select O.CompanyIDSeq                                                                     as CustomerID,
       Max(C.Name)                                                                        as CustomerName,
       O.AccountIDSeq                                                                     as AccountID,
       Max(coalesce(PROP.Name,C.Name))                                                    as AccountName,
       Max(coalesce(O.QuoteIDSeq,''))                                                     as QuoteIDSeq,
       O.OrderIDSeq                                                                       as OrderID,
       Max(convert(varchar(15),O.ApprovedDate,101))                                       as OrderDate,
       Max(P.DisplayName)                                                                 as ProductName,
       (Select Top 1 X.Name 
        from Orders.dbo.OrderStatusType X with (nolock)
        where X.Code = MAX((Case when OI.Chargetypecode = 'ILF' then OI.StatusCode
                                 else NULL
                            End)
                          )
       )                                                                                  as ILFStatus,
       (Select Top 1 X.Name 
        from Orders.dbo.OrderStatusType X with (nolock)
        where X.Code = MAX((Case when OI.Chargetypecode = 'ACS' then OI.StatusCode
                                 else NULL
                            End)
                          )
       )                                                                                  as AccessStatus,
       MAX((Case when OI.Chargetypecode = 'ACS' then convert(varchar(15),OI.ActivationStartDate,101)
                 else NULL
            end)
           )                                                                              as AccessStartDate,
       MAX((Case when OI.Chargetypecode = 'ACS' then convert(varchar(15),OI.ActivationEndDate,101)
                 else NULL
            end)
           )                                                                              as AccessEndDate,
       MAX((Case when OI.Chargetypecode = 'ACS' then convert(varchar(15),OI.CancelDate,101)
                 else NULL
            end)
           )                                                                              as AccessCancelledDate,
       
       (Select Top 1 X.Name 
        from Products.dbo.Measure X with (nolock)
        where X.Code = MAX((Case when OI.Chargetypecode = 'ACS' then OI.MeasureCode
                                 else NULL
                            End)
                          )
       )                                                                                  as AccessPriceBy,
       (Select Top 1 X.Name 
        from Products.dbo.Frequency X with (nolock)
        where X.Code = MAX((Case when OI.Chargetypecode = 'ACS' then OI.FrequencyCode
                                 else NULL
                            End)
                          )
       )                                                                                  as AccessBillingFrequency,
       Max(coalesce(Prop.SitemasterId,C.SitemasterId))                                    as SiteMasterID,
       Max(coalesce(Prop.LegacyRegistrationCode,C.LegacyRegistrationCode))                as LegacyRegistrationCode,
       (select  Top 1 Acc.EpicorCustomerCode 
        from Customers.dbo.Account Acc with (nolock)
        where Acc.CompanyIDSeq = max(C.IDSeq) and Acc.AccountTypeCode='AHOFF')            as CustomerEpicorCode,
       Max(A.EpicorCustomerCode)                                                          as AccountEpicorCode,
       Max(coalesce(AD.AddressLine1,''))                                                  as AccountAddress,
       Max(coalesce(AD.city,''))                                                          as Accountcity,
       Max(coalesce(AD.state,''))                                                         as Accountstate,
       Max(coalesce(AD.zip,''))                                                           as Accountzip,
       Max(coalesce(AD.PhoneVoice1,AD.PhoneVoice2,''))                                    as AccountPhone,
       Max(coalesce(AD.email,''))                                                         as Accountemail,
       Max(Coalesce(Prop.Units,''))                                                       as AccountUnits,
       Max(Coalesce(Prop.Beds,''))                                                        as AccountBeds,
       Max(Coalesce(Prop.PPUPercentage,''))                                               as AccountPPUPercent,
       sum((case when OI.Chargetypecode = 'ILF' then OI.NetExtYear1ChargeAmount
                  else 0
            end)
          )                                                                               as AnnualizedILFNet,
       sum((case when OI.Chargetypecode = 'ACS' then OI.NetExtYear1ChargeAmount
                  else 0
            end)
          )                                                                               as AnnualizedNet
From  ORDERS.dbo.[ORDER]     O  with (nolock)
inner Join
      CUSTOMERS.dbo.ACCOUNT  A with (nolock)
on    O.AccountIDSeq = A.IDSeq
and   O.CompanyIDSeq = isnull(@IPVC_CompanyID,O.CompanyIDSeq)
and   A.CompanyIDSeq = isnull(@IPVC_CompanyID,A.CompanyIDSeq)
and   O.AccountIDSeq = isnull(@IPVC_AccountID,O.AccountIDSeq)
and   A.IDSeq        = isnull(@IPVC_AccountID,A.IDSeq)
and	  O.ApprovedDate >= isnull( nullif(@IPD_StartDate,'') ,O.ApprovedDate)
and	  O.ApprovedDate <= isnull( nullif(@IPD_EndDate,'') ,O.ApprovedDate)
inner Join
      CUSTOMERS.dbo.Company  C with (nolock)
on    O.CompanyIdSeq = C.IDSeq
and   A.CompanyIDSeq = C.IDSeq
and   C.IDSeq        = isnull(@IPVC_CompanyID,C.IDSeq)
and   C.Name         like '%' + @IPVC_CustomerName + '%'
inner Join
      ORDERS.dbo.ORDERITEM OI with (nolock)
on    O.Orderidseq         = OI.OrderIDSeq
and   OI.StatusCode        = isnull(@IPVC_OrderStatus,OI.StatusCode)
and   OI.ReportingTypeCode = isnull(@IPVC_ReportingType,OI.ReportingTypeCode)
inner join
      Products.dbo.Product P With (nolock)
on    OI.ProductCode  = P.Code
and   OI.Priceversion = P.Priceversion
and   P.PlatformCode  = isnull(@IPVC_PlatformCode,P.PlatformCode)
and   P.FamilyCode    = isnull(@IPVC_FamilyCode,P.FamilyCode)
and   P.DisplayName   like '%' + @IPVC_ProductName + '%'
Left outer join
      CUSTOMERS.dbo.Property Prop with (nolock)
on    A.PropertyIDSeq = Prop.IDSeq
inner join
      CUSTOMERS.dbo.Address AD with (nolock)
ON    AD.CompanyIDSeq = C.IDSeq
and   AD.CompanyIDSeq = isnull(@IPVC_CompanyID,AD.CompanyIDSeq)
and   AD.state        = isnull(@IPVC_State,AD.state)
and   coalesce(A.propertyidseq,'') = coalesce(AD.propertyidseq,'')
and   AD.AddressTypeCode           = (CASE A.AccountTypeCode WHEN 'APROP' Then 'PRO' ELSE 'COM' END)
Where (Prop.name like '%'+ @IPVC_AccountName +'%' or C.[name] like '%'+ @IPVC_AccountName +'%')
Group by O.CompanyIDSeq,O.AccountIDSeq,O.OrderIDSeq,OI.ProductCode
Order by CustomerName ASC,AccountName ASC,ProductName ASC,OrderDate ASC

End
GO
