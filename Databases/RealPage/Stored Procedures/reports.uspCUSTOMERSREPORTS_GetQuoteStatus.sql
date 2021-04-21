SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERSREPORTS_GetQuoteStatus]
-- Description     : This procedure gets the list of ProductTypes
--
-- OUTPUT          : RecordSet of Code, Name from PRODUCTS..[Platform]
--
-- Code Example    : Exec Products.dbo.[uspCUSTOMERSREPORTS_GetQuoteStatus]
--
-- Revision History:
-- Author          : Naval Kishore
-- 08/13/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCUSTOMERSREPORTS_GetQuoteStatus] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/

 SELECT Code,[Name] FROM Quotes.dbo.Quotestatus with (nolock)

END -- Main END starts at Col 01
GO
