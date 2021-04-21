SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetOrderDetailsbyProduct
-- Description     : This procedure gets Order Details pertaining to passed AccountID
-- Input Parameters: 1. @IPI_Accoun tID   as varchar(20)
--                   2. @IPI_PageNumber  as integer
--                   3. @IPI_RowsPerPage as integer
-- 
-- OUTPUT          : RecordSet of OrderID,Status,CustomerID,CustomerName,AccountID,
--                                AccountName,OrderDate,OrderPeriod,LastInvoice,RowNumber
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetOrderDetails @IPI_AccountID  =1,
--                                                                   @IPI_PageNumber =3,
--                                                                   @IPI_RowsPerPage=20    
-- 
-- 
-- Revision History: Eric Font: @IPI_AccountID parameter must be a VARCHAR instead of an INT
-- Author          : SRA Systems 
-- 11/22/2006      : Stored Procedure Created.
-- 11/28/2006      : Changed by RealPage. Changed as per RPI standards.
-- 11/28/2006      : Changed by STA. The Account ID and the Account Name fields are removed
--                   as they need not be displayed in the account details sub tab page.
-- 12/07/2006      : Changed by STA. To implement the paging functionality of the top 20 records.
--	01/12/2007	   : Naval Kishore Modified SP for new business logic.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetOrderDetailsbyProduct] (
                                                       @IPI_AccountID     varchar(50),                                                        
                                                       @IPVC_statuscode   varchar(50) = '',
                                                       @IPI_PageNumber    int, 
                                                       @IPI_RowsPerPage   int
                                                      )
AS
BEGIN 
  set nocount on;
  set ansi_warnings off;
  ----------------------------------------------------------------------------------
  create table #TEMP_OR_PRODUCTS
                               (
				CompanyIDSeq	varchar(11),
				OrderIDSeq	varchar(50), 
                                OrderItemIDSeq  bigint,  
				ProductCode	char(30),
				ProductName	varchar(255),                                
				Status		varchar(70),   
				OrderDate	varchar(50),
				OrderPeriod     varchar(70),
				ChargeType	varchar(20),
                                BillTo          char(1),
				CreatedBy	varchar(70),
				BillThruDate	varchar(50),
                                LastInvoice     varchar(50),
                                StatusSortSeq   bigint
                              )
  -------------------------------------------------------------------------------------------
  INSERT INTO #TEMP_OR_PRODUCTS  (CompanyIDSeq,OrderIDSeq,OrderItemIDSeq,ProductCode,ProductName,
                                  Status,OrderDate,OrderPeriod,
 				  ChargeType,CreatedBy,BillThruDate,LastInvoice,StatusSortSeq)
  SELECT DISTINCT O.CompanyIDSeq, 
	   	  O.OrderIDSeq    as OrderIDSeq,
                  OI.IDSeq        as OrderItemIDSeq, 
		  OI.ProductCode,
		  Pr.DisplayName  as ProductName,	
		  OST.Name        as [Status],
		  coalesce(convert(varchar(50),OI.Startdate,101),'-')   AS OrderDate,
		  coalesce(convert(varchar(50),OI.StartDate,101) + '-'+ convert(varchar(50),OI.EndDate,101),'-') as OrderPeriod,
		OI.ChargeTypeCode					 AS ChargeTypeCode,	
                dbo.fnGetUserName(O.CreatedBy),
		coalesce(Convert(varchar(50),OI.LastBillingPeriodFromdate,101)+'-'+Convert(varchar(50),OI.LastBillingPeriodTodate,101),'-')      AS BillThruDate,
                '-'                                                      as LastInvoice,
                (case when OI.StatusCode = 'FULF'  then 1
                      when OI.StatusCode = 'PEND'  then 2
                      when OI.StatusCode = 'TRNSP' then 3
                      when OI.StatusCode = 'EXPD'  then 4
                      when OI.StatusCode = 'CNCL'  then 5
                    else 9999999999
                 end)                                                   as StatusSortSeq
         
  FROM [Orders].dbo.[Order]      O with (nolock)
  Inner join
       [Orders].dbo.[OrderItem]  OI with (nolock)
  on   O.OrderIDSeq = OI.OrderIDSeq
  and  O.accountidseq=@IPI_AccountID
  Inner join
       Products.dbo.Product       Pr with (nolock)
  on   Pr.Code=OI.ProductCode
  and  Pr.PriceVersion = OI.PriceVersion
  Inner Join
       Orders.dbo.OrderStatusType OST with (nolock)
  on   OST.Code=OI.StatusCode
  and  (OST.Code = @IPVC_statuscode or @IPVC_statuscode = '')
  order by StatusSortSeq asc
 ----------------------------------------------------------------------------------
 Update D
 set    D.LastInvoice = S.InvoiceDate
 from   #TEMP_OR_PRODUCTS D with (nolock)
 inner join
        (select II.OrderIDSeq,II.OrderitemIDSeq,
                convert(varchar(15),max(I.InvoiceDate),101) as InvoiceDate
         from   Invoices.dbo.Invoice I with (nolock)
         inner join
                Invoices.dbo.Invoiceitem II with (nolock)
         on     I.InvoiceIDSeq = II.InvoiceIDSeq
         and    I.AccountIDSeq = @IPI_AccountID
         group by II.OrderIDSeq,II.OrderitemIDSeq
        ) S
 on     D.Orderidseq     = S.OrderIDSeq
 and    D.OrderitemIDSeq = S.OrderitemIDSeq; 
 
 ----------------------------------------------------------------------------------
 --Final Select 
  SELECT  * FROM
  (
  SELECT  * from
    (
    SELECT  LT_OrderList.*, row_number() over(order by ProductName    asc,
                                                       ChargeTypeCode desc,   
                                                       OrderDate      desc
                                              ) as RowNumber from
      (
        SELECT        O.OrderIDSeq                                              as ID,
                      O.[ProductName]                                           as ProductName,                      
                      O.[ProductCode]                                           as ProductCode,
                      O.Status                                                  as Status,
 		      O.ChargeType					        as ChargeTypeCode,
                      O.OrderDate                                               as OrderDate,
		      O.OrderPeriod                                             as OrderPeriod,                           
                      O.LastInvoice                                             as LastInvoice,
                      '-'                                                       as NextInvoice,
                      O.CreatedBy                                               as CreatedBy,
		      O.BillThruDate				                as BillThruDate,
                      O.StatusSortSeq                                           as StatusSortSeq            
        FROM   #TEMP_OR_PRODUCTS O with (nolock)
        
      ) LT_OrderList

    ) LT_ListOfOrders    
    WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage 
    and RowNumber <=  (@IPI_PageNumber) * @IPI_RowsPerPage
  )
  AS RecordTable
  ----------------------------------------------------------------------------
SELECT COUNT(*) as linecount 
FROM #TEMP_OR_PRODUCTS with (nolock)
-----------------------------------------
drop table #TEMP_OR_PRODUCTS
-----------------------------------------
END
GO
