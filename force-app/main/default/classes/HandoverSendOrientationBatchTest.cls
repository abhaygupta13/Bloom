@isTest
private class HandoverSendOrientationBatchTest {
    
    @isTest
    static void testHandoverSendOrientationBatch() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project;
        
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
        );
        insert unit;
        
        Handover__c handover = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            HO_Agent_Assigned_User__c = UserInfo.getUserId()
        );
        insert handover;
        
        Event evn = new Event();
        evn.WhatId = handover.Id;
        evn.Subject = 'Other';
        evn.StartDateTime = DateTime.newInstance(2024, 6, 20, 8, 43, 38); 
        evn.EndDateTime = DateTime.newInstance(2024, 6, 22, 8, 43, 38); 
        evn.CurrencyIsoCode ='AED';
        insert evn;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Full Guideline Document';
        contentVersion.PathOnClient = 'FullGuidelineDocument.pdf';
        contentVersion.VersionData = Blob.valueOf('Full Guideline Document');
        insert contentVersion;
        system.debug('contentVersion'+contentVersion);
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = : contentVersion.Id];
        system.debug('con version'+con);
        
        Document__c dc= new Document__c();
        dc.Document_Name__c = 'Full Guideline Document';
        dc.Handover__c = handover.Id;
        dc.ContentDocumentId__c = con.ContentDocumentId;
        dc.Content_Version_Id__c = con.Id;
        insert dc;

        System.debug('DCCCCC=====> ' + dc);
        
        List<Id> handoverIds = new List<Id>{handover.Id};
        
        HandoverSendOrientationBatch batch = new HandoverSendOrientationBatch(handoverIds);

        Test.startTest();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        /*
        Handover__c updatedHandover = [SELECT Id, Unit_is_Ready__c, Is_Orientation_Letter_Sent__c, Home_Orientation_Invitation_Date__c, Sub_Status__c FROM Handover__c WHERE Id = :testHandover.Id];
        
        System.assertEquals(true, updatedHandover.Unit_is_Ready__c, 'Unit_is_Ready__c should be true.');
        System.assertEquals(true, updatedHandover.Is_Orientation_Letter_Sent__c, 'Is_Orientation_Letter_Sent__c should be true.');
        System.assertEquals(Date.Today(), updatedHandover.Home_Orientation_Invitation_Date__c, 'Home_Orientation_Invitation_Date__c should be today\'s date.');
        System.assertEquals(Constants.Handover_Sub_Status_Home_Orientation_Sent, updatedHandover.Sub_Status__c, 'Sub_Status__c should be set to Handover_Sub_Status_Home_Orientation_Sent.');*/
        
    }
    
    @isTest
    static void testHandoverSendOrientationBatchException() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project;
        
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
        );
        insert unit;
        
        Handover__c handover = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available'
           // HO_Agent_Assigned_User__c = UserInfo.getUserId()
        );
        insert handover;
        
        Event evn = new Event();
        evn.WhatId = handover.Id;
        evn.Subject = 'Other';
        evn.StartDateTime = DateTime.newInstance(2024, 6, 20, 8, 43, 38); 
        evn.EndDateTime = DateTime.newInstance(2024, 6, 22, 8, 43, 38); 
        evn.CurrencyIsoCode ='AED';
        insert evn;
        
        List<Id> handoverIds = new List<Id>{handover.Id};
        
        HandoverSendOrientationBatch batch = new HandoverSendOrientationBatch(handoverIds);

        Test.startTest();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        /*
        Handover__c updatedHandover = [SELECT Id, Unit_is_Ready__c, Is_Orientation_Letter_Sent__c, Home_Orientation_Invitation_Date__c, Sub_Status__c FROM Handover__c WHERE Id = :testHandover.Id];
        
        System.assertEquals(true, updatedHandover.Unit_is_Ready__c, 'Unit_is_Ready__c should be true.');
        System.assertEquals(true, updatedHandover.Is_Orientation_Letter_Sent__c, 'Is_Orientation_Letter_Sent__c should be true.');
        System.assertEquals(Date.Today(), updatedHandover.Home_Orientation_Invitation_Date__c, 'Home_Orientation_Invitation_Date__c should be today\'s date.');
        System.assertEquals(Constants.Handover_Sub_Status_Home_Orientation_Sent, updatedHandover.Sub_Status__c, 'Sub_Status__c should be set to Handover_Sub_Status_Home_Orientation_Sent.');*/
        
    }
}