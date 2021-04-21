SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetSelectedPriceCapDetails]
-- Description     : This procedure gets Price Cap Details pertaining to passed 
--                        PriceCapID
-- Input Parameters:   @IPC_PriceCapIDSeq varchar(11) 
--                   
--                    	
-- OUTPUT          : Dataset of the PriceCapBasisCode, PriceCapPercent, PriceCapTerm, PriceCapStartDate,
--					 from Customers.dbo.PriceCap,
--                   
-- Code Example    :   exec [dbo].[uspCUSTOMERS_GetSelectedPriceCapDetails] 51
--                     
	
-- Revision History:
-- Author          : Naval Kishore
-- 04/23/2007      : Stored Procedure Created.
-- 10/28/2010      : Naval Kishore Modified to get PriceCapEndDate. Defect #8350 
-----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetSelectedPriceCapDetails]
						 (
                                                    @IPC_PriceCapIDSeq varchar(50)
                                                  )
AS
BEGIN

if exists(select IDSeq from Customers.dbo.PriceCap where IDSeq =  @IPC_PriceCapIDSeq)

BEGIN
--------------------------------------------------------------------------------------------------
--PriceCap 
--------------------------------------------------------------------------------------------------
	SELECT 
			PriceCapBasisCode,
			convert(numeric(10,2),PriceCapPercent)as PriceCapPercent,
			PriceCapTerm,
			Convert(varchar(10), PriceCapStartDate, 101)as PriceCapStartDate,
			Convert(varchar(10), PriceCapEndDate, 101)as PriceCapEndDate,
			ActiveFlag
	FROM Customers.dbo.PriceCap
	WHERE IDSeq = @IPC_PriceCapIDSeq

--------------------------------------------------------------------------------------------------
--ProductList
--------------------------------------------------------------------------------------------------
	SELECT 
           prod.ProductCode AS ID,
           prod.ProductName AS [Name]
    FROM  Customers.dbo.PriceCapProducts prod  with (nolock) 
    WHERE 
          PriceCapIDSeq = @IPC_PriceCapIDSeq

--------------------------------------------------------------------------------------------------
--PropertyList
--------------------------------------------------------------------------------------------------	
	SELECT 
		prod.PropertyIDSeq AS ID, 

		prop.[Name] AS [Name] 

		FROM Customers.dbo.PriceCapPropertiesHistory prod 

		inner join Customers.dbo.[Property] prop 

		ON prop.IDSeq = prod.PropertyIDSeq 

	WHERE 
		PriceCapIDSeq =  @IPC_PriceCapIDSeq
 

UNION 

	SELECT 

		'NULL' AS ID, 

		Comp.[Name] AS [Name] 

	FROM Customers.dbo.PriceCapPropertiesHistory prod 

	inner join Customers.dbo.company comp 

	ON comp.IDSeq = prod.companyidseq where

	PriceCapIDSeq=@IPC_PriceCapIDSeq and prod.PropertyIDSeq is null
--------------------------------------------------------------------------------------------------
--PriceCap Notes
--------------------------------------------------------------------------------------------------	
	SELECT 
           [Description] AS [Description]
    FROM Customers.dbo.PriceCapNote 
    WHERE 
          PriceCapIDSeq = @IPC_PriceCapIDSeq
--------------------------------------------------------------------------------------------------

END

ELSE
BEGIN
--------------------------------------------------------------------------------------------------
--PriceCap 
--------------------------------------------------------------------------------------------------
	SELECT 
			PriceCapBasisCode,
			convert(numeric(10,2),PriceCapPercent)as PriceCapPercent,
			PriceCapTerm,
			Convert(varchar(10), PriceCapStartDate, 101)as PriceCapStartDate,
			Convert(varchar(10), PriceCapEndDate, 101)as PriceCapEndDate,
			ActiveFlag
	FROM Customers.dbo.PriceCapHistory
	WHERE PriceCapIDSeq = @IPC_PriceCapIDSeq

--------------------------------------------------------------------------------------------------
--ProductList
--------------------------------------------------------------------------------------------------
	SELECT 
           prod.ProductCode AS ID,
           prod.ProductName AS [Name]
    FROM  Customers.dbo.PriceCapProductsHistory prod  with (nolock) 
    WHERE 
          PriceCapIDSeq = @IPC_PriceCapIDSeq

--------------------------------------------------------------------------------------------------
--PropertyList
--------------------------------------------------------------------------------------------------	
	SELECT 
		prod.PropertyIDSeq AS ID, 

		prop.[Name] AS [Name] 

		FROM Customers.dbo.PriceCapPropertiesHistory prod 

		inner join Customers.dbo.[Property] prop 

		ON prop.IDSeq = prod.PropertyIDSeq 

	WHERE 
		PriceCapIDSeq =  @IPC_PriceCapIDSeq
 

UNION 

	SELECT 

		'NULL' AS ID, 

		Comp.[Name] AS [Name] 

	FROM Customers.dbo.PriceCapPropertiesHistory prod 

	inner join Customers.dbo.company comp 

	ON comp.IDSeq = prod.companyidseq where

	PriceCapIDSeq=@IPC_PriceCapIDSeq and prod.PropertyIDSeq is null

--------------------------------------------------------------------------------------------------
--PriceCap Notes
--------------------------------------------------------------------------------------------------	
	SELECT 
           [Description] AS [Description]
    FROM Customers.dbo.PriceCapNote 
    WHERE 
          PriceCapIDSeq = @IPC_PriceCapIDSeq
--------------------------------------------------------------------------------------------------

END
END
GO
