USE [SBOHTL_v4]
GO

/****** Object:  View [dbo].[HTL_SummuryTotalB1SLQuery]    Script Date: 11/20/2025 9:35:36 AM ******/
DROP VIEW [dbo].[HTL_SummuryTotalB1SLQuery]
GO

/****** Object:  View [dbo].[HTL_SummuryTotalB1SLQuery]    Script Date: 11/20/2025 9:35:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- Create the view
CREATE VIEW [dbo].[HTL_SummuryTotalB1SLQuery] AS

SELECT 
	Y.TotalAdvance, 
	Z.FIPROJECT, 
	Z.TotatReference, 
	ISNULL(Y.TotalAdvance, 0)- ISNULL(Z.TotatReference, 0) AS [SubTotal],
	z.AbsEntry, 
	z.Project_Name

FROM OPMG A
INNER JOIN 
(
        SELECT
            A.FIPROJECT, SUM(ISNULL(C1.Max1099,0)) OVER (
                PARTITION BY
                    A.AbsEntry)[TotatReference] , A.AbsEntry, A.NAME AS Project_Name
            /*Move Max1099 To DocTotal and parition by absentry*/
        FROM
            OPMG A
            INNER JOIN PMG4 A4 ON A.AbsEntry = A4.AbsEntry
            LEFT OUTER JOIN ODPO B ON A4.AbsEntry = B.U_HT_JobNo
            LEFT OUTER JOIN PCH9 C9 ON B.DocEntry = C9.BaseAbs
            INNER JOIN OPCH C ON C9.DocEntry = C.DocEntry
			LEFT OUTER JOIN (
				SELECT 
					C1.DocEntry, C1.U_tl_expdic, C1.LineTotal
					,case when C1.U_tl_expdic IS NULL OR C1.U_tl_expdic <> 'OP-0041' THEN SUM(ISNULL(C1.GTOTAL,0)) OVER (PARTITION BY C1.DOCENTRY) END AS [Max1099]
				FROM PCH1 C1 
					LEFT OUTER JOIN RPC1 Y1 ON C1.DocEntry = Y1.BaseEntry AND C1.ObjType = Y1.BaseType AND C1.LineNum = Y1.BaseLine 
				WHERE 
				C1.U_tl_expdic IS NULL OR C1.U_tl_expdic <> 'OP-0041' and (ISNULL(C1.GTotal,0) - ISNULL(Y1.GTotal, 0)) <> 0
				)C1 ON C.DocEntry = C1.DocEntry
            LEFT OUTER JOIN OCRD D ON B.CardCode = D.CardCode
        GROUP BY
            A.AbsEntry, A.FIPROJECT, C.Max1099, C.DocTotal, A.NAME,C1.Max1099
    ) Z ON Z.AbsEntry = A.AbsEntry
    
	INNER JOIN (
        SELECT
		A.AbsEntry,
		A.FIPROJECT
		,SUM(B.GTotal) OVER (PARTITION BY A.AbsEntry) as [TotalAdvance]
        FROM
            OPMG A
            LEFT OUTER JOIN PMG4 A4 ON A.AbsEntry = A4.AbsEntry
            LEFT OUTER JOIN (
                SELECT 
					B.U_HT_JobNo, B.CardCode, B.DpmAmnt, B.DocTotal,B1.GTotal     
                FROM ODPO B
					LEFT OUTER JOIN DPO1 B1 ON B.DocEntry = B1.DocEntry
            ) B ON A.AbsEntry = B.U_HT_JobNo
            LEFT OUTER JOIN OCRD D ON B.CardCode = D.CardCode
        WHERE
            A4.TYP = 204 
        GROUP BY
            B.DpmAmnt, B.DocTotal, B.DpmAmnt, A.FIPROJECT, A.AbsEntry,b.GTotal
    ) Y ON A.AbsEntry = Y.AbsEntry

GO


