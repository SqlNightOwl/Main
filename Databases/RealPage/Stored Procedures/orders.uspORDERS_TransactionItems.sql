SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_TransactionItems]
-- Description     : Lists all Products with Measurecode = 'TRAN'
------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_TransactionItems]
AS
BEGIN
  select distinct ltrim(rtrim(P.Code)) as Code,
         P.DisplayName                 as DisplayName
  from  Products.dbo.Product     P with (nolock)
  inner join Products.dbo.Charge C with (nolock)
  on    C.Productcode = P.Code
  and   C.PriceVersion= P.PriceVersion
  and   C.DisabledFlag= P.DisabledFlag
  and   P.DisabledFlag = 0
  and   C.DisabledFlag= 0
  and   C.MeasureCode = 'TRAN'
  and   C.Displaytype <> 'OTHER'  
  order by P.DisplayName Asc
END  

GO
