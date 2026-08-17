@isTest
public class DeSnaggingProcessTest {
    @TestSetup
    static void setupTestData() {
        Profile profile = [Select Id,Name FROM Profile Where Name ='System Administrator' LIMIT 1];
        User testUser = new User(
            Username = 'testhoagent@gmail.com', 
            LastName = 'Test',
            Email = 'testuser@example.com',
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
         insert testUser;

        Unit__c unt = new Unit__c();
        unt.Name = 'Unit Test A143';
        unt.HO_Agent__c = testUser.Id;
        unt.Status__c = 'Booked';
        unt.SAP_Unit_Number__c = '123';
        insert unt;
        
        Handover__c hand = new Handover__c();
        hand.Status__c = 'In Progress';
        hand.Unit__c = unt.Id;  
        insert hand;  
        
    }
    @isTest
    static void deSnaggingReportTest(){ 
        Handover__c handOver =[select Id,Name, sub_status__c, Unit__c from Handover__c where  Unit__r.name ='Unit Test A143' Limit 1 ];
        //  test data
         Document__c doc = new Document__c();
        doc.Handover__c = handOver.id;
        doc.Document_Name__c = HandoverConstants.HO_QA_Snagging_Report;
        insert doc;
        
         Document__c doc1 = new Document__c();
        doc1.Handover__c = handOver.id;
        doc1.Document_Name__c = HandoverConstants.HO_QA_DeSnagging_Report;
        insert doc1;
        
        String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));
        String fileName = 'testFile.pdf';
        String fileType = 'application/pdf';
        String inspector = 'testuser@example.com';
        String snagCount = '5';
        String status = 'CHO';
        String report_type = 'snagging';
        String report_type2 = 'DESNAGGING';
        String unitNumber = '123';
        Test.startTest();
        String result = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, status, report_type,unitNumber);
        String result2 = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, status, report_type2,unitNumber);
		String result3 = DeSnaggingProcess.deSnaggingReport('', '', '', inspector, snagCount, status, report_type,status);
        String result4 = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, '', report_type2,unitNumber);
        String result5 = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, '', snagCount, status, report_type2,unitNumber);
        String result6 = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, status, report_type2,'');
        Test.stopTest();
        //Assert
      // System.assertEquals('Report uploaded successfully on Handover(' + handOver.Name + ')', result); 
    }
    
    @isTest
    static void deSnaggingReportTest2(){ 
        List<Handover__c> handOver =[select Id,Name, sub_status__c, Unit__c from Handover__c where  Unit__r.name ='Unit Test A143' ];
        delete handOver;
        
       
        
        Unit__c unit = [Select Id, Name, HO_Agent__c FROM Unit__c Where Name = 'Unit Test A143' LIMIt 1];
        unit.HO_Agent__c = null;
        update unit;
        String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));
        String fileName = 'testFile.pdf';
        String fileType = 'application/pdf';
        String inspector = 'testuser@example.com';
        String snagCount = '5';
        String status = 'QA';
        String report_type = 'snagging';
        String unitNumber = '123';
        Test.startTest();
        String result = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, status, report_type,unitNumber);
       // System.assertEquals('Handover created successfully for this unit.', result);
        Test.stopTest();
    }   
@isTest
    static void deSnaggingReportTest3(){ 
        List<Handover__c> handOver =[select Id,Name, sub_status__c, Unit__c from Handover__c where  Unit__r.name ='Unit Test A143' ];
        delete handOver;
        Unit__c unit = [Select Id, Name, HO_Agent__c FROM Unit__c Where Name = 'Unit Test A143' LIMIt 1];
        unit.HO_Agent__c = null;
        update unit;
        String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));
        String fileName = 'testFile.pdf';
        String fileType = 'application/pdf';
        String inspector = 'testuser@example.com';
        String snagCount = '5';
        String status = 'QA';
        String report_type = 'desnagging';
        String unitNumber = '123';
        Test.startTest();
        String result = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, status, report_type,unitNumber);
       // System.assertEquals('Handover created successfully for this unit.', result);
        Test.stopTest();
    }
    @isTest
static void testCHOAlreadyCompleted() {
    Handover__c handOver = [SELECT Id, Unit__c FROM Handover__c WHERE Unit__r.Name = 'Unit Test A143' LIMIT 1];

    handOver.Sub_Status__c = HandoverConstants.Handover_Sub_Status_CHO_SNAGGING_COMPLETED;
    update handOver;

    Document__c doc = new Document__c(
        Handover__c = handOver.Id,
        Document_Name__c = HandoverConstants.HO_CHO_DeSnagging_Report
    );
    insert doc;

    String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('PDF'));
    String fileName = 'testFile';
    String fileType = '.pdf';
    String inspector = 'testuser@example.com';
    String snagCount = '2';
    String status = 'CHO';
    String report_type = 'DESNAGGING';
    String unitNumber = '123';

    Test.startTest();
    String result = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, status, report_type, unitNumber);
    System.assert(result.containsIgnoreCase('Report uploaded successfully'), 'Expected successful upload for CHO_DESNAGGING');
    Test.stopTest();
}
    @isTest
static void testInvalidInspectorEmail() {
    String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Test PDF'));
    String fileName = 'invalidInspector';
    String fileType = 'application/pdf';
    String inspector = 'nonexistent@example.com';
    String snagCount = '1';
    String status = 'QA';
    String report_type = 'SNAGGING';
    String unitNumber = '123';

    Test.startTest();
    String result = DeSnaggingProcess.deSnaggingReport(base64Pdf, fileName, fileType, inspector, snagCount, status, report_type, unitNumber);
    System.assertEquals(HandoverConstants.INSPECTOR_NOT_FOUND, result);
    Test.stopTest();
}


}