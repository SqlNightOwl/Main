SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------- 
-- procedure   : uspORDERS_Rep_GetDataForProfitLossReport
-- server      : OMS
-- Database    : ORDERS
 
-- purpose     :  This procedure gets orders for P/L reporting passed Create Date for passed family
-- Input Parameters: 1. @IPDT_FromDate  as DateTime
--                   2. @IPDT_ToDate  as DateTime 
--
-- returns     : resultset as below

-- Example of how to call this stored procedure:
-- EXEC ORDERS.dbo.uspORDERS_Rep_GetDataForProfitLossReport @IPDT_FromDate = '01/01/2007', @IPDT_ToDate = '05/31/2009',@IPVC_FamilyCode = 'CFR'

-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2009-June-12	SRS  	        Initial creation
-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
----------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspORDERS_Rep_GetDataForProfitLossReport]   (@IPDT_FromDate     datetime,
                                                                     @IPDT_ToDate       datetime,
                                                                     @IPVC_FamilyCode   varchar(20)
                                                                    ) 
AS
BEGIN
  set nocount on;
  ------------------------------------------------------
  Select O.OrderIDSeq                       as [Order Number],
         Max(O.Createddate) as [Order Create Date],
         ---------------------------------------------
         O.CompanyIDSeq             as [OMS CompanyID],
         Max(C.SiteMasterID)        as [PMC ID],
         Max(C.Name)                as [PMC Name],
         O.PropertyIDSeq            as [OMS PropertyID],
         Max(PRP.SiteMasterID)      as [Site ID],
         Max(PRP.Name)              as [Property Name], 
         Max(PRP.Units)             as [Property Units],
         Max(PRP.Beds)              as [Property Beds],
         Max(PRP.PPUPercentage)     as [Property PPUPercentage],
         Max(convert(int,PRP.StudentLivingFlag)) as [IsStudentLiving],                
         ---------------------------------------------
         Max(P.DisplayName)         as [Product Name],
         ---------------------------------------------
         Max((CASE when OI.Chargetypecode = 'ILF' then M.Name else NULL End))                                                        as [ILF Measure],
         Max((CASE when OI.Chargetypecode = 'ILF' then FR.Name else NULL End))                                                       as [ILF Term],
         Max((CASE when OI.Chargetypecode = 'ILF' then OST.Name else NULL End))                                                      as [ILF OrderStatus],
         Max((CASE when OI.Chargetypecode = 'ILF' then OI.StartDate else NULL End))                                                  as [ILF StartDate],
         Max((CASE when OI.Chargetypecode = 'ILF' then OI.EndDate else NULL End))                                                    as [ILF EndDate],
         Max((CASE when OI.Chargetypecode = 'ILF' then OI.CancelDate else NULL End))                                                 as [ILF CancelDate],
         Sum((CASE when OI.Chargetypecode = 'ILF' then OI.NetChargeAmount else 0 End))                                               as [ILF NetChargeAmount],

         Sum((CASE when OI.Chargetypecode = 'ILF' 
                    then (case when OI.Migratedflag=1 then coalesce(II.NetChargeAmount,OI.NetChargeAmount) else coalesce(II.NetChargeAmount,0) end)
              else 0 End)
            )                                                                                                                        as [ILF InvoicedAmount],
         Sum((CASE when OI.Chargetypecode = 'ILF' then coalesce(II.CreditAmount,0) else 0 End))                                      as [ILF CreditAmount],
         Max((CASE when OI.Chargetypecode = 'ILF' then coalesce(II.BillingPeriodFromDate,OI.LastBillingPeriodFromDate) else NULL End)) as [ILF OMS LastBillingPeriodFromDate],
         Max((CASE when OI.Chargetypecode = 'ILF' then coalesce(II.BillingPeriodToDate,OI.LastBillingPeriodToDate) else NULL End))     as [ILF OMS LastBillingPeriodToDate],
    
         Max((CASE when OI.Chargetypecode = 'ILF' then CRT.ReasonName else NULL End))                                                  as [ILF CancelReason], 
           
         (case when Sum((CASE when OI.Chargetypecode = 'ILF' then coalesce(II.CreditAmount,0) else 0 End)) > 0
                 then  Max((CASE when OI.Chargetypecode = 'ILF' then S.CreditReason else NULL End)) 
               else NULL   
          end)                                                                                                                       as [ILF CreditReason],
        
         ---------------------------------------------
         Max((CASE when OI.Chargetypecode = 'ACS' then M.Name else NULL End))                                                        as [ACS Measure],
         Max((CASE when OI.Chargetypecode = 'ACS' then FR.Name else NULL End))                                                       as [ACS Term],
         Max((CASE when OI.Chargetypecode = 'ACS' then OST.Name else NULL End))                                                      as [ACS OrderStatus],
         Max((CASE when OI.Chargetypecode = 'ACS' then OI.StartDate else NULL End))                                                  as [ACS Contract StartDate],
         Max((CASE when OI.Chargetypecode = 'ACS' then OI.EndDate else NULL End))                                                    as [ACS Contract EndDate],
         Max((CASE when OI.Chargetypecode = 'ACS' then OI.CancelDate else NULL End))                                                 as [ACS CancelDate],
         Max((CASE when OI.Chargetypecode = 'ACS' then OI.RenewalCount else 0 End))                                                  as [ACS RenewalCount],  

         Sum((CASE when OI.Chargetypecode = 'ACS' then OI.NetChargeAmount else 0 End))                                               as [ACS NetChargeAmount],

          Sum((CASE when OI.Chargetypecode = 'ACS' 
                    then (case when OI.Migratedflag=1 then coalesce(II.NetChargeAmount,OI.NetChargeAmount) else coalesce(II.NetChargeAmount,0) end)
              else 0 End)
            )                                                                                                                        as [ACS InvoicedAmount],
         Sum((CASE when OI.Chargetypecode = 'ACS' then coalesce(II.CreditAmount,0) else 0 End))                                      as [ACS CreditAmount],
         Max((CASE when OI.Chargetypecode = 'ACS' then coalesce(II.BillingPeriodFromDate,OI.LastBillingPeriodFromDate) else NULL End)) as [ACS OMS LastBillingPeriodFromDate],
         Max((CASE when OI.Chargetypecode = 'ACS' then coalesce(II.BillingPeriodToDate,OI.LastBillingPeriodToDate) else NULL End))     as [ACS OMS LastBillingPeriodToDate],
    
    
         Max((CASE when OI.Chargetypecode = 'ACS' then CRT.ReasonName else NULL End))                                                  as [ACS CancelReason], 
           
         (case when Sum((CASE when OI.Chargetypecode = 'ACS' then coalesce(II.CreditAmount,0) else 0 End)) > 0
                 then  Max((CASE when OI.Chargetypecode = 'ACS' then S.CreditReason else NULL End)) 
               else NULL   
          end)                                                                                                                       as [ACS CreditReason]
 
         ---------------------------------------------
  From   ORDERS.dbo.[Order]     O  with (nolock)
  inner join
         ORDERS.dbo.[OrderItem] OI With (nolock)
  on     O.OrderIDSeq  = OI.OrderIDSeq
  and    OI.FamilyCode = @IPVC_FamilyCode     
  /*
  and    convert(datetime,convert(varchar(50),O.CreatedDate,101)) >= @IPDT_FromDate
  and    convert(datetime,convert(varchar(50),O.CreatedDate,101)) <= @IPDT_ToDate
  */
  and    convert(int,convert(varchar(50), O.CreatedDate,112)) >= convert(int,convert(varchar(50),@IPDT_FromDate,112))
  and    convert(int,convert(varchar(50), O.CreatedDate,112)) <= convert(int,convert(varchar(50),@IPDT_ToDate,112)) 
  /*and   OI.RenewalCount = (Select Max(XI.RenewalCount)
                           from   Orders.dbo.Orderitem XI With (nolock)
                           where  XI.Orderidseq = OI.Orderidseq
                           and    XI.Chargetypecode = OI.ChargetypeCode
                           and    XI.Measurecode    = OI.Measurecode
                           and    XI.Frequencycode  = OI.Frequencycode
                           and    XI.ProductCode    = OI.ProductCode
                          )
  */
  inner join
         Products.dbo.Product P with (nolock)
  on     OI.ProductCode = P.Code
  and    OI.Priceversion= P.Priceversion
  inner Join
         Products.dbo.Frequency FR With (nolock)
  on     OI.FrequencyCode = FR.Code
  inner join
         Products.dbo.Measure M with (nolock)
  on     OI.Measurecode = M.Code
  inner join
         ORDERS.dbo.[OrderStatusType] OST WITH (NOLOCK) 
  ON     OI.StatusCode = OST.Code 
  inner  Join
         CUSTOMERS.dbo.Company  C with (nolock)
  on     O.CompanyIDSeq = C.IDSeq
  Left outer Join
         CUSTOMERS.dbo.Property PRP with (nolock)
  on     O.PropertyIDSeq = PRP.IDSEQ
  Left outer join
         Orders.dbo.Reason CRT with (nolock)
  on     OI.Cancelreasoncode = CRT.Code
  Left outer join
         (select sum(XII.NetchargeAmount) as NetChargeAmount,
                 sum(XII.CreditAmount)    as CreditAmount,
                 Min(XII.BillingPeriodFromDate) as BillingPeriodFromDate,
                 MAX(XII.BillingPeriodToDate)   as BillingPeriodToDate,
                 XII.Orderidseq,
                 XII.OrdergroupIDSeq,XII.OrderitemIDSeq,
                 XII.OrderItemRenewalCount
          from   Invoices.dbo.InvoiceItem XII With (nolock)
          inner join
                 Invoices.dbo.Invoice XI With (nolock)
          on     XII.InvoiceIDSeq = XI.InvoiceIDSeq
          and    XI.PrintFlag = 1
          inner join
                 Orders.dbo.Orderitem OXI with (nolock)
          on     XII.Orderidseq      = OXI.Orderidseq
          and    XII.OrdergroupIDSeq = OXI.OrderGroupIDSeq
          and    XII.OrderitemIDSeq  = OXI.IDSeq
          and    XII.OrderItemRenewalCount = OXI.RenewalCount
          and    OXI.FamilyCode      = @IPVC_FamilyCode
          group by XII.Orderidseq,
                   XII.OrdergroupIDSeq,XII.OrderitemIDSeq,XII.OrderItemRenewalCount
         ) II
  on     II.Orderidseq      = OI.Orderidseq
  and    II.OrdergroupIDSeq = OI.OrderGroupIDSeq
  and    II.OrderitemIDSeq  = OI.IDSeq
  and    II.OrderItemRenewalCount = OI.RenewalCount
  Left outer join
         (select Max(CRDT.ReasonName) as CreditReason,
                 XI.Orderidseq, XI.OrdergroupIDSeq,XI.OrderitemIDSeq,
                 XI.OrderItemRenewalCount
          from   ORDERS.dbo.[Reason] CRDT with (nolock)
          inner join
                 Invoices.dbo.[CreditMemo] CM with (nolock)
          on     CRDT.Code = CM.CreditReasonCode
          and    CM.CreditStatusCode = 'APPR'
          Inner Join
                 Invoices.dbo.[CreditMemoItem] CMI with (nolock)
          on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
          Inner Join
                 Invoices.dbo.InvoiceItem XI with (nolock)
          on     CMI.InvoiceIDSeq     = XI.Invoiceidseq
          and    CMI.InvoiceitemIdSeq = XI.IDseq  
          group  by XI.Orderidseq, XI.OrdergroupIDSeq,XI.OrderitemIDSeq,XI.OrderItemRenewalCount
         ) S
  on     II.Orderidseq      = S.Orderidseq
  and    II.OrdergroupIDSeq = S.OrderGroupIDSeq
  and    II.OrderitemIDSeq  = S.OrderitemIDSeq
  and    II.OrderItemRenewalCount = OI.RenewalCount
  Group by O.OrderIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.ProductCode,OI.RenewalCount
  Order by [Order Create Date] ASC,[PMC Name] ASC,[Property Name] ASC,[Product Name] ASC,OI.RenewalCount ASC
END
GO
