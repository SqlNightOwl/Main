SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  :  [ORDERS]     
-- Procedure Name  : [uspINVOICES_Rep_BillingSummaryView]      
-- Description     : This procedure gets Billing Details based on Customer. And this is based on the Excel File 'Billings Review Report.xls'     
-- Input Parameters: Except @IPDT_StartDate other Input parameters are optional      
--            
-- Code Example    : Exec [dbo].[uspINVOICES_Rep_BillingSummaryView]'','','','','','','08/24/2007'
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 07/24/2007      : Stored Procedure Created.      
------------------------------------------------------------------------------------------------------          
CREATE PROCEDURE [reports].[uspINVOICES_Rep_BillingSummaryView]      
(      
@IPVC_CompanyID		varchar(20) ='',
@IPVC_CustomerName  varchar(100) = '',
@IPVC_PropertyName  varchar(100) = '',
@IPC_ProductFamilyCode char(3) ='',
@IPVC_ProductName   varchar(255) = '',
@IPVC_AccountManager varchar(255) = '',
@IPDT_StartDate     Datetime = ''
)      
as      
BEGIN         
set nocount on  
------------------------------------------------------------
set @IPVC_CompanyID     = nullif(@IPVC_CompanyID, '')
set @IPVC_CustomerName  = @IPVC_CustomerName
set @IPVC_PropertyName  = @IPVC_PropertyName
set @IPC_ProductFamilyCode = nullif(@IPC_ProductFamilyCode, '')
set @IPVC_ProductName  = @IPVC_ProductName 
set @IPVC_AccountManager = nullif(@IPVC_AccountManager, '') 
--------------------------------------------------------------------------          
--Initialize Local Variables
-- This code is commented as these fields are mandatory from UI but 
-- can be un-commented and used while testing the procedure
	
	/*
	If(@IPDT_CurrentDate='')
		Begin                    -- Assigning Current Date
				Set @IPDT_CurrentDate =convert(varchar(50),getdate(),101)
		End  
	*/
-------------------------------------------------------------------     
--Declaring local table variables          
--------------------------------------------------------------------------      
Declare @LT_M_TempBillingReview  table   -- this local table variable is used to get monthly data 
(
  ProductCode char(30) null,
  PlatformName varchar(50) null,
  FamilyCode char(3) null,
  FamilyName varchar(50) null,
  CategoryName varchar(70) null,
  ProductName varchar(255) null,

  Mon_Gross money null default 0.00,  
  Mon_CreditAmount money   null default 0.00,
  Mon_Actual money null default 0.00,
  Mon_Budget int null,
  Mon_Variance int null,
  Mon_VariancePercent int null
)

Declare @LT_Q_TempBillingReview  table   -- this local table variable is used to get Quarterly data
(
  ProductCode char(30) null,
  PlatformName varchar(50) null,
  FamilyCode char(3) null,
  FamilyName varchar(50) null,
  CategoryName varchar(70) null,
  ProductName varchar(255) null,

  Qr_Gross money null default 0.00,  
  Qr_CreditAmount money null default 0.00,
  Qr_Actual money null default 0.00,
  Qr_Budget int null,
  Qr_Variance int null,
  Qr_VariancePercent int null

)

Declare @LT_Y_TempBillingReview  table  -- this local table variable is used to get Yearly data
(
  ProductCode char(30) null,
  PlatformName varchar(50) null,
  FamilyCode char(3) null,
  FamilyName varchar(50) null,
  CategoryName varchar(70) null,
  ProductName varchar(255) null,

  Yr_Gross money null default 0.00,  
  Yr_CreditAmount money null default 0.00,
  Yr_Actual money null default 0.00,
  Yr_Budget int null,
  Yr_Variance int null,
  Yr_VariancePercent int null 
)

