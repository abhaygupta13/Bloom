/***
Class       : EmirateIdReaderHandler
Author      : Smaartt
Description : 
TestClass   : EmirateIdReaderHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              03/04/24           Initial Version 
****************************************************************************************************************/

public without sharing  class EmirateIdReaderHandler {
    
    @AuraEnabled
    public static List<Account> getAccountByDocumentAndEmirateId(Account acc) {
        List<Account> existingAccount = new List<Account>();
        System.debug('acc'+acc);
        try {
            if(acc.Emirates_Id__pc != null ||acc.PersonMobilePhone!=null || acc.PersonEmail!=null ||acc.PassportNumber__pc != null){
                existingAccount = [SELECT Id, Name,  PersonEmail,PersonMobilePhone , PassportNumber__pc, Emirates_Id__pc, PersonBirthdate,
                                   Gender__pc, Nationality__pc FROM Account 
                                   WHERE (Emirate_Id_Copy__c = :acc.Emirates_Id__pc AND Emirate_Id_Copy__c != null) OR (PassportNumber__pc = :acc.PassportNumber__pc AND PassportNumber__pc != null) OR
                                  (PersonMobilePhone = :acc.PersonMobilePhone AND PersonMobilePhone != null) OR (PersonEmail = :acc.PersonEmail AND PersonEmail != null) ];
            }
            System.debug(existingAccount.size());
            return existingAccount;
        } catch (Exception e) {
            return null;            
        }
        
        
    }
    
    
    
    
    @AuraEnabled
    public static String createPersonAccount(Account acc,Boolean isDuplicateEligible) {
        String str = '';
        System.debug('acc'+acc);
        System.debug(isDuplicateEligible);
        if(isDuplicateEligible!=true){
            List<Account>existingAccount= EmirateIdReaderHandler.getAccountByDocumentAndEmirateId(acc);
            System.debug(existingAccount);
            if (!existingAccount.isEmpty()) {
                // Throw an error indicating duplicate records found
                throw new AuraHandledException('Duplicate document records');
               
            }
            
        }
        
        
        try {
          System.debug('acc'+acc);
         
           insert acc;
         // Database.insert(acc, false);
            str = acc.Id;
        } catch (Exception e) {
            List<String> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            if (errorMessage.contains('Use one of these records?')) {
                errorMessage = 'Duplicate record already exists.';
            }
            throw new AuraException(errorMessage);
        }
        return str;
    }
    
    
    
    @AuraEnabled
    public static void updateAccount(Account acc,String accountId) {
        try {
            System.debug('acc'+acc);
            System.debug('acc'+acc.PersonGenderIdentity);
            Account account = new Account();
            if(!String.isBlank(accountId)){
                account.id = accountId;
            }
             if(acc.FirstName!=null){
                account.FirstName = acc.FirstName;
            }
             if(acc.Salutation!=null){
                account.Salutation = acc.Salutation;
            }
            if(acc.MiddleName!=null){
                account.MiddleName = acc.MiddleName;
            }
            if(acc.LastName!=null){
                account.LastName = acc.LastName;
            }
            if(acc.NameinArabic__c!=null){
                account.NameinArabic__c = acc.NameinArabic__c;
            }
            if(acc.EmirateExpirtyEidTExt__c!=null){
                account.EmirateExpirtyEidTExt__c = acc.EmirateExpirtyEidTExt__c;
            }
            if(acc.GenderEIDReader_text__c!=null){
                account.GenderEIDReader_text__c = acc.GenderEIDReader_text__c;
            }
            if(acc.DobEidText__c!=null){
                account.DobEidText__c = acc.DobEidText__c;
            }
            if(acc.NationalityEidText__c!=null){
                account.NationalityEidText__c = acc.NationalityEidText__c;
            }
            if(acc.EID_Issue_Date__pc!=null){
                account.EID_Issue_Date__pc = acc.EID_Issue_Date__pc;
            }
            if(acc.PassportNumber__pc!=null){
                account.PassportNumber__pc = acc.PassportNumber__pc;
            }
            if(acc.Emirates_Id__pc!=null){
                account.Emirates_Id__pc = acc.Emirates_Id__pc;
            }
            if(acc.PassportExpDateText__c!=null){
                account.PassportExpDateText__c = acc.PassportExpDateText__c;
            }
            if(acc.PersonHomePhone!=null){
                account.PersonHomePhone = acc.PersonHomePhone;
            }
            if(acc.Company__pc!=null){
                account.Company__pc = acc.Company__pc;
            }
            if(acc.MaritalStatus__pc!=null){
                account.MaritalStatus__pc = acc.MaritalStatus__pc;
            } 
            if(acc.Title_Arabic__c!=null){
                account.Title_Arabic__c = acc.Title_Arabic__c;
            } if(acc.Place_of_Birth_English__c!=null){
                account.Place_of_Birth_English__c = acc.Place_of_Birth_English__c;
            }
            if(acc.Qualification__c!=null){
                account.Qualification__c = acc.Qualification__c;
            }
            if(acc.Position__pc!=null){
                account.Position__pc = acc.Position__pc;
            }
            if(acc.PlaceofIssue__pc!=null){
                account.PlaceofIssue__pc = acc.PlaceofIssue__pc;
            }
            if(acc.PersonEmail!=null){
                account.PersonEmail = acc.PersonEmail;
            }
            if(acc.PersonMobilePhone!=null){
                account.PersonMobilePhone = acc.PersonMobilePhone;
            }
            if(acc.Walk_In_Opportunity_Broker__c!=null){
                account.Walk_In_Opportunity_Broker__c = acc.Walk_In_Opportunity_Broker__c;
            }
            if(acc.BrokerAgent__c!=null){
                account.BrokerAgent__c = acc.BrokerAgent__c;
            }
             if(acc.Create_Broker_Opportunity__c!=null){
                account.Create_Broker_Opportunity__c = acc.Create_Broker_Opportunity__c;
            }
             if(acc.Purpose_of_Use__c!=null){
                account.Purpose_of_Use__c = acc.Purpose_of_Use__c;
            }
            if(acc.First_Purchase__c!=null){
                account.First_Purchase__c = acc.First_Purchase__c;
            }
            if(acc.No_of_Children__pc!=null){
                account.No_of_Children__pc = acc.No_of_Children__pc;
            }
             if(acc.CurrentHome__c!=null){
                account.CurrentHome__c = acc.CurrentHome__c;
            }
             if(acc.NoofYearswithCompany__pc!=null){
                account.NoofYearswithCompany__pc = acc.NoofYearswithCompany__pc;
            }
             if(acc.CustomerType__c!=null){
                account.CustomerType__c = acc.CustomerType__c;
            }
             if(acc.CustomerSubType__c!=null){
                account.CustomerSubType__c = acc.CustomerSubType__c;
            }
            if(acc.ResidentStatus__pc!=null){
                account.ResidentStatus__pc = acc.ResidentStatus__pc;
            }
           if(acc.Anniversary_Date__pc!=null){
                account.Anniversary_Date__pc = acc.Anniversary_Date__pc;
            }
             if(acc.Religion__pc!=null){
                account.Religion__pc = acc.Religion__pc;
            }
           /* if(acc.AnnualIncome__pc!=null){
                //account.AnnualIncome__pc = acc.AnnualIncome__pc;
            }*/
            if(acc.CreateOpportunity__c!=null){
                account.CreateOpportunity__c = acc.CreateOpportunity__c;
            }
             if(acc.No_of_Properties_Owned__c!=null){
                account.No_of_Properties_Owned__c = acc.No_of_Properties_Owned__c;
            }
            if(acc.MobileCountryCode__pc!=null){
                account.MobileCountryCode__pc = acc.MobileCountryCode__pc;
            }
           
            
            update account;
        }  catch(Exception e) {
            
            System.debug('Error updating account: ' + e.getMessage());
            throw new AuraHandledException('Error updating account: ' + e.getMessage());
        }
        
    } 
    
      
    @AuraEnabled
    public static String createOpportunity(String accountId) {
        String str = '';
    List<Opportunity>opplist = new List<Opportunity>();
        for(Account acc: [Select id,Name From Account Where id=:accountId]){
            Opportunity opp = new Opportunity();
            opp.Name = acc.Name;
            opp.AccountId = accountId;
            opp.CloseDate = date.today().addDays(60);
            opp.LeadChannel__c = 'Walk in';
            opp.StageName = 'New';
             
            opplist.add(opp);
        }
         if(!opplist.isEmpty()) {
        insert opplist;
        return opplist[0].Id;
    }
    return null;
        
    
    }
}