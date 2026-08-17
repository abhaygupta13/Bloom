@isTest
public class OCRCtrlTest {
    @isTest static void OCRCtrlTestMethod(){
        
        Id AccountRecordTypeId = [SELECT Id, Name FROM RecordType WHERE Name = 'Person Account' LIMIT 1].Id;
        
        // Create a new Account with the specified RecordTypeId and Name
        Account acc = new Account(
            RecordTypeId = AccountRecordTypeId,
            FirstName = 'Test Account',
            LastName ='test'
        );
        
      
      
        
        
         Account acc1 = new Account();
        acc1.Name='Test';
        
        insert acc1;
        
        
       
       
        
                 Profile profile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg9847588474.com'
        );
        insert testUser;
        
                         
     
        
        
        OCRCtrl.getVFOrigin();
        OCRCtrl.getAccountByDocumentAndEmirateId(acc1);
       OCRCtrl.createPersonAccount(acc, true, null,'abc@gmail.com','535353',false);
         OCRCtrl.updatePersonAccount(acc1);
        OCRCtrl.getRelatedDocuments(acc.id,'P');
        OCRCtrl.getRelatedDocuments(acc.id,null);
        OCRCtrl.getOcrButtonvisibleDetail(testUser.id);
       
    }
    
      @isTest static void OCRCtrlTestLeadMethod(){
            Lead testLead = new Lead();
        testLead.FirstName = 'John';
        testLead.LastName = 'Doe';
        testLead.Company = 'Test Company';
         testLead.LeadSource = 'Offline';
         testLead.Lead_Channel__c='Email';
         testLead.LeadSubSource__c='Billboards';
       
        String email = 'test@example.com';
        String phoneValue = '123-456-7890';

      
      
          OCRCtrl.createLead(testLead,null, email, phoneValue);
           OCRCtrl.createLead(null,null, email, phoneValue);


          
      }
        
    }