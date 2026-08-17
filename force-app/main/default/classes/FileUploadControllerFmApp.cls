/**
* @File Name : FileUploadController .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : January 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | January 10, 2025 |   | Initial Version
**/

public without sharing class FileUploadControllerFmApp {
    @AuraEnabled
    public static Boolean uploadFileToSite(String fileName, String base64Data, Id recordId) {
    
        try {
            // Create ContentVersion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = fileName;
            contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
            insert contentVersion;

            // Query ContentDocumentId
            contentVersion rec= [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
            // Create ContentDocumentLink
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = rec.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.ShareType = 'V'; // Viewer access
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;

            return true;
        } catch (Exception e) {
            System.debug('Error3 uploading file: ' + e.getMessage());
            return false;
        }
    }
}