@IsTest
public class HandoverRoundRobinTest {
    
    @TestSetup
    static void setupTestData() {
        
        Round_Robins__c rr=new Round_Robins__c(
            Name='Handover Operation',
            Assigned_To__c = String.valueof(1),
            Team__c ='Operation',
            Sobject__c='Handover__c'
        );
        insert rr;
        
        Round_Robins__c rr2=new Round_Robins__c(
            Name='Handover CRM',
            Team__c ='CRM',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Handover__c'
            
        );
        insert rr2;
        
        Profile profileCRM = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        Profile profileOperation = [SELECT Id FROM Profile WHERE Name='Operations Team'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileCRM.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
         User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileOperation.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;

        User userRecord3 = new User(Alias = 'Zaki3', Email='Zakial3@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileOperation.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3432'+'@mail.com');
        insert userRecord3;
        
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=1,
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
        
        Round_Robin_User__c rrUser2=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr2.Id,
            Total_Open_Count__c=11,
            User__c=userRecord3.id
            
        );
        insert rrUser2;
        
        
    }

    @IsTest
    static void testHandoverRoundRobinAssignment() {
       List<Handover__c> handovers = new List<Handover__c>();
        for (Integer i = 0; i < 4; i++) {
            handovers.add(new Handover__c(Name = 'Test Handover ' + i));
        }
        insert handovers;

        Test.startTest();
        HandoverRoundRobin.handoverRRAssignmentToTeam(handovers, 'CRM');
         HandoverRoundRobin.handoverRRAssignmentToTeam(handovers, 'OPERATION');
        Test.stopTest();        
    }

   
}