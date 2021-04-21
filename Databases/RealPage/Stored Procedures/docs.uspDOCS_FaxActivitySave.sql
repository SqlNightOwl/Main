SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_FaxActivitySave

Purpose    :  Saves Data into FaxActivity table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/29/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_FaxActivitySave

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_FaxActivitySave]
(
  @IP_IDSeq bigint,
  @IP_JobID int,
  @IP_DocumentIDSeq varchar (22),
  @IP_FaxTypeCode varchar (3),
  @IP_FaxStatusCode varchar (3),
  @IP_FilePath varchar (255),
  @IP_PageCount int,
  @IP_FaxNumber varchar (50),
  @IP_FaxRecipient varchar (255),
  @IP_CreatedDate datetime,
  @IP_CreatedBy varchar(255),
  @IP_IsActive bit,
  @IP_JobStatus int,
  @IP_ErrorDescription varchar(255)
)
AS

  SET @IP_IDSeq = NULLIF(@IP_IDSeq, 0);
  SET @IP_JobID = NULLIF(@IP_JobID, 0);
  
  IF ( EXISTS ( Select TOP 1 1 From FaxActivity WHERE IDSeq=@IP_IDSeq ) )
  BEGIN
    UPDATE FaxActivity SET
      DocumentIDSeq=@IP_DocumentIDSeq, JobID=@IP_JobID
      , FaxTypeCode=@IP_FaxTypeCode, FaxStatusCode=@IP_FaxStatusCode, FilePath=@IP_FilePath
      , PageCount=@IP_PageCount, FaxNumber=@IP_FaxNumber, FaxRecipient=@IP_FaxRecipient
      , CreatedDate=@IP_CreatedDate, CreatedBy=@IP_CreatedBy, IsActive=@IP_IsActive, JobStatus=@IP_JobStatus
      , ErrorDescription=@IP_ErrorDescription, ModifiedDate=getDate()
    OUTPUT 
      INSERTED.IDSeq as IDSeq, INSERTED.JobID as JobID
    Where 
      IDSeq = @IP_IDSeq
  END
  ELSE
  BEGIN
    INSERT INTO FaxActivity
      (DocumentIDSeq, JobID
       , FaxTypeCode, FaxStatusCode, FilePath
       , PageCount, FaxNumber, FaxRecipient
       , CreatedDate, CreatedBy, IsActive, JobStatus
       , ErrorDescription
       )
    OUTPUT 
       INSERTED.IDSeq as IDSeq, INSERTED.JobID as JobID
    VALUES
      (@IP_DocumentIDSeq, @IP_JobID
       , @IP_FaxTypeCode, @IP_FaxStatusCode, @IP_FilePath
       , @IP_PageCount, @IP_FaxNumber, @IP_FaxRecipient
       , @IP_CreatedDate, @IP_CreatedBy, @IP_IsActive, @IP_JobStatus
       , @IP_ErrorDescription
       )
  END

GO
