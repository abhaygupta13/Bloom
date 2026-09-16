/*****************************************************************************************
Class       : DocumentTypeService
Author      : Jayesh 
Description : Document Type Object Service Class
TestClass   : DocumentTypeServiceTest
Created Date: 05 Dec 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             05Dec2024            Initial Version 
*****************************************************************************************/
public inherited sharing class DocumentTypeService {
    private static DocumentTypeService instance;
    
    private DocumentTypeService() {
        
    }
    
    public static DocumentTypeService getInstance() { 
        if(instance == null) {
            instance = new DocumentTypeService();
        }
        return instance;
    }
    
    public List<DocumentType__c> getDocumentTypeRecords(String objectName){
        return [SELECT Id, Name, Type__c, Document_Output_Name__c, Document_Digital_Name__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c,ObjectType__c
                FROM DocumentType__c 
                WHERE ObjectType__c = :objectName];
    }
     public List<DocumentType__c> getActiveDocusignDocumentTypeRecords(String objectName){
        return [ SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, 
                Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                FROM DocumentType__c 
                WHERE Active__c = true 
                AND DigitalSignature__c = true
                AND ObjectType__c =:objectName];
    }
     public List<DocumentType__c> getActiveDocuGenDocumentTypeRecords(String objectName){
        return [SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
                Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                FROM DocumentType__c 
                WHERE Active__c = true AND IsDocgen__c= true AND ObjectType__c =:objectName];
    }
    public List<DocumentType__c> getDocumentTypeByIds(List<Id> documentTypeIds){
        return [SELECT Id, Type__c, Document_Output_Name__c, Document_Digital_Name__c,
                Docusign_Envelope_Template__r.dfsle__DocuSignId__c
                FROM DocumentType__c
                WHERE Id IN :documentTypeIds
               ];
    }
    
}