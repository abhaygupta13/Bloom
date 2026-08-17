@IsTest
public class HandoverBCCAndOrientationEmailBatchTest {
    
    @TestSetup
    static void setupTestData() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project;
        
         Project__c project2 = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project2;
        
        // Create a Unit
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
        );
        insert unit;

         Unit__c unit2 = new Unit__c(
            Name = 'Unit Test',
            SAP_Unit_Number__c = 'SAP001',
            Status__c = 'Available'
        );
        insert unit2;
        
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@example.com';
        insert acc;
        
        Account acc2 = new Account();
        acc2.LastName = 'Test Acc2';
        acc2.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc2.PersonEmail = 'test@example.com';
        insert acc2;
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Unit__c = unit.Id;
        sc.Account__c = acc.Id;
        insert sc;
        
        SalesOrder__c sc1 = new SalesOrder__c();
        sc1.Name ='Test sales order 2';
        sc1.Unit__c = unit2.Id;
        sc1.Account__c = acc2.Id;
        insert sc1;
        
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        update unit;
        
        unit2.Active_Sales_Order__c = sc1.Id;
        unit2.RelatedSalesOrder__c = sc1.Id;
        update unit2;
        
        // Create a Round Robin for Handover CRM
        Round_Robins__c rr = new Round_Robins__c(
            Name = 'Handover CRM',
            Team__c = 'CRM',
            Assigned_To__c = String.valueOf(5),
            Project__c = project.Id,
            Sobject__c = 'Handover__c'
        );
        insert rr;
        
         Round_Robins__c rr2 = new Round_Robins__c(
            Name = 'Handover CRM 2',
            Team__c = 'CRM',
            Assigned_To__c = String.valueOf(1),
            Project__c = project2.Id,
            Sobject__c = 'Handover__c'
        );
        insert rr2;
        
        Profile profileCRM = [SELECT Id FROM Profile WHERE Name = 'CRM Operations'];
        
        User userRecord = new User(
            Alias = 'zaki',
            Email = 'zakial@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki.al.bakri@example.com'
        );
        insert userRecord;
        
        User userRecord2 = new User(
            Alias = 'zaki2',
            Email = 'zakial2@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri 2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki2.al.bakri@example.com'
        );
        insert userRecord2;
        
         User userRecord3 = new User(
            Alias = 'zaki3',
            Email = 'zakial2@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri 2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki3.al.bakri@example.com'
        );
        insert userRecord3;
        
         User userRecord4 = new User(
            Alias = 'zaki4',
            Email = 'zakial2@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri 2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki4.al.bakri@example.com'
        );
        insert userRecord4;
        
        // Create Round Robin Users
        Round_Robin_User__c rrUser1 = new Round_Robin_User__c(
            Name = 'Hani Zaki Al Bakri - SM',
            Round_Robin__c = rr.Id,
            Round_Robin_ID__c = 1,
            Total_Open_Count__c = 10,
            User__c = userRecord.Id
        );
        insert rrUser1;
        
        Round_Robin_User__c rrUser2 = new Round_Robin_User__c(
            Name = 'Zaki Al Bakri - SM',
            Round_Robin__c = rr2.Id,
            Total_Open_Count__c = 10,
            User__c = userRecord2.Id
        );
        insert rrUser2;
        
         Round_Robin_User__c rrUser3 = new Round_Robin_User__c(
            Name = 'Zaki Al Bakri - SM3',
            Round_Robin__c = rr2.Id,
            Total_Open_Count__c = 9,
            User__c = userRecord3.Id
        );
        insert rrUser3;
        
         Round_Robin_User__c rrUser4 = new Round_Robin_User__c(
            Name = 'Zaki Al Bakri - SM34',
            Round_Robin__c = rr2.Id,
            Total_Open_Count__c = 10,
            User__c = userRecord4.Id
        );
        insert rrUser4;
        
        // Create a Handover record
        Handover__c handover1 = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            account__c = acc.id,
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            HO_Agent_Assigned_User__c = userRecord.Id,
            UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false
        );
        insert handover1;
        
        Handover__c handover2 = new Handover__c(
            Name = 'Test Handover2',
            Customer_Email__c = 'test@example.com',
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit2.Id,
             account__c = acc.id,
            Project__c = project2.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            HO_Agent_Assigned_User__c = userRecord.Id,
             UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false
        );
        insert handover2;
         Handover__c handover3 = new Handover__c(
            Name = 'Test Handover3',
            Customer_Email__c = 'test@example.com',
            Is_Orientation_Letter_Sent__c = true,
            Is_BCC_Announcement_Sent__c = true,
            account__c = acc.id,
            Unit__c = unit2.Id,
            Project__c = project2.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            HO_Agent_Assigned_User__c = userRecord.Id,
             UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false
        );
        insert handover3;

        
        // Create ContentVersion and associated Document__c record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Full Guideline Document',
            PathOnClient = 'FullGuidelineDocument.pdf',
            VersionData = Blob.valueOf('Full Guideline Document')
        );
        insert contentVersion;
        
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
         // Create ContentVersion and associated Document__c record
        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'QA Desnagging Report',
            PathOnClient = 'QA Desnagging Report.pdf',
            VersionData = Blob.valueOf('QA Desnagging Report')
        );
        insert contentVersion1;
        
     
         ContentVersion con1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id];
        
        Document__c document = new Document__c(
            Document_Name__c = 'Full Guideline Document',
            Handover__c = handover1.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document;
        Document__c document2 = new Document__c(
            Document_Name__c = 'Full Guideline Document',
            Handover__c = handover2.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document2;
        
         Document__c document3 = new Document__c(
            Document_Name__c = 'QA Desnagging Report',
            Handover__c = handover3.Id,
            ContentDocumentId__c = con1.ContentDocumentId,
            Content_Version_Id__c = con1.Id
        );
        insert document3;
        
         Document__c document4 = new Document__c(
            Document_Name__c = 'CHO Desnagging Report',
            Handover__c = handover3.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document4;
         Document__c document5 = new Document__c(
            Document_Name__c = 'SOA',
            Handover__c = handover3.Id,
            ContentDocumentId__c = con.ContentDocumentId,
            Content_Version_Id__c = con.Id
        );
        insert document5;
    
           }
    
    @IsTest
    static void testBCCBatch() {
        List<Id> unitIds = new List<Id>();
         List<Id> handoverIds = new List<Id>();
        for (Handover__c ho : [SELECT Id,Unit__c FROM Handover__c LIMIT 5]) {
            unitIds.add(ho.Unit__c);
             handoverIds.add(ho.Id);
        }
        
        HandoverBCCAndOrientationEmailBatch batch = new HandoverBCCAndOrientationEmailBatch(unitIds, HandoverConstants.BCC);
         HandoverBCCAndOrientationEmailBatch batch2 = new HandoverBCCAndOrientationEmailBatch(handoverIds, HandoverConstants.Orientation);
         List<Id>nocids = new List<Id>();
         
        
       
         Database.executeBatch(batch2);
        Database.executeBatch(batch);
            
     
        for (Handover__c ho : [SELECT Id,Name FROM Handover__c where name='Test Handover3']) {
            ho.Is_BCC_Announcement_Sent__c=true;
            update ho;
            nocids.add(ho.Id);
            
        }
             HandoverBCCAndOrientationEmailBatch batch3 = new HandoverBCCAndOrientationEmailBatch(nocids,HandoverConstants.NOC);
         
         
        Database.executeBatch(batch3);
        
      
    }
    @IsTest
    static void testNocBatch() {
       
         List<Id>nocids = new List<Id>();
        Handover__c  ho = [SELECT Id,Name FROM Handover__c Limit 1];
       
            nocids.add(ho.Id);
            
        
          Document__c document3 = new Document__c(
            Document_Name__c = 'QA Desnagging Report',
            Handover__c = ho.Id         
        );
        insert document3;
         List<Document__c> QADeSnagDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c = 'QA Desnagging Report' AND Handover__c =: ho.Id LIMIT 1];
            System.debug('QADeSnagDocList'+QADeSnagDocList);
            if(QADeSnagDocList.size()>0){
                CustomDocManageController.addFilesonRecordCreate('base64Pdf', 'hello'+'pdf', QADeSnagDocList[0]);
            }
 
             HandoverBCCAndOrientationEmailBatch batch3 = new HandoverBCCAndOrientationEmailBatch(nocids,HandoverConstants.NOC);
         
         
        Test.startTest();
         Database.executeBatch(batch3);
    
        
        
        
        
        Test.stopTest();
        
       
    }
    
   
}