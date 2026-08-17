@isTest
public class LeadTaskCreationHandlerTest {
    @isTest
    static void testMethod1() {
        // Test for New status
        List<Lead> Llist = new List<Lead>();
        Lead l = new lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
       // l.Lead_Channel__c = 'Online'; 
        Llist.add(l);
        insert Llist; 
        
        Test.startTest();
        leadTaskCreationHandler.createATaskonlead(new List<Id>{Llist[0].Id});
        Test.stopTest();
        
    }
    
    @isTest
    static void testMethod2() {
        // Test for Qualified status
        List<Lead> Llist1 = new List<Lead>();
        Lead l = new lead();
        l.LastName = 'Testclass2';
        l.MobileCountryCode__c = '971';
        l.Status = 'Qualified';
        l.MobilePhone = '37829292030';
        l.Email = 'Testclass2@gmail.com';
       // l.Lead_Channel__c = 'Online';
        l.LeadSource = 'Online';
        l.BuyRent__c = 'Buy';
        l.PropertyUsage__c = 'Residential Sale';
       // l.AreaSqmt__c = '100-150 SQM';
        l.CustomerBudget__c = '300k-650K';
        l.NumberOfBedrooms__c = '1BHK';
        l.UnitType__c = 'Apartment';
       // l.PropertyReadiness__c = '0-12 months';
        l.Project__c = 'Bloom Living';
        Llist1.add(l);
        insert Llist1; 
        
        Test.startTest();
        leadTaskCreationHandler.createATaskonlead(new List<Id>{Llist1[0].Id});
        Test.stopTest();
        
    }
}