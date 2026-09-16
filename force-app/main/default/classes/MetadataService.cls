/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : MetadataService
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
*****************************************************************************************************/
public class MetadataService {
    
    private static MetadataService instance;
    
    private MetadataService() {
        
    }
    
    public static MetadataService getInstance() { 
        if(instance == null) {
            instance = new MetadataService();
        }
        return instance;
    }
    
    public APISetting__mdt getAPISettingDetails(string developerName){
        return APISetting__mdt.getInstance(developerName); 
    }
    
    public Integration_Details__mdt getIntegrationDetails(string developerName){
        return Integration_Details__mdt.getInstance(developerName); 
    }
    
    public Date getAppSettingDateValue(string developerName){
        return AppSetting__mdt.getInstance(developerName).DateValue__c; 
    }
    
    public String getAppSettingTextValue(string developerName){
        return AppSetting__mdt.getInstance(developerName).TextValue__c; 
    }
    
    public Integer getAppSettingNumberValue(string developerName){
        return Integer.valueOf(AppSetting__mdt.getInstance(developerName).NumberValue__c); 
    }
    
    public Boolean getAppSettingBooleanValue(string developerName){
        return AppSetting__mdt.getInstance(developerName).BooleanValue__c;
    }
    
    public String getCountryCodeByNationality(string nationality){
        List<Country__mdt> countryList = [SELECT Id, CountryCode__c, Nationality__c FROM Country__mdt WHERE Nationality__c = :nationality];
        return (countryList != NULL && !countryList.isEmpty()) ? countryList[0].CountryCode__c : NULL;
    }

    public String getNationalityInArabic(string nationality){
        List<NationalityApi__mdt> nationalityList = [SELECT Id, CountryCode__c, NationalityInEnglish__c, NationalityInArabic__c 
                                                        FROM NationalityApi__mdt 
                                                        WHERE NationalityInEnglish__c = :nationality];
        return (nationalityList != NULL && !nationalityList.isEmpty()) ? nationalityList[0].NationalityInArabic__c : NULL;
    }
    
    public List<Document_Set_Up_Config__mdt> getDocumentSetupConfigs(String sobjectApiName) {
        return [SELECT Id, MasterLabel FROM Document_Set_Up_Config__mdt WHERE Sobject_lkup_Api_Name__c = :sobjectApiName];
    }
    
    public List<BFMSubcategoryPriorityMapping__mdt> getBFMSubcategoryPriorityMapping() {
        return [SELECT SubCategory__c, Priority__c FROM BFMSubcategoryPriorityMapping__mdt];
    }
    
    public Map<String, LeadCategoryMapping__mdt> getLeadCategoryMapping() {
        Map<String, LeadCategoryMapping__mdt> mappingData = new Map<String, LeadCategoryMapping__mdt>();
        
        for (LeadCategoryMapping__mdt record : [SELECT LeadTeam__c, LeadSource__c, LeadCategory__c, LeadType__c FROM LeadCategoryMapping__mdt]) {
            mappingData.put(record.LeadTeam__c + '|' + record.LeadSource__c, record);
        }
        return mappingData;
    }
    // Rushikesh : To get the IBAN Country Metadata Based on Country
    public List<BAPP_IBANCountryConfig__mdt> getIBANCountryConfig(String countryName) {
        return [
            SELECT Country__c, CountryCode__c, Length__c
            FROM BAPP_IBANCountryConfig__mdt
            WHERE Country__c = :countryName
            LIMIT 1
        ];
    }
    
    // Shruti : To get the Escalation Metadata Based on Type
    public List<BAPPEscalationDetails__mdt> getBrokerEscalationMetadata() {
        return [
            SELECT Type__c, Escalation_To_Email__c 
            FROM BAPPEscalationDetails__mdt
            WHERE Type__c IN ('RFI', 'Registration')
            LIMIT 1
        ];
    }
     public BAPPSMSTemplate__mdt getActiveSMSTemplateByName(String templateName) {
        List<BAPPSMSTemplate__mdt> templates = [
            SELECT Message_Body__c
            FROM BAPPSMSTemplate__mdt
            WHERE Template_Name__c = :templateName
            AND IsActive__c = true
            LIMIT 1
        ];
    
        return templates.isEmpty() ? null : templates[0];
    }

    public List<Integration_Details__mdt> getIntegrationDetailsMetadataByDevName(String devName) { 
        return [SELECT End_Point_URL__c, Api_Key__c, MethodType__c FROM Integration_Details__mdt Where DeveloperName=:devName];
    }
    
    public List<DLP_Resolution_Settings__mdt> getDLPResolutionSettings() {
        return [SELECT Resolution_Priority__c, Repair_Resolution__c,Is_Business_Hours__c,Business_Hours_Id__c,Repair_Resolution_SLA_Type__c, Replace_Resolution__c, Replace_Resolution_SLA_Type__c FROM DLP_Resolution_Settings__mdt];
    }
}