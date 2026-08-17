@IsTest
public class markQualifedLeadstatusTest {
    @IsTest
    static void Testmethod1(){
        Lead l = new Lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
        l.Lead_Channel__c = 'Call';
        l.BuyRent__c = 'Buy';
        l.PropertyUsage__c = 'Residential Sale';
        l.AreaSqmt__c = '35-65 SQM';
        l.CustomerBudget__c = '300K-650K';
        l.NumberOfBedrooms__c = '1BHK';
        l.UnitType__c = 'Apartment';
        l.PropertyReadiness__c = 'Offplan';
        l.Project__c = 'Bloom Living';
        Test.startTest();
        try {
            insert l;
        } catch (exception e) {
            
        }
        try {
            markQualifedLeadstatus.markQualifiedStatus(String.valueOf(l.Id));
        } catch (exception e) {
            
        }
        Test.stopTest();   
    }
}