Declare @LT_Complete_TempBillingReview table  -- this table variable is used to consolidate data related to month/quarter/year
(
  ProductCode char(30) null,
  PlatformName varchar(50) null,
  FamilyCode char(3) null,
  FamilyName varchar(50) null,
  CategoryName varchar(70) null,
  ProductName varchar(255) null,

  Mon_Gross money null default 0.00,  
  Mon_CreditAmount money   null default 0.00,
  Mon_Actual money null default 0.00,
  Mon_Budget int null,
  Mon_Variance int null,
  Mon_VariancePercent int null,

  Qr_Gross money null default 0.00,  
  Qr_CreditAmount money null default 0.00,
  Qr_Actual money null default 0.00,
  Qr_Budget int null,
  Qr_Variance int null,
  Qr_VariancePercent int null,

  Yr_Gross money null default 0.00,  
  Yr_CreditAmount money null default 0.00,
  Yr_Actual money null default 0.00,
  Yr_Budget int null,
  Yr_Variance int null,
  Yr_VariancePercent int null
)
declare @LD_MinDate datetime
declare @LD_MaxDate datetime
-------------------------------------------------------------------------
--                          *****MONTH Data*****
----------------------------------------------------------------------------
set @LD_MinDate = (select DATEADD(mm, DATEDIFF(mm,0,convert(varchar(12),@IPDT_StartDate,101)), 0))
set @LD_MaxDate = convert(varchar(12),@IPDT_StartDate,101)

INSERT INTO @LT_M_TempBillingReview  
(
  ProductCode,PlatformName,FamilyCode,FamilyName,CategoryName,ProductName,
  Mon_Gross,Mon_CreditAmount,Mon_Actual,Mon_Budget,Mon_Variance,Mon_VariancePercent
)    
select distinct Pr.Code as ProductCode,
  PF.Name as platformName,
  Fa.Code as FamilyCode,
  Fa.Name as FamilyName,
  Cat.Name as CategoryName,
  P.Name as ProductName,
  convert(numeric(30,2),SUM(Inv.ILFChargeAmount + Inv.AccessChargeAmount + Inv.TransactionChargeAmount)) as Mon_Gross,
  SUM(Inv.CreditAmount) as Mon_CreditAmount,
  convert(numeric(30,2),SUM((Inv.ILFChargeAmount + Inv.AccessChargeAmount + Inv.TransactionChargeAmount)-(Inv.CreditAmount)))as Mon_Actual,
  '' as Mon_Budget,
  '' as Mon_Variance,
  '' as Mon_VariancePercent
FROM invoices.dbo.invoice Inv with (nolock)
  JOIN invoices.dbo.invoiceItem InvI with (nolock) on Inv.InvoiceIDSeq=InvI.InvoiceIDSeq
  join Products.dbo.Product Pr with (nolock) on Pr.Code=InvI.ProductCode and Pr.PriceVersion=InvI.PriceVersion and Pr.DisplayName like '%' + @IPVC_ProductName + '%'
  join Products.dbo.[Platform] PF with (nolock) on PF.Code=Pr.PlatformCode
  JOIN products.dbo.Family Fa with (nolock) on  Pr.FamilyCode=Fa.Code
  JOIN products.dbo.category Cat with (nolock) on  Pr.CategoryCode=Cat.Code
  join Customers.dbo.Company C with (nolock) on C.IDSeq = Inv.CompanyIDSeq
  join Customers.dbo.Property P with (nolock) on P.IDSeq=Inv.PropertyIDSeq
  join Orders.dbo.[Order] O  with (nolock) on O.orderIDSeq=InvI.orderIDSeq
    and  C.IDSeq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null)
                             then @IPVC_CompanyID
                           else C.IDSeq
                      end)
    and C.Name like '%' + @IPVC_CustomerName + '%'
    and Pr.Name like '%' + @IPVC_PropertyName + '%'
    and  Fa.Code = (case when (@IPC_ProductFamilyCode <> '' and @IPC_ProductFamilyCode is not null)
                             then @IPC_ProductFamilyCode
                           else Fa.Code
                      end)
    and ((@IPVC_AccountManager is null) or EXISTS(select 1 
												from  Quotes.dbo.QuoteSaleAgent QSA with (nolock)
												where QSA.QuoteIDSeq=O.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPVC_AccountManager))
 and Inv.InvoiceDate between @LD_MinDate and @LD_MaxDate 
 GROUP BY Pr.Code,PF.Name,P.Name,Fa.Code,Fa.Name,Cat.Name,P.Name
-------------------------------------------------------------------------
--                          *****QUARTER Data*****
----------------------------------------------------------------------------
set @LD_MinDate = (select DATEADD(qq, DATEDIFF(qq,0,convert(varchar(12),@IPDT_StartDate,101)), 0))
set @LD_MaxDate = convert(varchar(12),@IPDT_StartDate,101)


