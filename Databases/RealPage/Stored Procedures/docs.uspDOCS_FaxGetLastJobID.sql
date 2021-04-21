SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_FaxGetLastJobID

Purpose    :  Gets the last JobID for specified TypeCode..
             
Parameters : 

  @IP_FaxTypeCode = INC, OUT
  
Returns    : Last JobID if found otherwise zero.

Date         Author                  Comments
-------------------------------------------------------
05/29/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_FaxGetLastJobID 'INC'

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_FaxGetLastJobID]
(
  @IP_FaxTypeCode VARCHAR(3) = 'INC'
)
AS

SELECT ISNULL(MAX(JOBID), 0) as LastJobID FROM FaxActivity Where FaxTypeCode = @IP_FaxTypeCode


GO
