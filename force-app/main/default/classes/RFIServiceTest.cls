@isTest
public class RFIServiceTest {
	@testSetup static void setup() {
        //create Broker Application
        BrokerApplication__c brokerApplicationObj = TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
        
        RFI__c rfiObj = new RFI__c();
        rfiObj.RFIComments__c = 'Test Comments';
        rfiObj.RFI_Reason__c = 'Others';
        rfiObj.BrokerApplication__c = brokerApplicationObj.Id;
		insert rfiObj;
    }
    
    @isTest
    static void testContactEmailBatch() {
        
        List<RFI__c> rfiList = [Select Id, RFIComments__c from RFI__c where RFI_Reason__c = 'Others' LIMIT 1];
        
        Test.startTest();
        List<RFI__c> listRFIUpdated = RFIService.getInstance().updateRFIRecords(rfiList);
        Test.stopTest();
    }
}