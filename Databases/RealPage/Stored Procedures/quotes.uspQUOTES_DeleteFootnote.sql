SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_DeleteFootnote]
-- Description     : This procedure deletes footnotes pertaining to passed 
--                        IDSEQ

-- Input Parameters: @IPI_IDSEQ bigint
-- 
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_DeleteFootnote] 
--                   @IPI_IDSEQ = 17
-- Revision History:
-- Author          : Naval Kishore
-- 04/04/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_DeleteFootnote] (
                                                       @IPI_IDSEQ   varchar(22)
                                                      )
as
begin   
		DELETE FROM QUOTES.DBO.QUOTEITEMNOTE where idseq=@IPI_IDSEQ

END 

GO
