SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERSREPORTS_GetPlatform]
-- Description     : This procedure gets the list of ProductTypes
--
-- OUTPUT          : RecordSet of Code, Name from PRODUCTS..[Platform]
--
-- Code Example    : Exec Products.dbo.[uspCUSTOMERSREPORTS_GetPlatform]
--
-- Revision History:
-- Author          : Naval Kishore
-- 08/13/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCUSTOMERSREPORTS_GetPlatform] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/

 SELECT Code,[Name] FROM Products.dbo.[Platform] with (nolock)

END -- Main END starts at Col 01
GO
