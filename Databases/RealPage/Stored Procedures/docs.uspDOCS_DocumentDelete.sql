SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_DocumentDelete

Purpose    :  Deletes data from Document table.
             
Parameters : DocumentIDSeq

Returns    : code indicating if the Delete were successful

Date         Author                  Comments
-------------------------------------------------------
06/06/2008   Anand Chakravarthy              Initial Creation


Example: EXEC uspDOCS_DocumentDelete

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/     
CREATE Procedure [docs].[uspDOCS_DocumentDelete](                
											     @IP_IDSeq    varchar(22)  
                                               )   
AS
BEGIN

 IF EXISTS(SELECT DocumentIDSeq from Docs.dbo.Contract WHERE [DocumentIDSeq] = @IP_IDSeq)
    DELETE FROM Docs.dbo.Contract WITH (ROWLOCK) WHERE [DocumentIDSeq] = @IP_IDSeq

 DELETE FROM Docs.dbo.DocumentHistory WITH (ROWLOCK) WHERE [DocumentIDSeq] = @IP_IDSeq
 DELETE FROM Docs.dbo.Document WITH (ROWLOCK) WHERE [DocumentIDSeq] = @IP_IDSeq
  

END  
  
 
GO
