/*****************************************************************************************
Class       : JointOwnerService
Author      : Biswajeet
Description : Joint Owner service class
test Class: JointOwnerServiceTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public inherited sharing class JointOwnerService {
    
    private static JointOwnerService instance;
    
    private JointOwnerService() {
        
    }
    
    public static JointOwnerService getInstance() { 
        if(instance == null) {
            instance = new JointOwnerService();
        }
        return instance;
    }
    
    public List<JointOwner__c> updateJointOwnersWithoutTrigger(List<JointOwner__c> JointOwnerList){
        if(JointOwnerList != NULL && !JointOwnerList.isEmpty()){
            JointOwnerTriggerHandler.isTriggerDisabled = false;
            update JointOwnerList;
            JointOwnerTriggerHandler.isTriggerDisabled = true; 
        }
        return JointOwnerList;
    }
     public List<JointOwner__c> fetchJointOwners(Id caseId){
        List<JointOwner__c> jointOwnersList = new List<JointOwner__c>();
        jointOwnersList = [Select id,First_Name__c,Phone_Number__c,Email__c,Passport_Expiry_Date__c,Last_Name__c,Nationality__c,Mobile_Country_Code__c,Emirates_ID_expiry_date__c,
                           Emirates_ID__c,Passport_Number__c,
                           Address__City__s,Address__CountryCode__s,
                           Address__PostalCode__s,Address__StateCode__s,
                           Address__Street__s,EIDIssueDate__c,Gender__c,PassportIssueDate__c,Customer_Type__c,NameInArabic__c,Salutation__c,PlaceofIssue__c,Language_Preference__c,UAEResident__c,Birthdate__c from JointOwner__c where Case__c = :caseId];
        return jointOwnersList;  
    }
}