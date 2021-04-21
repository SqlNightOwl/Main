SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [documents].[uspCUSTOMERS_InsertDocument] (
                                                               @IPVC_DocumentTypeCode  varchar(5),
                                                               @IPVC_DocumentLevelCode varchar(5), 
                                                               @IPVC_Name              varchar(255),
                                                               @IPVC_Description       varchar(1500),
                                                               @IPVC_CompanyIDSeq      varchar(11),
                                                               @IPVC_CreatedDate       varchar(10),  
                                                               @IPVC_DocumentPath      varchar(255)
                                                     )
as
begin
    
      insert into Documents.dbo.[Document]
      (
           DocumentTypeCode,
           DocumentLevelCode,
           Name,
           Description,
           CompanyIDSeq,
           CreatedDate,
           DocumentPath,
           ModifiedDate   
      )
 values
      (
           @IPVC_DocumentTypeCode,
           @IPVC_DocumentLevelCode, 
           @IPVC_Name,
           @IPVC_Description,
           @IPVC_CompanyIDSeq,
           @IPVC_CreatedDate,
           @IPVC_DocumentPath,
           getdate()
      )
END

GO
