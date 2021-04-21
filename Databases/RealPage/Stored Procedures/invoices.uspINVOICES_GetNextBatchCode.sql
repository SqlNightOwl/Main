SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------    
-- Database  Name  : Invoices    
-- Procedure Name  : [uspINVOICES_GetNextBatchCode]    
-- Description     : Returns the next batch code to process
--    
-- Created         : DCANNON
-- 5/1/2006        : 
-- 04/27/2011	   : Surya Kondapalli -	Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
------------------------------------------------------------------------------------------------------    
CREATE PROCEDURE [invoices].[uspINVOICES_GetNextBatchCode] @BatchType varchar(50),@CountryCode varchar(3)
AS    
BEGIN     
  
  select top 1 EpicorBatchCode 
  from Invoices.dbo.BatchProcess with (nolock)
  where Status = 'EPICOR PUSH PENDING'
  and BatchType = @BatchType
  and EpicorCompanyName = case when @CountryCode = 'USA' 
							   then 'USD'
							   when @CountryCode = 'CAN' 
							   then 'CAD' end
    
END    
  
  
  
  
  
  
  
  







GO