INSERT INTO @LT_Q_TempBillingReview  
(
  ProductCode,PlatformName,FamilyCode,FamilyName,CategoryName,ProductName,
  Qr_Gross,Qr_CreditAmount,Qr_Actual,Qr_Budget,Qr_Variance,Qr_VariancePercent
)    
select distinct Pr.Code as ProductCode,
  PF.Name as platformName,
  Fa.Code as FamilyCode,
  Fa.Name as FamilyName,
  Cat.Name as CategoryName,
  P.Name as ProductName,
  convert(numeric(30,2),SUM(Inv.ILFChargeAmount + Inv.AccessChargeAmount + Inv.TransactionChargeAmount)) as Qr_Gross,
  SUM(Inv.CreditAmount) as Qr_CreditAmount,
  convert(numeric(30,2),SUM((Inv.ILFChargeAmount + Inv.AccessChargeAmount + Inv.TransactionChargeAmount)-(Inv.CreditAmount)))as Qr_Actual,
  '' as Qr_Budget,
  '' as Qr_Variance,
  '' as Qr_VariancePercent
FROM invoices.dbo.invoice Inv with (nolock)
  JOIN invoices.dbo.invoiceItem InvI with (nolock) on Inv.InvoiceIDSeq=InvI.InvoiceIDSeq
  join Products.dbo.Product Pr with (nolock) on Pr.Code=InvI.ProductCode and Pr.PriceVersion=InvI.PriceVersion and Pr.DisplayName like '%' + @IPVC_ProductName + '%'
  join Products.dbo.[Platform] PF with (nolock) on PF.Code=Pr.PlatformCode
  JOIN products.dbo.Family Fa with (nolock) on  Pr.FamilyCode=Fa.Code
  JOIN products.dbo.category Cat with (nolock) on  Pr.CategoryCode=Cat.Code
  join Customers.dbo.Company C with (nolock) on C.IDSeq = Inv.CompanyIDSeq
  join Customers.dbo.Property P with (nolock) on P.IDSeq=Inv.PropertyIDSeq
  join Orders.dbo.[Order] O  with (nolock) on O.orderIDSeq=InvI.orderIDSeq

    and  C.IDSeq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null)
                             then @IPVC_CompanyID
                           else C.IDSeq
                      end)
    and C.Name like '%' + @IPVC_CustomerName + '%'
    and Pr.Name like '%' + @IPVC_PropertyName + '%'
    and  Fa.Code = (case when (@IPC_ProductFamilyCode <> '' and @IPC_ProductFamilyCode is not null)
                             then @IPC_ProductFamilyCode
                           else Fa.Code
                      end)
    and ((@IPVC_AccountManager is null) or EXISTS(select 1 
												from  Quotes.dbo.QuoteSaleAgent QSA with (nolock)
												where QSA.QuoteIDSeq=O.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPVC_AccountManager))
 and Inv.InvoiceDate between @LD_MinDate and @LD_MaxDate 
 GROUP BY Pr.Code,PF.Name,P.Name,Fa.Code,Fa.Name,Cat.Name,P.Name
-------------------------------------------------------------------------
--                          *****YEAR Data*****
----------------------------------------------------------------------------

set @LD_MinDate = (select DATEADD(yy, DATEDIFF(yy,0,convert(varchar(12),@IPDT_StartDate,101)), 0))
set @LD_MaxDate =convert(varchar(12),@IPDT_StartDate,101)

INSERT INTO @LT_Y_TempBillingReview  
(
  ProductCode,PlatformName,FamilyCode,FamilyName,CategoryName,ProductName,  
  Yr_Gross,Yr_CreditAmount,Yr_Actual,Yr_Budget,Yr_Variance,Yr_VariancePercent 
)    
select distinct Pr.Code as ProductCode,
  PF.Name as platformName,
  Fa.Code as FamilyCode,
  Fa.Name as FamilyName,
  Cat.Name as CategoryName,
  P.Name as ProductName,
  convert(numeric(30,2),SUM(Inv.ILFChargeAmount + Inv.AccessChargeAmount + Inv.TransactionChargeAmount)) as Yr_Gross,
  SUM(Inv.CreditAmount) as Yr_CreditAmount,
  convert(numeric(30,2),SUM((Inv.ILFChargeAmount + Inv.AccessChargeAmount + Inv.TransactionChargeAmount)-(Inv.CreditAmount)))as Yr_Actual,
  '' as Yr_Budget,
  '' as Yr_Variance,
  '' as Yr_VariancePercent
