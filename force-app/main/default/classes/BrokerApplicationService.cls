/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 26th MAY 2025
* @Description : Service class for handling operations related to BrokerApplication__c such as fetching,
*                updating application records, managing Drawloop state, and calculating escalation dates.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh       26th MAY 2025   Initial draft - Handles core data logic and utility methods
*                                           for BrokerApplication__c.
*****************************************************************************************************/
public class BrokerApplicationService {
    
    private static BrokerApplicationService instance;

    private BrokerApplicationService() { }

    public static BrokerApplicationService getInstance() {
        if (instance == null) {
            instance = new BrokerApplicationService();
        }
        return instance;
    }
	// To Fetch Application By Id
    public BrokerApplication__c getApplicationById(Id applicationId) { 
        return [
            SELECT Id, ApplicationNumber__c, ApprovalStatus__c, InApproval__c, ApprovalComments__c,
                   IsAgreementExpired__c, IsTradeLicenseExpired__c, RejectionComments__c, IsRFIUpdated__c,
                   IsSuspended__c, SuspensionReason__c, SuspensionTenure__c, IsTerminated__c, TerminationReason__c,CurrentScreen__c,
                   RfiRaisedBy__c, RfiComments__c, RfiCount__c,Drawloop_Next__c,Drawloop_Next_1__c,isRequestForReAgreement__c,
                   Name, TypeOfEstablishment__c, TradeLicenseNumber__c, TradeLicenseExpiryDate__c,
                   CommercialLicenseNumber__c, CommercialLicenseExpiryDate__c, AgencyType__c, RegisteredCountry__c,
                   RegisteredState__c, RegisteredCity__c, RegisteredEmirate__c, AgencyEmail__c,
                   ORNADM__c, LicenseType__c, IsVATRegistered__c, TaxRegistrationNumber__c, VATUndertakingIssueDate__c,
                   AddressLine01__c, AddressLine02__c, Country__c, Emirate__c, City__c,
                   ZipCodePOBoxNumber__c, CompanyPhone_Number__c, CountryCode__c,BBMId__c,
                   BeneficiaryName__c, Account_Number__c, BankCountry__c, BankNameValue__c, BankBranchAddress__c,
                   IBAN__c, SwiftCode__c, AgreementInitiationdate__c
            FROM BrokerApplication__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
    }
    
    public List<BrokerApplication__c> getApplicationByIds(Set<Id> ids) {
    return [SELECT Id, TypeOfEstablishment__c, Name,IsRFIUpdated__c, ApprovalStatus__c,ApplicationNumber__c FROM BrokerApplication__c WHERE Id IN :ids];
	}
    
    // To Fetch Application details by ApplicationNumber
    public BrokerApplication__c getBrokerApplicationByNumber(String appNumber) {
            List<BrokerApplication__c> apps =
            [SELECT Id, ApplicationNumber__c, ApprovalStatus__c, InApproval__c, ApprovalComments__c,
                   IsAgreementExpired__c, IsTradeLicenseExpired__c, RejectionComments__c, IsRFIUpdated__c,
                   IsSuspended__c, SuspensionReason__c, SuspensionTenure__c, IsTerminated__c, TerminationReason__c,CurrentScreen__c,
                   RfiRaisedBy__c, RfiComments__c, RfiCount__c,isRequestForReAgreement__c,
                   Name, TypeOfEstablishment__c, TradeLicenseNumber__c, TradeLicenseExpiryDate__c,
                   CommercialLicenseNumber__c, CommercialLicenseExpiryDate__c, AgencyType__c, RegisteredCountry__c,
                   RegisteredState__c, RegisteredCity__c, RegisteredEmirate__c, AgencyEmail__c,
                   ORNADM__c, LicenseType__c, IsVATRegistered__c, TaxRegistrationNumber__c, VATUndertakingIssueDate__c,
                   AddressLine01__c, AddressLine02__c, Country__c, Emirate__c, City__c,
                   ZipCodePOBoxNumber__c, CompanyPhone_Number__c, CountryCode__c,
                   BeneficiaryName__c, Account_Number__c, BankCountry__c,BankNameValue__c , BankBranchAddress__c,
                   IBAN__c, SwiftCode__c,(SELECT Id, RFIComments__c,RFI_Reason__c FROM RFIs__r ORDER BY CreatedDate DESC)
            FROM BrokerApplication__c
            WHERE ApplicationNumber__c = :appNumber
            LIMIT 1
            ];
        return apps.isEmpty() ? null : apps[0];
    }
    // Insert Update
    public void insertApplications(List<BrokerApplication__c> apps) {
        if (apps != null && !apps.isEmpty()) {
            insert apps;
        }
    }
    public void updateApplications(List<BrokerApplication__c> apps) {
        if (apps != null && !apps.isEmpty()) {
            update apps;
        }
    }
    /**
     * Updates a list of BrokerApplication__c records.
     */
    public void updateBrokerApplications(List<BrokerApplication__c> brokerApplications) {
        if (brokerApplications != null && !brokerApplications.isEmpty()) {
            update brokerApplications;
        }
    }

    /**
     * Updates Drawloop_Next_1__c field of a single BrokerApplication__c record to blank.
     */
    public void resetDrawloopNext(String recordId) {
        if (String.isNotBlank(recordId)) {
            BrokerApplication__c baReset = new BrokerApplication__c(
                Id = recordId,
                Drawloop_Next_1__c = ''
            );
            update baReset;
        }
    }
    /**
     * Updates Drawloop_Next_1__c field of a single BrokerApplication__c record to provided value.
     */
    public void updateDrawloopNext(String recordId, String drawloopNextVal) {
        if (String.isNotBlank(recordId) && String.isNotBlank(drawloopNextVal)) {
            BrokerApplication__c baUpdate = new BrokerApplication__c(
                Id = recordId,
                Drawloop_Next_1__c = drawloopNextVal
            );
            update baUpdate;
        }
    }
    
     public List<BrokerApplication__c> updateBrokerApplicationsWithoutTrigger(List<BrokerApplication__c> brokerAppList) {
        if (brokerAppList != null && !brokerAppList.isEmpty()) {
            BrokerApplicationTriggerHandler.isTriggerDisabled = true;
            update brokerAppList;
            BrokerApplicationTriggerHandler.isTriggerDisabled = false;
        }
        
        return brokerAppList;
    }
}