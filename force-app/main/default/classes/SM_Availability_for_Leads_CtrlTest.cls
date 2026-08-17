@istest
public class SM_Availability_for_Leads_CtrlTest{
    @istest
    Static void Testmethod1(){
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
    Test.startTest();
        List<User> userList = SM_Availability_for_Leads_Ctrl.getUserRecords();
        Test.stopTest();
}
     @istest
    Static void Testmethod2(){
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
        userRecord.Alias = 'Zaki H';
        Update userRecord;
   Test.startTest();
        SM_Availability_for_Leads_Ctrl.updateUsers(new List<User>{userRecord});
        Test.stopTest();
}
}