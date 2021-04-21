SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_FamilyList
-- Description     : This procedure gets the list of Family
--
-- OUTPUT          : RecordSet of Code, Name from PRODUCTS..[Family]
--
-- Code Example    : Exec DOCUMENTS.dbo.[uspPRODUCTS_FamilyList]
--
-- Revision History:
-- Author          : RAJESH NALLAPATI 
-- 04/23/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_FamilyList] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/

  SELECT   F.Code,
           F.[Name] 
  FROM     PRODUCTS.dbo.[Family] F with (nolock)
  WHERE  /* Exists (Select top 1 1 from Products.dbo.Product P with (nolock)
                   where  P.Familycode = F.Code
                   and    P.disabledflag = 0
                )
         */
  F.Code not in ('ADM','RPM')
  order by [SortSeq] asc

END -- Main END starts at Col 01
GO
