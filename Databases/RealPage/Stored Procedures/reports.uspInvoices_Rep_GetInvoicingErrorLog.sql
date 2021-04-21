SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : [uspInvoices_Rep_GetInvoicingErrorLog]  
-- Description     : This procedure gets Custom Bundle Invoice Details   
-- Input Parameters: 
--                     
-- OUTPUT          :   
-- Code Example    : Exec INVOICES.DBO.[uspInvoices_Rep_GetInvoicingErrorLog] '','','','','','','',0
-- 
-- Revision History:  
-- Author          : Anand Chakravarthy  
-- 04/07/2009      : Stored Procedure Created.  
-- 02/17/2010      : Naval Kishore Modified the parameters as per defect #7553.(LeadDays Change)
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [reports].[uspInvoices_Rep_GetInvoicingErrorLog] (@IPVC_CustomerID    varchar(50) ='',
                                                               @IPVC_CustomerName  varchar(255)='',
                                                               @IPVC_AccountID     varchar(50) ='',
                                                               @IPVC_AccountName   varchar(255)='',
                                                               @IPVC_OrderID       varchar(50) ='',
                                                               @IPDT_BillCycleDate varchar(50) ='',
                                                               @IPDT_RunDate       varchar(50) ='',
                                                               @IPB_ErrorsOnly     bit         = 1
                                                              )
as
BEGIN --> Main Begin
  set nocount on ;
  ---------------------------------------------------------------
  select  @IPVC_CustomerID    = nullif(@IPVC_CustomerID,''),
          @IPVC_AccountID     = nullif(@IPVC_AccountID,''),
          @IPVC_OrderID       = nullif(@IPVC_OrderID,''),
          @IPDT_RunDate       = nullif(@IPDT_RunDate,''),
          @IPDT_BillCycleDate = nullif(@IPDT_BillCycleDate,''),
          @IPVC_CustomerName  = coalesce(@IPVC_CustomerName,''),
          @IPVC_AccountName   = coalesce(@IPVC_AccountName,'')
  ---------------------------------------------------------------
  select  IE.CompanyIDSeq                               as CompanyIDSeq,
          C.Name                                        as CompanyName,
          coalesce(P.Name,C.Name)                       as AccountName,          
          IE.AccountIDSeq                               as AccountIDSeq,
          IE.OrderIDSeq                                 as OrderIDSeq,
          OI.IDSeq                                      as OrderItemIDSeq,
          OI.OrderGroupIdSeq                            as OrderGroupIdSeq,
          IE.PropertyIDSeq                              as PropertyIDSeq,
          CONVERT(VARCHAR(20),IE.BeforeEOMBillingPeriodFromDate,101) as BeforeEOMBillingPeriodFromDate,
          CONVERT(VARCHAR(20),IE.BeforeEOMBillingPeriodToDate,101)   as BeforeEOMBillingPeriodToDate,
          CONVERT(VARCHAR(20),BillingCycleDate,101)                  as BillingCycleDate,
          IE.EOMRunType                                              as EOMRunType,
          IE.EOMRunBatchNumber                                       as EOMRunBatchNumber,
          (case when IE.EOMRunStatus = 1 then 'Succeeded'  
                when IE.EOMRunStatus = 2 then 'Failed'
                else 'Queued for Invoicing'
           end)                                                      as EOMRunStatus,
          IE.EOMRunDateTime                                          as EOMRunDateTime,
          IE.ErrorMessage                                            as ErrorMessage
  ----------------------
  from    INVOICES.dbo.InvoiceEOMRunLog IE with (nolock)
  inner join
          Orders.dbo.Orderitem OI with (nolock) 
  on      IE.OrderIdSeq     = OI.OrderIDSeq
  and     IE.OrderItemIDSeq = OI.IDSeq
  and     IE.AccountIDSeq   = coalesce(@IPVC_AccountID,IE.AccountIDSeq)
  and     OI.OrderIDSeq     = coalesce(@IPVC_OrderID,OI.OrderIDSeq)
  and     IE.OrderIDSeq     = coalesce(@IPVC_OrderID,IE.OrderIDSeq)
  and     IE.BillingCycleDate = coalesce(@IPDT_BillCycleDate,IE.BillingCycleDate)
  and    (isnull(@IPDT_RunDate,'') = '' or Convert(Varchar(12),IE.EOMRunDateTime,101) = @IPDT_RunDate)
--  and     convert(datetime,convert(varchar(20),IE.BillingCycleDate,101)) = coalesce(@IPDT_RunDate,convert(datetime,convert(varchar(20),IE.BillingCycleDate,101)))
    ----------------------
  and    ((@IPB_ErrorsOnly=1 and IE.EOMRunStatus = 2)
           OR
          (@IPB_ErrorsOnly=0)
         ) 
  inner join
          Customers.dbo.Company C with (nolock)
  on      IE.CompanyIDSeq  = C.IDSeq
  and     C.IDSeq          = coalesce(@IPVC_CustomerID,C.IDSeq)
  and     IE.CompanyIDSeq  = coalesce(@IPVC_CustomerID,IE.CompanyIDSeq)
--  and     (C.Name           like '%' + @IPVC_AccountName  + '%'
--            OR
--           C.Name           like '%' + @IPVC_CustomerName + '%'
--          )
  and     C.Name           like '%' + @IPVC_CustomerName + '%'
  left outer join
          Customers.dbo.Property P with (nolock)
  on      IE.CompanyIDSeq = P.PMCIDSeq
  and     C.IDSeq         = P.PMCIDSeq
  and     IE.PropertyIDSeq= P.IDSeq
--  and     P.Name           like '%' + @IPVC_AccountName + '%'
  ----------------------
  where  (
           (IE.PropertyIDSeq is null and C.Name           like '%' + @IPVC_AccountName  + '%')
             OR
           (IE.PropertyIDSeq is not null and P.Name           like '%' + @IPVC_AccountName + '%')
             AND
           C.Name           like '%' + @IPVC_CustomerName + '%'
         )
  ----------------------
END
GO
