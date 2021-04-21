SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_DocumentListSelectVer1] (
                                                               @IPI_PageNumber int,
                                                               @IPI_RowsPerPage int,
                                                               @IPVC_CompanyIDSeq varchar(12),
                                                               @IPVC_DocumentType varchar(5), 
                                                               @IPVC_Description  varchar(1500),
                                                               @IPVC_CreatedBy    varchar(70),
                                                               @IPVC_ModifiedDate varchar(10)
                                                              )
as
begin
    
        select * from   
        (select     top  (@IPI_RowsPerPage *  @IPI_PageNumber) 
                   doc.DocumentIDSeq                          as ID,
                   docType.Name                               as [Type],
                   '@'                                        as Attachment,  
                   doc.Name                                   as [Name],
                   doc.Description                            as Description,
                   convert(varchar(10),doc.CreatedDate,101)   as DateSigned,
                   doc.CreatedBy                              as CreatedBy,
                   convert(varchar(10),doc.ModifiedDate,101)  as LastModified,
                   row_number() over(order by doc.DocumentIDSeq)      as RowNumber
        from 
                   Documents.dbo.[Document] doc 
 
        inner join Documents.dbo.DocumentType docType

        on    doc.DocumentTypeCode = docType.Code            
                    
        where CompanyIDSeq = @IPVC_CompanyIDSeq

        and (
                   (((@IPVC_DocumentType <> '') and (docType.Code = @IPVC_DocumentType)) 
                or  (@IPVC_DocumentType =  ''))
                
                and
                   (((@IPVC_Description <> '') and (doc.Description like  '%'+@IPVC_Description+'%')) 
                or  (@IPVC_Description =  ''))

                and
                   (((@IPVC_CreatedBy <> '') and (doc.CreatedBy like  '%'+@IPVC_CreatedBy+'%')) 
                or  (@IPVC_CreatedBy =  '')) 

                and
                   (((@IPVC_ModifiedDate <> '') and ((convert(varchar(10),doc.ModifiedDate,101)) = @IPVC_ModifiedDate)) 
                or  (@IPVC_ModifiedDate =  '')) 
            )

        )tbl
            where RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage


            /*Get the number of records */

            select count(*)
                  
        from 
                   Documents.dbo.[Document] doc 
 
        inner join Documents.dbo.DocumentType docType

        on    doc.DocumentTypeCode = docType.Code            
                    
        where CompanyIDSeq = @IPVC_CompanyIDSeq

        and (
                   (((@IPVC_DocumentType <> '') and (docType.Code = @IPVC_DocumentType)) 
                or  (@IPVC_DocumentType =  ''))
                
                and
                   (((@IPVC_Description <> '') and (doc.Description like  '%'+@IPVC_Description+'%')) 
                or  (@IPVC_Description =  ''))

                and
                   (((@IPVC_CreatedBy <> '') and (doc.CreatedBy like  '%'+@IPVC_CreatedBy+'%')) 
                or  (@IPVC_CreatedBy =  '')) 

                and
                   (((@IPVC_ModifiedDate <> '') and ((convert(varchar(10),doc.ModifiedDate,101)) = @IPVC_ModifiedDate)) 
                or  (@IPVC_ModifiedDate =  '')) 
            )
END

GO
