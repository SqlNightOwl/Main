SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspINVOICES_DeletePullList]
-- Description     : This procedure deletes Pull List for @IPBI_PullListIDSeq
-- Input Parameters: 
--                   
-- OUTPUT          : None
--
--                   
-- Code Example    : Exec [uspINVOICES_DeletePullList]
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 07/29/2009      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_DeletePullList] (@IPBI_PullListIDSeq  bigint)
AS
BEGIN     
  Delete from Invoices.dbo.PullListAccounts where PullListIDSeq =@IPBI_PullListIDSeq
  Delete from Invoices.dbo.PullList where IDSeq =@IPBI_PullListIDSeq
END

GO
