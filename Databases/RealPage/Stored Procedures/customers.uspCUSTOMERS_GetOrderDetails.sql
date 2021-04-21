SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetOrderDetails
-- Description     : This procedure gets Order Details pertaining to passed AccountID
-- Input Parameters: 1. @IPI_AccountID   as varchar(20)
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
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetOrderDetails] (
                                                       @IPI_AccountID     varchar(20), 
                                                       @IPI_PageNumber    int, 
                                                       @IPI_RowsPerPage   int
                                                      )
AS
BEGIN 
SELECT TOP (@IPI_RowsPerPage) * FROM
  (
  SELECT TOP (@IPI_PageNumber * @IPI_RowsPerPage) * from
    (
    SELECT  *, row_number() over(order by OrderDate desc) as RowNumber from
      (
        SELECT TOP 20 

                      o.OrderIdSeq                                              as ID,

                      OST.Name                                                  as Status,

--                      isnull(convert(numeric(10,2), (select sum(NetChargeAmount)  
--                        from Orders..OrderItem with (nolock)  where  OrderIDseq = O.Idseq and ChargeTypeCode = 'ILF')),0)       as ILF,

					ISNULL( Quotes.DBO.fn_FormatCurrency((select sum(NetChargeAmount)  
                        from Orders..OrderItem with (nolock)  where  OrderIDseq = O.OrderIdSeq and ChargeTypeCode = 'ILF'),2,2),'0') as ILF,

--					  isnull( convert(numeric(10,2),(select sum(NetChargeAmount)
--                        from Orders..OrderItem with (nolock)  where  OrderIDseq = O.Idseq and ChargeTypeCode = 'ACS')),0)   as Access,

					ISNULL(Quotes.DBO.fn_FormatCurrency((select sum(NetChargeAmount)
								from Orders..OrderItem with (nolock)  where  OrderIDseq = O.OrderIdSeq and ChargeTypeCode = 'ACS'),2,2),'0') as Access,

					
                      Convert(varchar(10),O.CreatedDate,101)                    as OrderDate,

                      (select convert(varchar(50),min(ILFStartDate),101)
                        + ' ' + '-' + ' ' +
                        convert(varchar(50),max(ILFEndDate),101)  
                        from Orders..OrderItem  where  OrderIDseq = O.OrderIdSeq)    as OrderPeriod,

                      (SELECT top 1 
                      isnull((convert(varchar(15),I.InvoiceDate,101)),'N/A')  
                      FROM Invoices.dbo.invoice I (nolock)
                      left outer join Invoices.dbo.InvoiceGroup IG
                      on IG.InvoiceIDSeq = I.InvoiceIDSeq
                      left outer join Invoices.dbo.InvoiceItem II
                      on II.InvoiceGroupIDSeq = IG.IDSeq     
                      WHERE II.OrderIDSeq= O.OrderIdSeq)                             as LastInvoice,

                      'N/A'                                                     as NextInvoice,
					  O.CreatedBy												as CreatedBy
                      --dbo.fnGetUserName(O.CreatedBy)                            as CreatedBy                     
            
        FROM   Orders.dbO.[Order] O (nolock)

        inner JOIN Orders.dbO.OrderStatusType OST (nolock) 

            ON            O.StatusCode   = OST.Code

      
        inner JOIN Customers.dbO.Company C (nolock) 

            ON            O.CompanyIDSeq = C.IDSeq  
     
        WHERE  O.AccountIDSeq = @IPI_AccountID

      ) LT_OrderList

    ) LT_ListOfOrders
    
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage 

    and RowNumber <= (@IPI_PageNumber) * @IPI_RowsPerPage
  )

AS RecordTable
  ----------------------------------------------------------------------------
END

GO
