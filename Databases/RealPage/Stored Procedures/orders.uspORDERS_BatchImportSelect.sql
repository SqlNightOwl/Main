SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_BatchImportSelect]
-- Description     : Return information about the batch import
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
-- exec [uspORDERS_BatchImportSelect] 5
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_BatchImportSelect] (@IPI_IDSeq bigint)					
AS
BEGIN 
  select prod.[DisplayName], [Status], ImportCount,TransactionCount, isnull([FirstName] + ' ' + [LastName], 'Admin') as [DisplayName]
  from Orders.dbo.TransactionImport ti with (nolock)
  inner join Products.dbo.Product prod with (nolock)
  on    prod.Code = ti.ProductCode
  and   prod.disabledFlag = 0
  left  outer join [Security].dbo.[User] u with (nolock)
  on    ti.CreatedByIDSeq = u.IDSeq
  where ti.IDSeq = @IPI_IDSeq
END
GO
