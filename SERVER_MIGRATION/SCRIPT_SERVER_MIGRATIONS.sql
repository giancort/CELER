

UPDATE DOCS_BRANCH
SET PATH_DOC =
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PATH_DOC, 'C:\', 'E:\'), 'E:\\TKPP-NC\\DOCS\\\\', 'E:\OPERATION_FILES\DOCS\'), 'E:\DOCS\', 'E:\OPERATION_FILES\DOCS\'), 'E:\TKPP-NC\DOCS\\', 'E:\OPERATION_FILES\DOCS\'), 'E:\TKPP-NC\DOCS\', 'E:\OPERATION_FILES\DOCS\')
FROM DOCS_BRANCH
INNER JOIN BRANCH_EC
	ON BRANCH_EC.COD_BRANCH = DOCS_BRANCH.COD_BRANCH
INNER JOIN COMMERCIAL_ESTABLISHMENT
	ON COMMERCIAL_ESTABLISHMENT.COD_EC = BRANCH_EC.COD_EC
WHERE DOCS_BRANCH.ACTIVE = 1
AND PATH_DOC IS NOT NULL

GO

alter table DOCS_AFFILIATOR alter column DOCUMENTS VARCHAR(400);


GO

UPDATE DOCS_AFFILIATOR
SET DOCUMENTS = REPLACE(DOCUMENTS, 'C:\Afiliador', 'E:\OPERATION_FILES\AFFILIATOR\DOCS')
FROM DOCS_AFFILIATOR
--WHERE ACTIVE = 1
--AND DOCUMENTS IS NOT NULL
GO

UPDATE THEMES
SET LOGO_AFFILIATE = REPLACE(LOGO_AFFILIATE, 'C:\Afiliador', 'E:\OPERATION_FILES\AFFILIATOR\THEMES')
   ,LOGO_HEADER_AFFILIATE = REPLACE(LOGO_HEADER_AFFILIATE, 'C:\Afiliador', 'E:\OPERATION_FILES\AFFILIATOR\THEMES')
   ,BACKGROUND_IMAGE = REPLACE(BACKGROUND_IMAGE, 'C:\Afiliador', 'E:\OPERATION_FILES\AFFILIATOR\THEMES')
   ,SELF_REG_IMG_INITIAL = REPLACE(BACKGROUND_IMAGE, 'C:\Afiliador', 'E:\OPERATION_FILES\AFFILIATOR\THEMES')
   ,SELF_REG_IMG_FINAL = REPLACE(BACKGROUND_IMAGE, 'C:\Afiliador', 'E:\OPERATION_FILES\AFFILIATOR\THEMES')
FROM THEMES
WHERE ACTIVE = 1


UPDATE ASSIGN_FILE
SET [path] = REPLACE([path], 'C:\TKPP-NC\DOCS\Cessao', 'E:\OPERATION_FILES\ASSIGNED')
FROM ASSIGN_FILE

UPDATE NOTIFICATION_MESSAGES
SET LINK_REPORT = REPLACE(LINK_REPORT, 'C:\ExportReport', 'E:\OPERATION_FILES\REPORT_EXPORT')
FROM NOTIFICATION_MESSAGES

UPDATE MESSAGING
SET LINK_MESSAGE = REPLACE(LINK_MESSAGE, 'C:\FILEMESSAGE', 'E:\OPERATION_FILES\FILE_MESSAGE')
FROM MESSAGING
WHERE LINK_MESSAGE <> ''