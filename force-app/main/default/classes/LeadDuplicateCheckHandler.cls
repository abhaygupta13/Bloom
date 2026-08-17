/***
Class       : LeadDuplicateCheckHandler
Author      : Smaartt
Description : created to check the lead duplicates and update the lead types.
TestClass  : LeadDuplicateCheckHandlerTest
HelperClass: 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version_DevInitials     Date       Author          Details
1.          V1.0              10/07/23    Vinay      Initial Version 
****************************************************************************************************************/


public class LeadDuplicateCheckHandler {
    public static void handleDuplicateLeads(List<Lead> trgNew) {
        Map<string,lead> workingQualifyMap = new Map<string,lead>();
        Map<string,lead> retiredMap = new Map<string,lead>();
        Map<string,Account> ExistingAccountMap = new Map<string,Account>();
        set<String> Key = new set<String>();
        Id personRecId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        System.debug('Person Account RecordTypeId: ' + personRecId);
        for(lead le : trgNew ){
            key.add(le.MobilePhone + '_' + le.Email); 
        }
        for(lead ld : [select id,Status,Duplicate_key__c From Lead where Duplicate_key__c In:key]){
            If(ld.Status == 'Retired'){
                retiredMap.put(ld.Duplicate_key__c,ld); 
            }
            If(ld.Status == 'Working' || ld.Status == 'Qualified'){
                workingQualifyMap.put(ld.Duplicate_key__c,ld); 
            }
        }
        for(Account Acc : [select id,Duplicate_key__c,RecordTypeId From Account where Duplicate_key__c In:key AND RecordTypeId=:personRecId]){
            ExistingAccountMap.put(Acc.Duplicate_key__c,Acc);
        }
        
        for(lead le:trgNew){
            string tempkey = le.MobilePhone + '_' + le.Email;
            if(retiredMap.containskey(tempkey)){
                le.Lead_Type__c = 'Recurring Lead';
                
            }
            if(workingQualifyMap.containskey(tempkey)){
                le.Lead_Type__c = 'Recurring Lead';
                le.ParentLead__c = workingQualifyMap.get(tempkey).id; 
                
            }
            if(ExistingAccountMap.containskey(tempkey)){
                le.Lead_Type__c = 'Existing Customer';
                le.ExistingAccount__c = ExistingAccountMap.get(tempkey).id;
            }
        }
        
    }
}