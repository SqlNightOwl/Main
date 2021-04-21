SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_LastBatchImportSelect]
-- Description     : Return information last batch imported.
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Bhavesh Shah
--
-- exec [uspORDERS_LastBatchImportSelect]
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_LastBatchImportSelect] 
AS
BEGIN 
  select TOP 1
    ti.IDSeq,
    prod.[DisplayName], 
    [Status], 
    ImportCount, 
	TransactionCount, 
    isnull([FirstName] + ' ' + [LastName], 'Admin') as [DisplayName]
  from 
    TransactionImport ti with (nolock)
      inner join Products..Product prod with (nolock)
        on prod.Code = ti.ProductCode and   prod.disabledFlag = 0
      left  outer join [Security]..[User] u with (nolock)
        on ti.CreatedByIDSeq = u.IDSeq
  Order by 
    ti.IDSeq DESC
END
GO
