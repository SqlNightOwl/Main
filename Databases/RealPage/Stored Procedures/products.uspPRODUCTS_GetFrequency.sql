SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_GetFrequency]
-- Description     : This procedure gets the list of Frequency
--
-- OUTPUT          : RecordSet of Code, Name from PRODUCTS..[Frequency]
--
-- Code Example    : Exec Products.dbo.[uspPRODUCTS_GetFrequency]
--
-- Revision History:
-- Author          : Naval Kishore
-- 06/29/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetFrequency] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/

  select   Code, [Name] 
  from     PRODUCTS.dbo.[Frequency] with (nolock)
  where    DisplayFlag  = 1 
  order by [Name] asc

END -- Main END starts at Col 01
GO
