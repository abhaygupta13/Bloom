/***
Class       : OCRCtrl
Author      : Smaartt
Description : 
TestClass   : Test Class Name
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public  class OCRCtrl {
    
     @AuraEnabled(cacheable=true)
    public static string getVFOrigin(){        
        string baseURL = URL.getOrgDomainUrl().toExternalForm();
        return baseURL.split('.my.')[0] + '--c.' + 'vf.force.com';
       // return 'https://bloomholding--prodcopy--c.sandbox.vf.force.com';
     }

    
  
    
     @AuraEnabled
    public static List<Account> getAccountByDocumentAndEmirateId(Account acc) {
        List<Account> existingAccount = new List<Account>();
        
        try {
            if (acc.PassportNumber__pc != null ) {
                   existingAccount = [SELECT Id, Name,  PersonEmail,PersonMobilePhone , PassportNumber__pc, Emirates_Id__pc, PersonBirthdate, PersonGenderIdentity,Gender__pc, Nationality__pc 
                                   FROM Account 
                                   WHERE PassportNumber__pc = :acc.PassportNumber__pc AND PassportNumber__pc != null];


                                         
                System.debug(existingAccount);
               
            }else if(acc.Emirates_Id__pc != null){
                 existingAccount = [SELECT Id, Name,  PersonEmail,PersonMobilePhone , PassportNumber__pc, Emirates_Id__pc, PersonBirthdate, PersonGenderIdentity,Gender__pc, Nationality__pc 
                                   FROM Account 
                                   WHERE Emirates_Id__pc = :acc.Emirates_Id__pc AND Emirates_Id__pc != null];
            }
             System.debug(existingAccount.size());
                return existingAccount;
        } catch (Exception e) {
            return null;
            
           
            
        }
        
        
    }
    
   
    
    
    @AuraEnabled
    public static String createPersonAccount(Account acc, Boolean createwalkinopportunity, String mobileCountrycode, String emailaddress, String phonevalue,Boolean isDuplicateEligible) {
        String str = '';
        System.debug(isDuplicateEligible);
        if(isDuplicateEligible!=true){
            List<Account>existingAccount= OCRCtrl.getAccountByDocumentAndEmirateId(acc);
            System.debug(existingAccount);
            if (!existingAccount.isEmpty()) {
                // Throw an error indicating duplicate records found
                throw new AuraHandledException('Duplicate document records');
                
            }
            
        }
        
        
        try {
            acc.CreateOpportunity__c = createwalkinopportunity;
            acc.MobileCountryCode__pc = mobileCountrycode;
            acc.PersonEmail = emailaddress;
            acc.PersonMobilePhone = phonevalue;
            
            insert acc;
            str = acc.Id;
        } catch (Exception e) {
            List<String> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            if (errorMessage.contains('Use one of these records?')) {
                errorMessage = 'Document Number already exists.';
            }
            throw new AuraException(errorMessage);
        }
        return str;
    }
    
     @AuraEnabled
    public static void updatePersonAccount(Account acc) {
        
     update acc;        
    }
    
    
    
    @AuraEnabled
    public static String createLead(Lead lead, String mobileCountrycode, String emailaddress, String phonevalue) {
        String str = '';
        
        
        
        try {
            lead.LeadSource = CustomLabelUtility.leadSource;
            lead.Lead_Channel__c = CustomLabelUtility.leadChannel;
            lead.LeadSubSource__c = CustomLabelUtility.leadSubsource;
            lead.MobileCountryCode__c = mobileCountrycode;
            lead.Email = emailaddress;
            lead.MobilePhone = phonevalue;
            insert lead;
            str = lead.Id;
        } catch (Exception e) {
            List<String> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            if (errorMessage.contains('Use one of these records?')) {
                errorMessage = 'Document Number already exists.';
            }
            
        }
        return str;
    }
    
    
    @AuraEnabled
    public static list<Document__c> getRelatedDocuments(String recordId,string doctype){
        list <Document__c> docList=new list <Document__c>();
        if(doctype=='P'){
            docList=[select id,name,Document_Name__c from Document__c where Account__c =:recordId and Document_Name__c like 'Passport%'];
        }
        else{
            docList=[select id,name,Document_Name__c from Document__c where Account__c =:recordId and Document_Name__c like 'Emirate%'];
        }
        return docList;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean>getOcrButtonvisibleDetail(Id userId) {
        
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :userId];
        String profileName = currentUser.Profile.Name;
        Map<String, Boolean> visibilityMap = new Map<String, Boolean>();
        
        List<OCR_Button_Visiblity__mdt>getOcrData = [SELECT id,usrIdentifer__c,MasterLabel FROM OCR_Button_Visiblity__mdt WHERE usrIdentifer__c LIKE :('%' + profileName + '%')];
        for(OCR_Button_Visiblity__mdt metadata: getOcrData){
            String label = metadata.MasterLabel;
            visibilityMap.put(label, true);
        }
        return visibilityMap;
    }
    
    
    
}