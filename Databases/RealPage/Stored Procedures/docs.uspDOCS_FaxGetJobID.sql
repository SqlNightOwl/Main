SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_FaxGetJobID

Purpose    :  Gets the  JobID..
             
Parameters : 

  @IP_JobID = 9184
  
Returns    :  JobID if found otherwise zero.

Date         Author                  Comments
-------------------------------------------------------
06/17/2008   Anand Chakravarthy      Initial Creation


Example: EXEC uspDOCS_FaxGetJobID 'INC'

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_FaxGetJobID]
(
   @IP_JobID int 
)
AS

SELECT * FROM FaxActivity Where JobId = @IP_JobID


GO
