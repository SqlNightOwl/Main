SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspINVOICES_GetAllPullListNames]
-- Description     : This procedure inserts Account for a Pull List pertaining to passed AccountID
-- Input Parameters: 
--                   
-- OUTPUT          : RecordSet of IDSEq is generated
--
--                   
-- Code Example    : Exec [uspINVOICES_GetAllPullListNames]
-- 
-- 
-- Revision History:
-- Author          : Naval Kishore SIngh
-- 23/09/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetAllPullListNames]
AS
BEGIN     
  select 
	IDSEQ	as PullListIDSeq, 
	title	as Title             
  from    invoices.dbo.PullList with (nolock)  
  Order By Title ASC			
END

GO
