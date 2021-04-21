SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_RequiredTemplateList

Purpose    :  Gets data from RequiredTemplate table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_RequiredTemplateList

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_RequiredTemplateList]
AS
  Select
    IDSeq,
    TemplateIDSeq,
    FamilyCode,
    ProductCode
  From
    RequiredTemplate

GO
