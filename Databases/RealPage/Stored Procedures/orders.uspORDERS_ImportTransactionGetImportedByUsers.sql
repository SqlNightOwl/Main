SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportTransactionGetImportedByUsers]
-- Description     : This Proc returns distinct list of Imported by Users for Transaction Import

-- Input Parameters: Note

------------------------------------------------------------------------------------------------------
-- Revision History:
-- 2010-08-11      : LWW #8143-special sequencing for "all" row, (even before Abraham!)
-- 2010-05-24      : SRS #7677
------------------------------------------------------------------------------------------------------
Create Procedure [orders].[uspORDERS_ImportTransactionGetImportedByUsers]
AS
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL ON;
  -------------------------------

	SELECT [ImportedByUserIDSeq],[ImportedByUserName],[ImportedByNTUserName]
	FROM
	(
	  select 0                                             as  ImportedByUserIDSeq,  --UI Hidden value against the drop down show in Batch Header
			 'All Users'                                   as  ImportedByUserName,   --UI Populate Drop down as Imported By 
			 'All Users'                                   as  ImportedByNTUserName  --UI Populate by the side of Imported By to show NT User Name as a label based on user selection 
	  ----------
	  union
	  ----------
	  select U.IDSeq                                       as  ImportedByUserIDSeq,  --UI Hidden value against the drop down show in Batch Header
			 U.FirstName + ' ' +  U.LastName               as  ImportedByUserName,   --UI Populate Drop down as Imported By 
			 U.NTUser                                      as  ImportedByNTUserName  --UI Populate by the side of Imported By to show NT User Name as a label based on user selection
	  from   SECURITY.dbo.[User] U with (nolock)
	  where  exists (select top 1 1
					 from   ORDERS.dbo.TransactionImportBatchHeader TIBH with (nolock)
					 where  TIBH.CreatedByIDSeq = U.IDSeq
					)
	) u
	ORDER BY CASE WHEN [ImportedByUserName] like 'All%' THEN '_AA' ELSE [ImportedByUserName] END  ASC;
	RETURN 0
END
GO
