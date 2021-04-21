SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_GetFamilyCount]
-- Description     : This procedure gets count of Family
-- --                    	
-- OUTPUT          : no of rows
-- Code Example    :   Exec PRODUCTS.dbo.[uspPRODUCTS_GetFamily]
--
-- Revision History:
-- Author          : Naval Kishore
-- 04/23/2007      : Stored Procedure Created.
-- =============================================
CREATE PROCEDURE [products].[uspPRODUCTS_GetFamilyCount]
					
AS
BEGIN
/**********************************************************************************************/
   SELECT count (*) FROM PRODUCTS.[dbo].[Family] with (nolock)
	
END

GO
