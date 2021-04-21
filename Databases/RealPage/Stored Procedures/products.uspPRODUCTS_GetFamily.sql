SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_GetFamily]
-- Description     : This procedure gets Product Details pertaining to passed 
--                        ProductName, FamilyCode, ViewProducts, Category and Platform
-- Input Parameters:   @IPI_PageNumber       as  int, 
--                     @IPI_RowsPerPage      as  int 
--                    	
-- OUTPUT          : RecordSet of the ID, Name, Category, Family, Platform  of Products from Products..Product,
--                   Products..Family, Products..Category and Customers..Platform 
-- Code Example    :   Exec PRODUCTS.dbo.[uspPRODUCTS_GetFamily]
--					   @IPI_PageNumber        =   1,
--                     @IPI_RowsPerPage       =   10 
--                     
	
-- Revision History:
-- Author          : Naval Kishore
-- 04/23/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetFamily]
					(
						@IPI_PageNumber       as  int, 
						@IPI_RowsPerPage      as  int					    
					)
AS
BEGIN
/**********************************************************************************************/
SELECT * FROM 
  (
  select Code, [Name] ,[Description],
        row_number() over(order by [Name])   as RowNumber 
  from PRODUCTS.dbo.[Family] with (nolock)


	
)LVT_GetFamily
 /*******************************************************************************/
WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
/**********************************************************************************************/
end

GO
