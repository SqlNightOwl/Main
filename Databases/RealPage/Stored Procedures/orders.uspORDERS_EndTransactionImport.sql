SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_EndTransactionImport]
-- Description     : Inserts an entry into the batch table to begin the import transaction process
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Revision History: 07/08/2008
-- Author          : Bhavesh Shah
--                 : Added Error message.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [orders].[uspORDERS_EndTransactionImport] 
(
  @IPI_IDSeq bigint, 
  @IPI_ImportCount int,
  @IPVC_ErrorMessage varchar(max) = null
)
AS
BEGIN 
  update TransactionImport
  set Status = 'COMPLETE',
--      ImportCount = @IPI_ImportCount
      ImportCount = ( select count(*) from TransactionImportItem 
                      where TransactionImportIDSeq = @IPI_IDSeq
                      and   TransactionStatusCode in ('NEWO', 'COMP')),
      TransactionCount = ( select count(*) from TransactionImportItem 
                      where TransactionImportIDSeq = @IPI_IDSeq),
      ErrorMessage = nullif(@IPVC_ErrorMessage, '')
where IDSeq = @IPI_IDSeq
END

GO
