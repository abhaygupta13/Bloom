/*
* @Author : Jayprakash Bharti
* @CreatedDate : 7th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  20AUG2024        Test  GIS Integration Implementation
*****************************************************************************************************/
@isTest
private class UserServiceTest {

    @isTest static void TestMethod1(){
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
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
        Set<Id> userIds = new Set<Id>{userRecord.Id, userRecord2.Id};
        Set<String> salesManagerEmailSet = new Set<String>{uniqueName+'@mail.com',uniqueName+'3232'+'@mail.com'};
        
        Test.startTest();
		UserService objUserService = UserService.getInstance();
		objUserService.hasBypassEmail();
		objUserService.hasBypassIntegration();
		objUserService.hasBypassTrigger();
		objUserService.getUsersByIds(userIds);
		objUserService.getUsersByEmails(salesManagerEmailSet);
        objUserService.getUsersByEmail('Zaki Al Bakri');
        objUserService.getUsersByTitles(new list<String>{'Salesforce Manager'});
		objUserService.getUsersById(userRecord.Id);
        objUserService.getActiveUsersWithEmailByIds(new set<id>{userRecord.Id});
		objUserService.getUserIdByUserName(userRecord.Username);
		
		Test.stopTest();
    }
}