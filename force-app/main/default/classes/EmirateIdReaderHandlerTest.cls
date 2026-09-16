@isTest
public class EmirateIdReaderHandlerTest {
    @isTest static void EmirateIdReaderHandlerTestMethod(){
        
        Id AccountRecordTypeId = [SELECT Id, Name FROM RecordType WHERE Name = 'Person Account' LIMIT 1].Id;
        
        // Create a new Account with the specified RecordTypeId and Name
        Account acc = new Account();
        acc.RecordTypeId = AccountRecordTypeId;
        acc.FirstName = 'Test Account 1';
        acc.LastName ='test 1';
        acc.MiddleName ='test 1 ';
        acc.Emirates_Id__pc = '343531';
        acc.PersonMobilePhone= '535351';
        acc.PersonEmail ='abc1@gmail.com';
        acc.PassportNumber__pc ='53531';
        acc.NameinArabic__c='test 1';
        acc.Title_Arabic__c ='test 1';
        acc.PersonGenderIdentity = 'Male';
        acc.PersonBirthdate = System.today();
        acc.EID_Expiry_Date__pc = System.today();
        acc.EID_Issue_Date__pc = System.today();
        acc.PassportExpiryDate__pc = System.today();
        acc.PersonHomePhone = '345353';
        acc.Company__pc ='abc 1';
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
            LastName = 'test',
            Emirates_Id__pc = '11111',
            PersonMobilePhone = '999991111',
            PersonEmail = 'test1@test.com',
            PassportNumber__pc = 'P11111'
        );
        EmirateIdReaderHandler.getAccountByDocumentAndEmirateId(acc);
        // EmirateIdReaderHandler.createPersonAccount(acc,false);
        String AccId = EmirateIdReaderHandler.createPersonAccount(acc,true);
        
        acc.Emirates_Id__pc = '22222';
        acc.PersonMobilePhone = '999992222';
        acc.PersonEmail = 'test2@test.com';
        acc.PassportNumber__pc = 'P22222';
        
        //EmirateIdReaderHandler.updateAccount(acc,acc1.id);
        try {
            EmirateIdReaderHandler.updateAccount(acc, acc1.Id);
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            System.assert(true);
        }
        EmirateIdReaderHandler.getAccountByDocumentAndEmirateId(null);
        EmirateIdReaderHandler.createOpportunity(AccId);
        
        
    }
    
}