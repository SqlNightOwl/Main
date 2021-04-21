SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Customers
-- Procedure Name  : [uspCustomers_GetCommentDetails]
-- Description     : This procedure gets the Details of CustomerComment Table
--
-- OUTPUT          : RecordSet of Code, Name from Customers.DBO.[CustomerComment]
--
-- Code Example    : Exec Customers.dbo.[uspCustomers_GetCommentDetails] @IPBI_CommentIDSeq = 12
--
-- Revision History:
-- Author          : Anand Chakravarthy
-- 05/24/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCustomers_GetCommentDetails](@IPBI_CommentIDSeq bigint -->Primary Key Unique identifier for CustomerComment Record
                                                       ) 
                           

AS
BEGIN -- Main BEGIN
  set nocount on;    
  ---------------------------------------
  SELECT  CC.CommentTypeCode    as [CommentTypeCode],
          CT.Name               as [CommentTypeName],
          CC.AccountTypeCode    as [AccountTypeCode],
          CC.Name               as [Name],
          CC.Description        as [Description],
          CC.CompanyIDSeq       as [CompanyIDSeq],
          CC.PropertyIDSeq      as [PropertyIDSeq], 
          CC.AccountIDSeq       as [AccountIDSeq]      
  FROM   Customers.dbo.CustomerComment CC with (nolock) 
  inner Join
         Customers.dbo.CommentType CT with (nolock)
  on     CC.CommentTypeCode = CT.Code
  Where  IDSeq = @IPBI_CommentIDSeq

END -- Main END
GO
