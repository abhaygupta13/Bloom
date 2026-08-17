@isTest
public class EmirateIdReaderHandlerTest {
    @isTest static void EmirateIdReaderHandlerTestMethod(){
        
        Id AccountRecordTypeId = [SELECT Id, Name FROM RecordType WHERE Name = 'Person Account' LIMIT 1].Id;
        
        // Create a new Account with the specified RecordTypeId and Name
        Account acc = new Account();
        acc.RecordTypeId = AccountRecordTypeId;
        acc.FirstName = 'Test Account';
        acc.LastName ='test';
        acc.MiddleName ='test';
        acc.Emirates_Id__pc = '34353';
        acc.PersonMobilePhone= '53535';
        acc.PersonEmail ='abc@gmail.com';
        acc.PassportNumber__pc ='5353';
        acc.NameinArabic__c='test';
        acc.Title_Arabic__c ='test';
        acc.PersonGenderIdentity = 'Male';
        acc.PersonBirthdate = System.today();
        acc.EID_Expiry_Date__pc = System.today();
        acc.EID_Issue_Date__pc = System.today();
        acc.PassportExpiryDate__pc = System.today();
        acc.PersonHomePhone = '345353';
        acc.Company__pc ='abc';
        acc.MaritalStatus__pc = 'Married';
        acc.Place_of_Issuance__c ='Dubai';
        acc.Qualification__c ='test';
        acc.Position__pc = 'test';
        acc.PersonMailingCity ='Dubai';
        acc.Nationality__pc ='United Arab Emirates';
        acc.PersonMailingCountry ='United Arab Emirates';
        acc.PersonMailingCity = 'Dubai';
        acc.PersonMailingPostalCode = '43433';
        acc.PersonMailingStreet = 'test';
        acc.Salutation = 'Mr.';
        acc.Gender__pc = 'Male';
        acc.Place_of_Birth_English__c = 'Dubai';
        acc.PlaceofIssue__pc = 'Dubai';
        acc.No_of_Children__pc = 3;
        acc.Purpose_of_Use__c = 'Investor';
        acc.NoofYearswithCompany__pc =3;
        acc.CustomerType__c = 'Resident';
        acc.CustomerSubType__c = 'CORPORATE';
        
        
        
        
        Account acc1 = new Account(
            RecordTypeId = AccountRecordTypeId,
            FirstName = 'Test Account',
            LastName ='test',
            Emirates_Id__pc = '34353',
            PersonMobilePhone= '53535',
            PersonEmail ='abc@gmail.com',
            PassportNumber__pc ='5353'
        );
        insert acc1;
        
        EmirateIdReaderHandler.getAccountByDocumentAndEmirateId(acc);
        // EmirateIdReaderHandler.createPersonAccount(acc,false);
        EmirateIdReaderHandler.createPersonAccount(acc,true);
        EmirateIdReaderHandler.updateAccount(acc,acc1.id);
        EmirateIdReaderHandler.getAccountByDocumentAndEmirateId(null);
        EmirateIdReaderHandler.createOpportunity(acc1.id);
        
        
    }
    
}