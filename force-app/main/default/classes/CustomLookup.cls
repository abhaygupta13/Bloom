/***
Class       : CustomLookup
Author      : Smaartt
Description : 
TestClass   : CustomLookupTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              12/12/23           Initial Version  

****************************************************************************************************************/
public without sharing class CustomLookup {
     
    @AuraEnabled(cacheable=true)
    public static list<sObject> searchLookupData(string searchKey , string sObjectApiName,String parentId) {    
        List < sObject > returnList = new List < sObject > ();
        string sWildCardText = '%' + searchKey + '%';
       String status ='Sold';
        string sQuery;
        if(sObjectApiName=='SalesOrder__c'){
            sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText AND Status__c=:status order by createdDate DESC LIMIT 5';
        System.debug(sQuery );
        }
        else if (sObjectApiName == 'Unit__c' && String.isNotBlank(parentId)) {
            set<Id> allocationId = new set<Id>();
            for(Unit_Allocation__c ua:[select Unit__c FROM Unit_Allocation__c  WHERE Account__c = :parentId AND Active__c =true]){
                allocationId.add(ua.Unit__c);
            }
            sQuery = 'SELECT Id, Name FROM Unit__c WHERE Id = :allocationId ORDER BY CreatedDate DESC';
        } 
        else if (sObjectApiName == 'Amenities__c' && String.isNotBlank(parentId)) {
            String  projectRec = [select project__c from unit__c where Id=:parentId].project__c;
            sQuery = 'SELECT Id, Name FROM Amenities__c  WHERE project__c = :projectRec AND isPaid__c =false ORDER BY CreatedDate DESC ';
        } 
        else{
            sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText  order by createdDate DESC LIMIT 5';
        System.debug(sQuery );
        }
       
        for (sObject obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
    }
     
    // Method to fetch lookup default value 
    @AuraEnabled
    public static sObject searchDefaultRecord(string recordId , string sObjectApiName) {
        string sRecId = recordId;    
        string sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        for (sObject obj: database.query(sQuery)) {
            return obj;
        }
        return null;
    }
    @AuraEnabled
    public static List<SalesOrder__c>getSalesordetail(string salesorderId) {
        List<Salesorder__c>salesorderdetail = [Select id,LegalStatus__c,Name,Account__r.Name,Account__r.PersonMobilePhone,Account__r.PersonEmail From Salesorder__c where id=:salesorderId AND Account__r.isPersonAccount=true];
        if(salesorderdetail.size()>0)
             return salesorderdetail;
        else
            return null;
        
       
    }
}