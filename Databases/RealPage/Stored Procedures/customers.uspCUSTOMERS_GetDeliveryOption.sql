SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetDeliveryOption]
-- Description     : This procedure Selects all Delivery Option from Seed Table Delivery Option
-- Input Parameter : 
--                  
--
-- Code Example    : [CUSTOMERS].dbo.[uspCUSTOMERS_GetDeliveryOption]
--                   
--
-- Revision History:
-- Author          : SRS
-- 12/18/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetDeliveryOption]    
AS
BEGIN 
  set nocount on;
  select Code,Name
  from   CUSTOMERS.dbo.DeliveryOption with (nolock)
  order by IDSeq asc
END
GO
