USE [SBOHTL_v4]
GO

/****** Object:  View [dbo].[HTL_SummuryReferenceB1SLQuery]    Script Date: 11/20/2025 9:34:54 AM ******/
DROP VIEW [dbo].[HTL_SummuryReferenceB1SLQuery]
GO

/****** Object:  View [dbo].[HTL_SummuryReferenceB1SLQuery]    Script Date: 11/20/2025 9:34:54 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- Create the view
CREATE VIEW [dbo].[HTL_SummuryReferenceB1SLQuery] AS

--USE SBOHTL_v3

SELECT

	A.DocNum as paramater,
    A.AbsEntry AS [AbsEntry],
    A.NAME AS Project_Name,
	C.U_HT_DocSequence [Sequence Number],
    --C.DocNum AS [DocNum],
	a.NAME AS [DocNum],
    C.DocEntry AS [DocEntry],
    --SUM(C.DocTotal) OVER (
    --    PARTITION BY
    --        A.AbsEntry
    --) [TotalAmount],
	SUM(C1.[Max1099]) OVER (
        PARTITION BY
            A.AbsEntry
    ) [TotalAmount],

	C.ObjType As [ObjType],
    --C.DocTotal AS [Max1099],
	C1.[Max1099],
	--C1.U_tl_expdic,
    A.FIPROJECT AS [FIPROJECT],
    C.TaxDate AS [AP TAXDATE]

FROM OPMG A

    INNER JOIN PMG4 A4 ON A.AbsEntry = A4.AbsEntry
    LEFT OUTER JOIN ODPO B ON A4.AbsEntry = B.U_HT_JobNo
    LEFT OUTER JOIN PCH9 C9 ON B.DocEntry = C9.BaseAbs
    INNER JOIN OPCH C ON C9.DocEntry = C.DocEntry and c.CANCELED = 'N'
	LEFT OUTER JOIN (
		SELECT 

			C1.DocEntry, C1.U_tl_expdic, C1.LineTotal
			--SUM(C1.GTotal) OVER (PARTITION BY C1.DOCENTRY ) AS [Max1099],
			--,(ISNULL(C1.GTotal,0) - ISNULL(Y1.GTotal, 0)) AS [DpmAmnt] 
			,case when C1.U_tl_expdic IS NULL OR C1.U_tl_expdic <> 'OP-0041' THEN SUM(ISNULL(C1.GTOTAL,0)) OVER (PARTITION BY C1.DOCENTRY) END AS [Max1099]
			
		FROM PCH1 C1 
		LEFT OUTER JOIN RPC1 Y1 ON C1.DocEntry = Y1.BaseEntry AND C1.ObjType = Y1.BaseType AND C1.LineNum = Y1.BaseLine 
		WHERE 
		--c1.DocEntry = 172 AND
		C1.U_tl_expdic IS NULL OR C1.U_tl_expdic <> 'OP-0041' and (ISNULL(C1.GTotal,0) - ISNULL(Y1.GTotal, 0)) <> 0
		)C1 ON C.DocEntry = C1.DocEntry

    LEFT OUTER JOIN OCRD D ON B.CardCode = D.CardCode

GROUP BY

	A.DocNum,
	C.U_HT_DocSequence,
    C.DocNum,
    A.FIPROJECT,
    C1.Max1099,
    C.DocEntry,
    C.TaxDate,
    A.AbsEntry,
    A.NAME,
	C.ObjType,
	--C1.U_tl_expdic,
    C.DocTotal


GO


