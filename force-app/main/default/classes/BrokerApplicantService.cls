/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 26th MAY 2025
* @Description : Service class for Broker Applicant operations including
*                fetching applicant/application details, and utility methods.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment                                                                       
* 1.0       Rushikesh        26th MAY 2025    Initial draft - Service class for applicant record processing and retrieval.
*****************************************************************************************************/
public class BrokerApplicantService {

    private static BrokerApplicantService instance;

    private BrokerApplicantService() {
    }

    public static BrokerApplicantService getInstance() {
        if (instance == null) {
            instance = new BrokerApplicantService();
        }
        return instance;
    }
    public List<BrokerApplicant__c> getExistingApplicantsByApplicationId(Id applicationId) {
        if (String.isBlank(applicationId)) return new List<BrokerApplicant__c>();
        return [
            SELECT Id, BrokerContactRole__c,IsSuperAdmin__c,Title__c, FirstName__c, MiddleName__c, LastName__c, PhoneNumber__c, Email__c,CountryCode__c,Country__c,
                   NationalId__c, NationalIdExpiryDate__c, PassportNumber__c, PassportExpiryDate__c,DateOfBirth__c,
                   Designation__c, ShareHoldingPercentage__c
            FROM BrokerApplicant__c
            WHERE BrokerApplication__c = :applicationId
        ];
    }
    public BrokerApplication__c getApplicationDetails(Id applicationId) {
        if (String.isBlank(applicationId)) return null;
        try {
            return [
                SELECT ApplicationNumber__c, TypeofEstablishment__c
                FROM BrokerApplication__c
                WHERE Id = :applicationId
                LIMIT 1
            ];
        } catch (QueryException e) {
            return null;
        }
    }
    public String getApplicationNumber(Id applicationId) {
        if (String.isBlank(applicationId)) return '';
        
            BrokerApplication__c app = [
                SELECT ApplicationNumber__c,TypeofEstablishment__c
                FROM BrokerApplication__c
                WHERE Id = :applicationId
                LIMIT 1
            ];
            return app != null ? app.ApplicationNumber__c : '';
        }
    public void insertApplicants(List<BrokerApplicant__c> toInsert) {
        if (toInsert != null && !toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    public void updateApplicants(List<BrokerApplicant__c> toUpdate) {
        if (toUpdate != null && !toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    public Map<Id, String> getApplicantNames(Set<Id> applicantIds) {
        Map<Id, String> applicantNameMap = new Map<Id, String>();
        for (BrokerApplicant__c applicant : [SELECT Id, Name FROM BrokerApplicant__c WHERE Id IN :applicantIds]) {
            applicantNameMap.put(applicant.Id, applicant.Name);
        }
        return applicantNameMap;
    }
    
    public Map<Id, String> getApplicationNames(Set<Id> appIds) {
        Map<Id, String> appNameMap = new Map<Id, String>();
        for (BrokerApplication__c app : [SELECT Id, Name FROM BrokerApplication__c WHERE Id IN :appIds]) {
            appNameMap.put(app.Id, app.Name);
        }
        return appNameMap;
    }
    // Fetch applicants by email within a given BrokerApplication
    public List<BrokerApplicant__c> getApplicantsByEmails(String applicationId, Set<String> emails) {
        if (String.isBlank(applicationId) || emails.isEmpty()) return new List<BrokerApplicant__c>();
        return [
            SELECT Id, Email__c
            FROM BrokerApplicant__c
            WHERE BrokerApplication__c = :applicationId
            AND Email__c IN :emails
        ];
    }
    // Fetch a single Broker Applicant record by Id
    public BrokerApplicant__c getApplicantById(Id applicantId) {
        if (String.isBlank(applicantId)) return null;
    
        List<BrokerApplicant__c> applicants = [
            SELECT Id, BrokerApplication__c
            FROM BrokerApplicant__c
            WHERE Id = :applicantId
            LIMIT 1
        ];
        
        return (!applicants.isEmpty()) ? applicants[0] : null;
    }
    public List<BrokerApplicant__c> getApplicantsByApplicationIds(Set<Id> appIds) {
        if (appIds == null || appIds.isEmpty()) return new List<BrokerApplicant__c>();
    
        return [
            SELECT Id, FirstName__c, LastName__c, MiddleName__c,
                   Email__c, PhoneNumber__c, CountryCode__c, Country__c,
                   DateOfBirth__c, BrokerContactRole__c,
                   ShareHoldingPercentage__c, PassportExpiryDate__c, PassportNumber__c,
                   NationalID__c, NationalIDExpiryDate__c,
                   Title__c, Designation__c,
                   IsAdmin__c, IsAgent__c, IsOwner__c, IsCEO__c,
                   IsSuperAdmin__c, isFinancialAdmin__c, IsPartner__c,
                   TypeofEstablishment__c,
                   LeadConversionallowed__c,
                   IsAuthorizedSignatory__c,
                   BrokerApplication__c
            FROM BrokerApplicant__c
            WHERE BrokerApplication__c IN :appIds
        ];
    }
    public List<BrokerApplicant__c> getPartnerAndOwnerApplicantsForSMS(Set<Id> applicationIds) {
        if (applicationIds == null || applicationIds.isEmpty()) {
            return new List<BrokerApplicant__c>();
        }
    
        return [
            SELECT Id,
                   BrokerApplication__c,
                   BrokerContactRole__c,
                   PhoneNumber__c,
                   CountryCode__c
            FROM BrokerApplicant__c
            WHERE BrokerApplication__c IN :applicationIds
            AND BrokerContactRole__c INCLUDES ('Partner', 'Owner')
            AND PhoneNumber__c != null
            AND CountryCode__c != null
        ];
    }


}