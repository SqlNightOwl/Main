SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_GetSelectedPriceCapDetailsHistory](@IPC_PriceCapIDSeq varchar(11))
AS
BEGIN

--------------------------------------------------------------------------------------------------
	SELECT 
			PriceCapBasisCode,
			convert(numeric(3),PriceCapPercent)as PriceCapPercent,
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

	ON nullif(comp.IDSeq,'') = nullif(prod.companyidseq,'') where

	PriceCapIDSeq=@IPC_PriceCapIDSeq 
--------------------------------------------------------------------------------------------------
--PriceCap Notes
--------------------------------------------------------------------------------------------------	
	SELECT 
           [Description] AS [Description]
    FROM Customers.dbo.PriceCapNoteHistory 
    WHERE 
          PriceCapIDSeq = @IPC_PriceCapIDSeq
--------------------------------------------------------------------------------------------------
END
GO