FROM invoices.dbo.invoice Inv with (nolock)
  JOIN invoices.dbo.invoiceItem InvI with (nolock) on Inv.InvoiceIDSeq=InvI.InvoiceIDSeq
  join Products.dbo.Product Pr with (nolock) on Pr.Code=InvI.ProductCode and Pr.PriceVersion=InvI.PriceVersion and Pr.DisplayName like '%' + @IPVC_ProductName + '%'
  join Products.dbo.[Platform] PF with (nolock) on PF.Code=Pr.PlatformCode
  JOIN products.dbo.Family Fa with (nolock) on  Pr.FamilyCode=Fa.Code
  JOIN products.dbo.category Cat with (nolock) on  Pr.CategoryCode=Cat.Code
  join Customers.dbo.Company C with (nolock) on C.IDSeq = Inv.CompanyIDSeq
  join Customers.dbo.Property P with (nolock) on P.IDSeq=Inv.PropertyIDSeq
  join Orders.dbo.[Order] O  with (nolock) on O.orderIDSeq=InvI.orderIDSeq
    and  C.IDSeq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null)
                             then @IPVC_CompanyID
                           else C.IDSeq
                      end)
    and C.Name like '%' + @IPVC_CustomerName + '%'
    and Pr.Name like '%' + @IPVC_PropertyName + '%'
    and  Fa.Code = (case when (@IPC_ProductFamilyCode <> '' and @IPC_ProductFamilyCode is not null)
                             then @IPC_ProductFamilyCode
                           else Fa.Code
                      end)
    and ((@IPVC_AccountManager is null) or EXISTS(select 1 
												from  Quotes.dbo.QuoteSaleAgent QSA with (nolock)
												where QSA.QuoteIDSeq=O.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPVC_AccountManager))
 and Inv.InvoiceDate between @LD_MinDate and @LD_MaxDate 
 GROUP BY Pr.Code,PF.Name,P.Name,Fa.Code,Fa.Name,Cat.Name,P.Name
--------------------------------------------------------------------------
--	Inserting Final Data into ''@LT_Complete_TempBillingReview' variable 
--	from the table variables @LT_M_TempBillingReview, @LT_Q_TempBillingReview and @LT_Y_TempBillingReview
--------------------------------------------------------------------------
Insert into @LT_Complete_TempBillingReview
select Y.ProductCode,Y.PlatformName,Y.FamilyCode,Y.FamilyName,Y.CategoryName,Y.ProductName,	
       Mon_Gross,Mon_CreditAmount,Mon_Actual,Mon_Budget,Mon_Variance,Mon_VariancePercent,
       Qr_Gross,Qr_CreditAmount,Qr_Actual,Qr_Budget,Qr_Variance,Qr_VariancePercent,
       Yr_Gross,Yr_CreditAmount,Yr_Actual,Yr_Budget,Yr_Variance,Yr_VariancePercent
from @LT_M_TempBillingReview M
 join @LT_Q_TempBillingReview Q on M.ProductCode=Q.ProductCode and M.FamilyCode=Q.FamilyCode and M.FamilyName=Q.FamilyName and M.CategoryName=Q.CategoryName and M.ProductName=Q.ProductName
 join @LT_Y_TempBillingReview Y on Q.ProductCode=Y.ProductCode and Q.FamilyCode=Y.FamilyCode and Q.FamilyName=Y.FamilyName and Q.CategoryName=Y.CategoryName and Q.ProductName=Y.ProductName
--------------------------------------------------------------------------
---Final Select for the Report
--------------------------------------------------------------------------  
select ProductCode,PlatformName,FamilyCode,FamilyName,CategoryName,ProductName,	
       Mon_Gross,Mon_CreditAmount,Mon_Actual,Mon_Budget,Mon_Variance,Mon_VariancePercent,
       Qr_Gross,Qr_CreditAmount,Qr_Actual,Qr_Budget,Qr_Variance,Qr_VariancePercent,
       Yr_Gross,Yr_CreditAmount,Yr_Actual,Yr_Budget,Yr_Variance,Yr_VariancePercent
from @LT_Complete_TempBillingReview
END
GO
