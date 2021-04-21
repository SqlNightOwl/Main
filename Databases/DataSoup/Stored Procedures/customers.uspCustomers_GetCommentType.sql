SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Customers
-- Procedure Name  : [uspCustomers_GetCommentType]
-- Description     : This procedure gets the list of Comment Types
--
-- OUTPUT          : RecordSet of Code, Name from Customers.DBO.[CommentType]
--
-- Code Example    : Exec Customers.dbo.[uspCustomers_GetCommentType] @IPI_ActiveOnly = 1
/*
-- Scenario 1      : For Add new Customer Comment, to populate the Drop down in Modal all
                      Exec Customers.dbo.[uspCustomers_GetCommentType] @IPI_ActiveOnly = 1
                     to get only active Comment Types
   
   Scenario 2      : For Edit of a Customer Comment, 
                      Call Exec Customers.dbo.[uspCustomers_GetCommentType] @IPI_ActiveOnly = 0
                       and default selection to CommentTypeName returned by 
                        EXEC CUSTOMERS.dbo.uspCustomers_GetCommentDetails @IPBI_CommentIDSeq

  Scenario 3       : Search section Comment type drop down.
                       Call Exec Customers.dbo.[uspCustomers_GetCommentType] @IPI_ActiveOnly = 0
                        This will return all comment types whether it is disabled or not, to search 
                        even on previously customer comments created with disabled CommentTypeCode
*/

-- Revision History:
-- Author          : Anand Chakravarthy
-- 05/24/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCustomers_GetCommentType] (@IPI_ActiveOnly  int = 1)
AS
BEGIN -- Main BEGIN starts at Col 01
 set nocount on;
 --Get ACTIVE CommentType to populate drop down
 SELECT Code,Name 
 FROM   Customers.dbo.CommentType with (nolock) 
 where  ((@IPI_ActiveOnly = 1 and DisabledFlag = 0)
           Or
         (@IPI_ActiveOnly = 0)
        )
END -- Main END starts at Col 01
GO
