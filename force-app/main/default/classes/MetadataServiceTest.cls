/*
* @Author : Jayprakash Bharti
* @CreatedDate : 20th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  20AUG2024        Test  GIS Integration Implementation
*****************************************************************************************************/
@IsTest
private class MetadataServiceTest {
    private static final string SALES_TARGET_QUARTER_YEAR { get { return 'SalesTargetQuarterYear'; } }
    private static final string REMINDER_DAYS { get { return 'ProjectUnitRegEmailReminderDays'; } }
    static testmethod void testMethod1(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Integration_Details__mdt objIntegrationdetails = objMetadataService.getIntegrationDetails('GISIntegrationSetting');
        string objAppSettingMdt = objMetadataService.getAppSettingTextValue('LeadDuplicateRuleId');
    }
    
    static testmethod void testGetCountryCodeByNationality(){
        MetadataService objMetadataService = MetadataService.getInstance();
        objMetadataService.getCountryCodeByNationality('Indian');
    }

    @isTest
    private static void testGetBFMSubcategoryPriorityMapping(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Test.startTest();
            List<BFMSubcategoryPriorityMapping__mdt> mappingList = objMetadataService.getBFMSubcategoryPriorityMapping();
        Test.stopTest();
        Assert.areEqual(true, !mappingList.isEmpty(), 'Record not found');
    }
    
    @isTest
    private static void testAppSettingMetadata(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Test.startTest();
            Integer numericValue = objMetadataService.getAppSettingNumberValue(REMINDER_DAYS);
        	Boolean booleanValue = objMetadataService.getAppSettingBooleanValue(SALES_TARGET_QUARTER_YEAR);
        Test.stopTest();
    }
    
    @isTest
    private static void testGetLeadCategoryMapping(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Test.startTest();
        Map<String, LeadCategoryMapping__mdt> leadCategoryMap = objMetadataService.getLeadCategoryMapping();
        Test.stopTest();
    }
    //Shruti
	@isTest
    private static void testDocumentSetupConfigs(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Test.startTest();
            List<Document_Set_Up_Config__mdt> mappingList = objMetadataService.getDocumentSetupConfigs('Handover__c');
        Test.stopTest();
        Assert.areEqual(true, !mappingList.isEmpty(), 'Record not found');
    }
    //Shruti
    @isTest
    private static void testLeadCategoryMapping(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Test.startTest();
            Map<String, LeadCategoryMapping__mdt> mappingList = objMetadataService.getLeadCategoryMapping();
        Test.stopTest();
        Assert.areEqual(true, !mappingList.isEmpty(), 'Record not found');
    }
	//Shruti    
    @isTest
    private static void testIBANCountryConfig(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Test.startTest();
            List<BAPP_IBANCountryConfig__mdt> mappingList = objMetadataService.getIBANCountryConfig('United Arab Emirates');
        Test.stopTest();
        Assert.areEqual(true, !mappingList.isEmpty(), 'Record not found');
    }
    //Shruti
    @isTest
    private static void testBrokerEscalationDetails(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Test.startTest();
            List<BAPPEscalationDetails__mdt> mappingList = objMetadataService.getBrokerEscalationMetadata();
        Test.stopTest();
        Assert.areEqual(true, !mappingList.isEmpty(), 'Record not found');
    }
}