SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [documents].[fn_getDateSigned]  (@IPVC_DocumentID varchar(22)
                                        )
returns varchar(10)
as
begin
         declare @LVVC_DateSigned as varchar(10)
         set     @LVVC_DateSigned = null
         select  @LVVC_DateSigned = convert(varchar(10),AgreementSignedDate,101) 
         from    Documents.dbo.[Document] with (nolock)
         where   DocumentIDSeq = @IPVC_DocumentID 
         return  @LVVC_DateSigned
end

GO
