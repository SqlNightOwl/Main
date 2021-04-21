SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_PlatformList
-- Description     : This procedure gets the list of Family
--
-- OUTPUT          : RecordSet of Code, Name from PRODUCTS..[Family]
--
-- Code Example    : Exec DOCUMENTS.dbo.[uspPRODUCTS_PlatformList]
--
-- Revision History:
-- Author          : RAJESH NALLAPATI 
-- 04/23/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_PlatformList] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/

  select   PF.Code,PF.[Name] 
  from     PRODUCTS.dbo.[PlatForm] PF with (nolock)
  where    Exists (Select top 1 1 from Products.dbo.Product P with (nolock)
                   where  P.PlatFormcode = PF.Code
                   and    P.disabledflag = 0
                  )
  order by [SortSeq] asc

END -- Main END starts at Col 01
GO
