@isTest
public class LeadRoundRobinTest {
    @isTest static void LeadRoundRobinTest(){           
        
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Sales Manager'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki Al Bakri', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        
        Round_Robins__c rr=new Round_Robins__c(
            Name='Sales Manager',
            Sobject__c='Lead'
        );
        insert rr;
        
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=5,
            User__c=userRecord.Id
        );
        insert rrUser;
       
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=11,
            User__c=userRecord.id
        );
        insert rrUser1;
        List<Round_Robin_User__c> rruList= new List<Round_Robin_User__c>();
        rruList.add(rrUser);
        map<Integer, Round_Robin_User__c> rruMap=new map<Integer, Round_Robin_User__c>();
        rruMap.put(1, rrUser);
        List<Round_Robin_User__c> rruList1= new List<Round_Robin_User__c>();
        rruList1.add(rrUser1);
        map<Integer, Round_Robin_User__c> rruMap1=new map<Integer, Round_Robin_User__c>();
        rruMap.put(2, rrUser1);
       
       
       
    }
    @isTest
    static void testleadOwnerUpdateBasedOnRROnUpdate() {
        
        Round_Robins__c rr=new Round_Robins__c(
            Name='Sales Manager',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Lead'
        );
        insert rr;
        
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Sales Manager'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
         User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;
        
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=5,
            User__c=userRecord.id
        );
        insert rrUser;
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=10,
            User__c=userRecord2.id
        );
        insert rrUser1;
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Lead testLead = new Lead(); 
        testLead.LastName = 'Testclass';
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'New';
        testLead.MobilePhone = '37829292020';
        testLead.Email = 'testlead@example.com';
        testLead.Lead_Channel__c = 'Call';
        testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
        testLead.leadsubsource__c='Instagram';
        testLead.OwnerId = adminUser.Id;
        insert testLead;
        // Update the lead's status to 'Qualified' and change the owner
        testLead.Status = 'Qualified';
        testLead.BuyRent__c = 'Buy';
       testLead.PropertyUsage__c = 'Residential Sale';
        testLead.AreaSqmt__c = '35-65 SQM';
        testLead.CustomerBudget__c = '300k-650K';
        testLead.NumberOfBedrooms__c = '1BHK';
        testLead.UnitType__c = 'Apartment';
       // testLead.PropertyReadiness__c = '0-12 months';
        testLead.Project__c = 'Bloom Living';
        User newOwner = [SELECT Id FROM User WHERE Profile.Name = 'Sales Manager' AND IsActive = true LIMIT 1];
        testLead.OwnerId = UserInfo.getUserId();
        
        Lead testLead1 = new Lead(); 
        testLead1.LastName = 'Testclass';
        testLead1.MobileCountryCode__c = '971';
        testLead1.Status = 'New';
        testLead1.MobilePhone = '3782929202022';
        testLead1.Email = 'testlead19@example.com';
        testLead1.Lead_Channel__c = 'Call';
        testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
        testLead.leadsubsource__c='Instagram';
        testLead1.OwnerId = adminUser.Id;
        insert testLead1;
        // Update the lead's status to 'Qualified' and change the owner
        testLead1.Status = 'Qualified';
        testLead1.BuyRent__c = 'Buy';
        testLead1.PropertyUsage__c = 'Residential Sale';
        testLead1.AreaSqmt__c = '35-65 SQM';
        testLead1.CustomerBudget__c = '300k-650K';
        testLead1.NumberOfBedrooms__c = '1BHK';
        testLead1.UnitType__c = 'Apartment';
        testLead1.Project__c = 'Bloom Living';
        testLead1.OwnerId = UserInfo.getUserId();
        
        
        
        Test.startTest();
        
        update testLead;
        update testLead1;
        Delete testLead;
        testLead1.Status = 'Retired';
       testLead1.RetiredReason__c = 'Lost Interest';
        testLead1.RetirementComments__c = 'Retried';
        testLead1.OwnerId = UserInfo.getUserId();
        update testLead1;
        
        Test.stopTest();
    }
    @isTest static void LeadRoundRobinTest1(){
        Round_Robins__c rr=new Round_Robins__c(
            Name='Sales Manager',
            Sobject__c='Lead'
        );
        insert rr;       
       
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Sales Manager'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial1@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri1', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
         User userRecord2 = new User(Alias = 'Zaki', Email='Zakial12@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki2 Al Bakri1', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'wqewqe'+'@mail.com');
        insert userRecord;
         Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=5,
            User__c=userRecord.id
        );
        insert rrUser;
      
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=5,
            User__c=userRecord2.id
        );
        insert rrUser1;
        List<Round_Robin_User__c> rruList= new List<Round_Robin_User__c>();
        rruList.add(rrUser);
        map<Integer, Round_Robin_User__c> rruMap=new map<Integer, Round_Robin_User__c>();
        rruMap.put(1, rrUser);
        List<Round_Robin_User__c> rruList1= new List<Round_Robin_User__c>();
        rruList1.add(rrUser1);
        map<Integer, Round_Robin_User__c> rruMap1=new map<Integer, Round_Robin_User__c>();
        rruMap.put(2, rrUser1);
        Test.startTest();
      

        Test.stopTest();
    }
    
}