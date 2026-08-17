/***
Class       : OpportunityTriggerHelper
Author      : Smaartt
Description : Helper class for Opportunity Trigger Handler
TestClass   : OpportunityTriggerHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version_DevInitials     Date                Details
1.          V1.0              09/08/23           Initial Version 
****************************************************************************************************************/
public class OpportunityTriggerHelper {
    
    public static void createDocuments(List<Opportunity> newList){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> accountDocTypeList = objDocumentService.getDocTypes('Opportunity');
        List<Document__c> documentList = new List<Document__c>();
        List<Opportunity> oppList = OpportunityService.getInstance().getOpportunitiesWithAccountRecordType(newList);
        for(Opportunity opp : oppList){
            if(opp.OpportunityType__c == 'Leasing'){
                for(DocumentType__c objDocumentType :accountDocTypeList){
                    if(opp.Account.Recordtype.Developername == 'PersonAccount' &&
                       objDocumentType.Customer_Type__c == 'Individual' )
                    {
                        documentList.add(new Document__c(Opportunity__c = opp.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                    }else if (opp.Account.Recordtype.Developername == 'OrganizationAccount' &&
                              objDocumentType.Customer_Type__c == 'Organization')
                    {
                        documentList.add(new Document__c(Opportunity__c = opp.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                    }
                }                
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }
     //Helps to update the Salesorder ADHA Status to prior ADHA Status, 
    //It invokes when ADHA sends Cancellation Application
    public static void updateSalesOrdersADHAStatus(List<Opportunity> newList , Map<Id,Opportunity> oldMap){
        List<SalesOrder__c> salesOrderUpdList = new List<SalesOrder__c>();
        Set<Id> oppIdSet = new Set<Id>();
        SalesOrderService objSalesOrderservice = SalesOrderService.getInstance();
        for(Opportunity opp : newList){
            if(oldMap.get(opp.id).ADHAStatus__c != opp.ADHAStatus__c &&
               opp.ADHAStatus__c == 'Cancel_Rejected'){
                   oppIdSet.add(opp.Id);
             }  
        } 
        for(SalesOrder__c so : objSalesOrderservice.getSalesOrdersByOppIds(oppIdSet)){
            SalesOrder__c soUpd = new SalesOrder__c(id=so.id,ADHAStatus__c = so.PriorADHAStatus__c);
            salesOrderUpdList.add(soUpd); 
        }
         objSalesOrderservice.updateSalesOrdersWithoutTrigger(salesOrderUpdList);
    }
}