/**
* @File Name : CustomerDocumentService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 8, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 8, 2024 |   | Initial Version
**/

public class CustomerDocumentService {
	
    public List<Customer_Document__c> getCustomerDocuments(Id caseId){
       return [SELECT Id,Service_Catolog_Documents__c FROM Customer_Document__c WHERE Case__c = :caseId ];
              
    }
    public List<Customer_Document__c> getCustomerDocumentsByCatalogId(String parentId,String sCatalogDocId){
        
        return [select Id from Customer_Document__c where Case__c =:parentId AND Service_Catolog_Documents__c=:sCatalogDocId];
    }
    public Integer getDocumentsCountOnCase(String prentId){
        return [SELECT COUNT() FROM Customer_Document__c WHERE Case__c=:prentId];
    }
	
    public List<Customer_Document__c> getDocumentsRelatedToAccount(String accountId){
        return [
                    SELECT Name
                    FROM Customer_Document__c
                    WHERE Account__c = :accountId
                ];
    }

    
	public void createCustomerDocument(List<Customer_Document__c> request){
        insert request;
    }
    
    public void updateCustomerDocument(List<Customer_Document__c> request){    
        update request;
    }
    
}