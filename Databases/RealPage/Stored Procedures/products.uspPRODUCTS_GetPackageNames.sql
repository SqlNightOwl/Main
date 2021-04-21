SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_GetPackageNames]
-- Description     : This procedure returns the Package names.
-- Input Parameters: 	
-- 
-- OUTPUT          : RecordSet of ID,PackageName.
-- Code Example    : Exec PRODUCS.DBO.uspPRODUCTS_GetPackageNames
-- 
-- Revision History:
-- Author          : KIRAN KUSUMBA 
-- 05/30/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetPackageNames]	
AS
BEGIN
  ----------------------------------------------------
  ------- MAIN SELECT STATEMENT ----------------------
  ----------------------------------------------------
  SELECT IDSeq, [Name] FROM PRODUCTS.dbo.CustomBundle with (nolock)
  ----------------------------------------------------
END

GO
