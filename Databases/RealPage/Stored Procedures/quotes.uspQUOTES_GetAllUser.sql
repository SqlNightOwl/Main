SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [quotes].[uspQUOTES_GetAllUser] 
AS
BEGIN
 select distinct
      isnull(u.IDSeq,0)                as IDSeq,
      u.FirstName+' '+u.LastName        as UserName
 from [Quotes]..[quote] q
 inner join [Security]..[user] u
 on q.modifiedByIDSeq = u.IDseq order by UserName

END

--exec Quotes..uspQUOTES_GetAllUser
GO
