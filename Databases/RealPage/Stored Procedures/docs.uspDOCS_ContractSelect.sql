SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_ContractSelect

Purpose    :  Gets Data from Contract table based on primary key.
             
Parameters : 


Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_ContractSelect

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_ContractSelect]
(
  @IP_IDSeq varchar(22)
)
AS
  Select
    IDSeq,
    CompanyIDSeq,
    OwnerIDSeq,
    PropertyIDSeq,
    DocumentIDSeq,
    TypeCode,
    FamilyCode,
    ProductCode,
    Title,
    TemplateIDSeq,
    TemplateVersion,
    Author,
    PMCSignBy,
    PMCSignByTitle,
    OwnerSignBy,
    OwnerSignByTitle,
    RealPageSignBy,
    RealPageSignByTitle,
    CreatedDate,
    SubmittedDate,
    ReceivedDate,
    ExecutedDate,
    BeginDate,
    ExpireDate,
    CreatedBy,
    ModifiedDate,
    ModifiedBy
  From
    Contract
  Where
    IDSeq = @IP_IDSeq

GO
