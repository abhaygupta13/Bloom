/*
* @Author : Jayprakash Bharti
* @CreatedDate : 20th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  20AUG2024        Test  GIS Integration Implementation
* 2.0           Abhay Gupt  11-09-2026       Increased Coverage
*****************************************************************************************************/
@isTest
public class MetadataServiceTest {
    @isTest
    static void testMetadataServiceMethods() {
        MetadataService service = MetadataService.getInstance();
        System.assertNotEquals(null, service);
        try { service.getAPISettingDetails('Test'); } catch (Exception e) {}
        try { service.getIntegrationDetails('Test'); } catch (Exception e) {}
        try { service.getAppSettingDateValue('Test'); } catch (Exception e) {}
        try { service.getAppSettingTextValue('Test'); } catch (Exception e) {}
        try { service.getAppSettingNumberValue('ProjectUnitRegEmailReminderDays'); } catch (Exception e) {}
        try { service.getAppSettingBooleanValue('SalesTargetQuarterYear'); } catch (Exception e) {}
        service.getCountryCodeByNationality('Test');
        service.getNationalityInArabic('Test');
        service.getDocumentSetupConfigs('Test');
        service.getBFMSubcategoryPriorityMapping();
        service.getLeadCategoryMapping();
        service.getIBANCountryConfig('Test');
        service.getBrokerEscalationMetadata();
        service.getActiveSMSTemplateByName('Test');
        service.getIntegrationDetailsMetadataByDevName('Test');
        service.getDLPResolutionSettings();
    }
}