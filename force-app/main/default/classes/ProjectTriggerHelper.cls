/*****************************************************************************************
Class       : ProjectTriggerHelper
Author      : Biswajeet 
Description : 
TestClass   : ProjectTriggerHelperTest
Created Date: 15 Oct 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             15Oct2024           Initial Version 
*****************************************************************************************/
public class ProjectTriggerHelper {
    
    public static void createDocuments(List<Project__c> newList){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> projectDocTypeList = objDocumentService.getDocTypes('Project');
        List<Document__c> documentList = new List<Document__c>();
        for(Project__c project :newList){
            for(DocumentType__c objDocumentType :projectDocTypeList){
                documentList.add(new Document__c(Project__c	= project.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);
    }
}