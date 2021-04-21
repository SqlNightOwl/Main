SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetCategory]
-- Description     : Lists all Category Code with Name for Population of Drop down for Reason Category
--                    in Search Maintenance screen   for Reason Category Matrix.

-- Parameters      : None
-- Syntax          : EXEC ORDERS.dbo.uspORDERS_GetCategory
------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_GetCategory]
as
BEGIN
 set nocount on;
 --------------------
 select C.Code           as CategoryCode,  --> UI to hold it internally corresponding to drop down CategoryName
        C.CategoryName   as CategoryName   --> UI to populate CategoryName in the drop down.
 from   ORDERS.dbo.Category C with (nolock)
 order by
        C.CategoryName ASC
 --------------------
END
GO
