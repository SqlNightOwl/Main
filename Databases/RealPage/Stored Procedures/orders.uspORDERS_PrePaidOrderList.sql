SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_PrePaidOrderList
-- Description     : This procedure gets Order Details pertaining to passed Quote ID
--
-- Input Parameters: 
--                   @IPVC_QuoteID        as    varchar
-- 
-- OUTPUT          : RecordSet of [OrderID], [Name], [EpicorID], [InstantInvoiceID], [NetCharge], [ShippingHandlingAmount], [Tax], [TotalAmount]
--
-- EXEC [uspORDERS_PrePaidOrderList] @IPVC_QuoteID = 'Q1104000949'
--
-- Revision History:
-- Author          : Satya B 
-- 08/10/2011      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [orders].[uspORDERS_PrePaidOrderList] (@IPVC_QuoteID VARCHAR(50))
AS
BEGIN 

	SELECT IDENTITY(INT, 1,1) AS IDSeq, o.QuoteIDSeq, o.CompanyIDSeq, o.PropertyIDSeq, i.CompanyName, i.PropertyName,
        o.OrderIDSeq AS [OrderID],  a.EpicorCustomerCode AS [EpicorID], '' AS [InstantInvoiceID],
		SUM(ii.NetChargeAmount) AS [NetCharge], SUM(ii.ShippingAndHandlingAmount) AS [ShippingHandlingAmount],
		SUM(ii.TaxAmount) AS Tax, SUM(ii.NetChargeAmount) + SUM(ii.ShippingAndHandlingAmount) + SUM(ii.TaxAmount) AS [TotalAmount]
	INTO #PrePaidOrderList FROM Orders.dbo.[Order] o WITH (NOLOCK)
	JOIN Orders.dbo.OrderItem oi WITH (NOLOCK) ON o.OrderIDSeq = oi.OrderIDSeq
	JOIN Invoices.dbo.InvoiceItem ii WITH (NOLOCK) ON oi.OrderIDSeq = ii.OrderIDSeq AND oi.IDSeq = ii.OrderItemIDSeq
	JOIN Invoices.dbo.Invoice i WITH (NOLOCK) ON ii.InvoiceIDSeq = i.InvoiceIDSeq AND o.AccountIDSeq = i.AccountIDSeq
	JOIN Customers.dbo.Account a WITH (NOLOCK) ON o.AccountIDSeq = a.IDSeq
	WHERE o.QuoteIDSeq = @IPVC_QuoteID
	GROUP BY o.QuoteIDSeq, o.OrderIDSeq, o.CompanyIDSeq, o.PropertyIDSeq, i.CompanyName, i.PropertyName, a.EpicorCustomerCode

	SELECT (SELECT COUNT(*) FROM #PrePaidOrderList) AS TotalRecords, 
		[OrderID], PropertyName AS [Name], [EpicorID], [InstantInvoiceID], [NetCharge], [ShippingHandlingAmount], [Tax], [TotalAmount]
	FROM #PrePaidOrderList
	ORDER BY [Name]

	SELECT SUM([NetCharge]) AS [NetCharge], SUM([ShippingHandlingAmount]) AS [ShippingHandlingAmount], SUM([Tax]) AS [Tax], SUM([TotalAmount]) AS [TotalAmount]
	FROM #PrePaidOrderList

    SELECT CompanyIDSeq, PropertyIDSeq, [InstantInvoiceID], [TotalAmount], [EpicorID], CompanyName, PropertyName
    FROM #PrePaidOrderList
	ORDER BY PropertyName

	DROP TABLE #PrePaidOrderList

END  
GO
