/*****************************************************************************************
Class       : LeadService
Author      : Biswajeet
Description : Lead service class
test Class: LeadServiceTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public inherited sharing  class LeadService {
    
    private static final string LEAD_STATUS_CLOSED { get { return 'Closed'; } }
    
    private static LeadService instance;
    
    private LeadService() {
    }
    
    public static LeadService getInstance() { 
        if(instance == null) {
            instance = new LeadService();
        }
        return instance;
    }
    
    public List<Lead> getLeadByIds(Set<Id> leadIds){
        return [SELECT Id, Name, Email, MobilePhone, nationality__c,LeadNumber__c, EmiratesID__c,
                Passport_Number__c, Emirates_Id__c, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name, Status,
                CustomerType__c, FirstName, LastName, EmiratesIDExpiryDate__c, Company,
                ResidentStatus__c, CustomerSubType__c, Street, NameArabic__c, PostalCode,
                City, Country, Latitude, Longitude, CountryCode, State, StateCode, 
                BrokerAgency__c, BrokerAgency__r.Name, BrokerAgent__c, BrokerAgent__r.Name,BudgetRangeFrom__c,
                LeadSource, Phone, GenderIdentity, Birthdate__c, CreatedById,BudgetRangeTo__c,
                OwnerId, Owner.Name, Owner.Email, Owner.Profile.Name, Owner.Profile.Id, ConvertedDate,
                IsConverted, ConvertedOpportunity.OpportunityNumber__c, RoundRobinNumber__c, LeadTeam__c,
                MobileCountryCode__c, MobilePhoneNumber__c, PhoneCountryCode__c,
                PhoneNumber__c,IsDraftLead__c,LastModifiedById,Project__c, ContactCentreLeadStatus__c, BusinessHour__c,
                LeadManagerStatus__c, LeasingDocumentsReceived__c,MaritalStatus__c,ReshuffleCount__c
                FROM Lead WHERE Id IN :leadIds ORDER BY CreatedDate DESC];
    }
    
    public Lead getLeadById(Id leadId){
        return [SELECT Id,Salutation,FirstName,MiddleName, LastName, Name, Email, MobilePhone, nationality__c, RecordTypeId,Unit__r.Name,EmploymentStatus__c,CompanyIndustry__c,YearsOfEmployment__c,CompanyEmirates__c,
                TradeLicenseNumber__c, RegistrationAuthority__c, EmiratesID__c, Gender__c,AnnualIncome__c,CompanyName__c,BPType__c,SourceOfFunds__c,
                Passport_Number__c, Emirates_Id__c, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name, Status, PropertyUsage__c, Comments__c,TaxRegistrationNumber__c,
                CustomerType__c,  EmiratesIDExpiryDate__c, Company, Project__c, BuyRent__c, UnitType__c, SecondaryLeadSource__c,
                ResidentStatus__c, CustomerSubType__c, Street, NameArabic__c, PostalCode, CustomerBudget__c, SecondaryLeadSubSource__c,
                City, Country, Latitude, Longitude, CountryCode, State, StateCode, AreaSqmt__c, BrokerAgent__c,LeadNumber__c,
                BrokerAgency__c, LeadSource, Phone, GenderIdentity, Birthdate__c,BudgetRangeFrom__c,BudgetRangeTo__c, NumberOfBedrooms__c, lead_channel__c,
                OwnerId, Owner.Name, Owner.Email, Owner.Profile.Name, ConvertedDate, PropertyReadiness__c, leadsubsource__c,
                IsConverted,ConvertedOpportunity.OpportunityNumber__c,MobileCountryCode__c, PreferredCommunicationMethodology__c, ADHAType__c, BusinessHour__c,
                MobilePhoneNumber__c, PhoneCountryCode__c, PhoneNumber__c,LeadTeam__c,Position__c,ContactCentreLeadStatus__c, LeadManagerStatus__c,LeasingDocumentsReceived__c,MaritalStatus__c,ReshuffleCount__c
                FROM Lead WHERE Id = :leadId];
    }
    
    public List<Lead> getLeadByIdsAndCreatedByIds(Set<Id> leadIds, Set<Id> createdByIds){
        return [SELECT Id, Name, Email, UnitType__c, IsCommercialLeasing__c, RoundRobinNumber__c, OwnerId, CreatedById,LeadTeam__c,Project__c
                FROM Lead WHERE Id IN :leadIds AND CreatedById IN :createdByIds];
    }
    public List<Lead> getLeadByCreatedByIds(Set<Id> leadIds,Set<Id> createdByIds, Set<Id> profileIds){
        return [SELECT Id, Name, Email, UnitType__c, IsCommercialLeasing__c, Project__c, RoundRobinNumber__c, OwnerId, CreatedById,IsDraftLead__c,LastModifiedById,LeadTeam__c,ReshuffleCount__c
                FROM Lead WHERE Id IN :leadIds AND (CreatedBy.ProfileId IN :profileIds OR CreatedById IN :createdByIds)];
    }
    
    public List<Lead> getLeadByOwnerId(Set<Id> userSet, List<String> leadManagerStatusList){
        return [SELECT Id, Name, LeadManagerStatus__c, LeadNumber__c, Status, CreatedDate,
                Owner.Name, Owner.Email, Project__c, LeadManagerAssignedDate__c FROM Lead
                WHERE OwnerId IN: userSet AND LeadManagerStatus__c IN: leadManagerStatusList];
    }
    
    public List<Lead> getLeadWithOpenActivity(Set<Id> leadIds){
        return [SELECT Id, Name, OwnerId, IsConverted,ConvertedOpportunityId, Status,ContactCentreLeadStatus__c, LeadManagerStatus__c, LeadTeam__c, FollowUpDate__c, WaitingListDate__c, (SELECT Id,Status,Subject,WhoId FROM Tasks WHERE WhoId IN :leadIds AND Status = 'Open')
                FROM Lead WHERE Id IN :leadIds];
    }
    
    public List<Lead> getLeadWithClosedActivity(Set<Id> leadIds){
        return [SELECT Id, Name, OwnerId, IsConverted,ConvertedOpportunityId, Status,ContactCentreLeadStatus__c, LeadManagerStatus__c, LeadTeam__c, FollowUpDate__c, WaitingListDate__c, (SELECT Id,Status,Subject,WhoId FROM Tasks WHERE WhoId IN :leadIds AND Status = 'Completed' AND (Subject LIKE '%SM - Day%' OR Subject LIKE '%LO - Day%') ORDER BY Subject)
                FROM Lead WHERE Id IN :leadIds];
    }
    
    public List<Lead> getLeadsByADHAApplicationNumber(String applicationNumber){
        return [SELECT Id, ApplicationNumber__c FROM Lead 
                WHERE ApplicationNumber__c = :applicationNumber AND IsConverted = false AND Status != :LEAD_STATUS_CLOSED];
    }
    
    public Lead insertLead(Lead objLead){
        if(objlead != NULL ){
            objLead = insertLeads(new List<Lead>{objLead})[0];
        }
        return objlead;
    }
    
    public Lead updateLead(Lead objLead){
        if(objlead != NULL ){
            objLead = updateLeads(new List<Lead>{objLead})[0];
        }
        return objlead;
    }
    
    public Lead updateLeadWithoutTrigger(Lead objLead){
        if(objlead != NULL ){
            objLead = updateLeadsWithoutTrigger(new List<Lead>{objLead})[0];
        }
        return objlead;
    }
    
    public List<Lead> insertLeads(List<Lead> leadList){
        if(leadList != NULL && !leadList.isEmpty()){
            insert leadList;
        }
        return leadList;
    }
    
    public List<Database.SaveResult> insertLeadsWithoutDuplicateRule(List<Lead> leadList){
        Database.DMLOptions objDML = new Database.DMLOptions();
        objDML.DuplicateRuleHeader.allowSave = true;
        List<Database.SaveResult> srList = Database.insert(leadList, objDML);
        return srList;
    }
    
    public List<Database.SaveResult> updateLeadsWithoutDuplicateRule(List<Lead> leadList){
        Database.DMLOptions objDML = new Database.DMLOptions();
        objDML.DuplicateRuleHeader.allowSave = true;
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        if(!leadList.isEmpty()){
            srList = Database.update(leadList, objDML);
        }
        return srList;
    }
    
    public Database.SaveResult insertLeadWithoutDuplicateRule(Lead objLead){
        Database.SaveResult sr;
        if(objlead != NULL ){
            sr = insertLeadsWithoutDuplicateRule(new List<Lead>{objLead})[0];
        }
        return sr;
    }
    
    public List<Lead> updateLeads(List<Lead> leadList){
        if(leadList != NULL && !leadList.isEmpty()){
            update leadList;
        }
        return leadList;
    }
    
    public List<Lead> updateLeadsWithoutTrigger(List<Lead> leadList){
        if(leadList != NULL && !leadList.isEmpty()){
            LeadTriggerHandler.isTriggerDisabled = true;
            update leadList;
            LeadTriggerHandler.isTriggerDisabled = false;
        }
        return leadList;
    }
    
    public Database.SaveResult updateLeadWithoutDuplicateRule(Lead objLead){
        Database.SaveResult sr;
        if(objlead != NULL ){
            sr = updateLeadsWithoutDuplicateRule(new List<Lead>{objLead})[0];
        }
        return sr;
    }
    //To find Duplicate Leads
    public List<Lead> findDuplicateLead(BAPPLeadGenerationHandler.LeadGenerationRequest req) {
        String strIdCondition = '';
        If(String.isNotBlank(req.leadId)) {
            strIdCondition = 'AND Id != \'' + String.escapeSingleQuotes(req.leadId) + '\' ';
        }
        
        String query = 'SELECT Id FROM Lead WHERE ' +
            'FirstName = \'' + String.escapeSingleQuotes(req.firstName) + '\' ' +
            'AND LastName = \'' + String.escapeSingleQuotes(req.lastName) + '\' ' +
            'AND Email = \'' + String.escapeSingleQuotes(req.email) + '\' ' +
            'AND MobilePhoneNumber__c = \'' + String.escapeSingleQuotes(req.phoneNumber) + '\' ' +
            'AND Status NOT IN (\'Closed\', \'Converted\')';
        
        If(String.isNotBlank(strIdCondition)) {
            query += strIdCondition;
        }
        
        If (String.isNotBlank(req.middleName)) {
            query += ' AND MiddleName = \'' + String.escapeSingleQuotes(req.middleName) + '\'';
        }
        query += ' LIMIT 1';
        return Database.query(query);
    }
    //Search leads
    public List<Lead> getLeadsBySearch(String searchKey, String accountId, String contactId, Integer limitSize, Boolean duplicateSearch) {
        if (String.isBlank(accountId) || String.isBlank(contactId)) {
            return new List<Lead>();
        }
        
        // Check if Contact has privileged role (Admin, AuthorizedSignatoryOfficer, CEO)
        Contact c = ContactService.getInstance().getContactById(contactId);
        Boolean hasPrivilegedAccess = false;
        
        if (c.BrokerContactRole__c != null) {
            List<String> roles = c.BrokerContactRole__c.split(';');
            for (String role : roles) {
                String trimmed = role != null ? role.trim().toLowerCase() : '';
                if (trimmed == 'admin' || trimmed == 'superadmin' || trimmed == 'ceo'|| trimmed == 'partner'|| trimmed == 'owner'|| trimmed == 'authorizedsignatoryofficer') {
                    hasPrivilegedAccess = true;
                    break;
                }
            }
        }
        // Default limit if null or invalid
        Integer effectiveLimit = (limitSize != null && limitSize > 0 && limitSize <= 100) ? limitSize : 100;
        String searchPattern = '%' + (searchKey != null ? searchKey : '') + '%';
        // Construct search pattern
        
        // Common SELECT fields
        String baseQuery = 'SELECT Id, Owner.Profile.Name, FirstName, MiddleName, LastName, Name, Email, MobilePhoneNumber__c,Salutation, ' +
            'BrokerAgency__c, Company, Project__c, UnitType__c,Unit__r.Name, NumberOfBedrooms__c, ' +
            'Status, OwnerId,Owner.Email,Owner.Name, LeadNumber__c, IsConverted, ConvertedOpportunityId,LeadCustomerName__c, ' +
            'Country,MobileCountryCode__c,State, City,Street,PostalCode, LanguagePreference__c, Passport_Number__c, PassportExpiryDate__c, ' +
            'NationalID__c, NationalIDExpiryDate__c, PreferredCommunicationMethodology__c,BrokerAgent__c, Broker_Agent_Name__c, ' +
            'CreatedDate, LastModifiedDate, RecordType.DeveloperName  ';
        
        
        // Build WHERE conditions
        String whereClause = 'FROM Lead WHERE BrokerAgency__c = :accountId ';
        
        if (!hasPrivilegedAccess) {
            whereClause += 'AND BrokerAgent__c = :contactId ';
        }
        // === Case 1: Duplicate search + searchKey IS BLANK ===
        if (duplicateSearch && String.isBlank(searchKey)) {
            // Last 5 unique closed leads
            whereClause += 'AND Status = \'Closed\' ';
            whereClause += 'ORDER BY LastModifiedDate DESC LIMIT :effectiveLimit';
            return Database.query(baseQuery + whereClause);
        }
        
        // === Case 2: Duplicate search + searchKey provided ===
        if (duplicateSearch && !String.isBlank(searchKey)) {
            whereClause += 'AND Status = \'Closed\' ';
            whereClause += 'AND (LeadCustomerName__c LIKE :searchPattern OR Email LIKE :searchPattern) ';
        } else {
            // === Case 3: Non-duplicate search ===
            whereClause += 'AND Status IN (\'New\', \'In Progress\', \'Closed\') ';
            if (!String.isBlank(searchKey)) {
                whereClause += 'AND (LeadCustomerName__c LIKE :searchPattern OR Email LIKE :searchPattern ' +
                    'OR MobilePhoneNumber__c LIKE :searchPattern OR LeadNumber__c LIKE :searchPattern) ';
            }
        }
        
        whereClause += 'ORDER BY LastModifiedDate DESC LIMIT :effectiveLimit';
        
        return Database.query(baseQuery + whereClause);
    }
    //BAPP Filter leads
    public List<Lead> getLeadsByFilters(String accountId,String contactId,List<String> recordTypeDevNames,BAPPGetLeadsHandler.FilterCriteria filter,Boolean hasAccessRole) {
        List<String> whereClauses = new List<String>();
        whereClauses.add('lead_channel__c = \'Broker Portal\'');
        // ===== Base Filters =====
        if (!String.isBlank(accountId)) {
            whereClauses.add('BrokerAgency__c = :accountId');
        }
        // Only filter by agent if NOT admin
        if (!hasAccessRole && !String.isBlank(contactId)) {
            whereClauses.add('BrokerAgent__c = :contactId');
        }
        
        // ===== RecordType Filter =====
        if (recordTypeDevNames != null && !recordTypeDevNames.isEmpty()) {
            whereClauses.add('RecordType.DeveloperName IN :recordTypeDevNames');
        }
        
        // ===== Status Filter =====
        if (filter != null && !String.isBlank(filter.status)) {
            List<String> statuses = new List<String>();
            for (String s : filter.status.split(';')) {
                if (!String.isBlank(s)) statuses.add(s.trim());
            }
            if (!statuses.isEmpty()) {
                whereClauses.add('Status IN :statuses');
            }
        }
        // ===== Sales Manager Filter =====
        if (filter != null && !String.isBlank(filter.salesManagerId)) {
            List<Id> smIds = new List<Id>();
            for (String sm : filter.salesManagerId.split(';')) {
                if (!String.isBlank(sm)) {
                    smIds.add((Id)sm.trim());
                }
            }
            if (!smIds.isEmpty()) {
                whereClauses.add('OwnerId IN :smIds');
            }
        }
        // ===== Updated Date Range Filter =====
        DateTime updatedFrom = (filter != null && filter.updatedOnFrom != null) 
            ? DateTime.newInstance(filter.updatedOnFrom, Time.newInstance(0,0,0,0)) 
            : null;
        
        DateTime updatedTo = (filter != null && filter.updatedOnTo != null) 
            ? DateTime.newInstance(filter.updatedOnTo, Time.newInstance(23,59,59,999)) 
            : null;
        
        if (updatedFrom != null && updatedTo != null) {
            whereClauses.add('LastModifiedDate >= :updatedFrom AND LastModifiedDate <= :updatedTo');
        } else if (updatedFrom != null) {
            whereClauses.add('LastModifiedDate >= :updatedFrom');
        } else if (updatedTo != null) {
            whereClauses.add('LastModifiedDate <= :updatedTo');
        }
        
        // ===== Build Query =====
        String baseQuery = 
            'SELECT Id, Name, FirstName, MiddleName, LastName, Email, MobilePhoneNumber__c,Salutation, ' +
            'LeadNumber__c, BrokerAgency__c, BrokerAgent__c, Company, Project__c, UnitType__c,Unit__r.Name, NumberOfBedrooms__c, ' +
            'Status, OwnerId,Owner.Email,Owner.Name, Owner.Profile.Name, IsConverted, ConvertedOpportunityId,MobileCountryCode__c, ' +
            'Country, State, City,Street, PostalCode, LanguagePreference__c, Passport_Number__c, PassportExpiryDate__c,Broker_Agent_Name__c, ' +
            'NationalID__c, NationalIDExpiryDate__c, PreferredCommunicationMethodology__c, ' +
            'CreatedDate, LastModifiedDate, RecordType.DeveloperName ' +
            'FROM Lead';
        
        String soql;
        if (!whereClauses.isEmpty()) {
            soql = baseQuery + ' WHERE ' + String.join(whereClauses, ' AND ') + ' ORDER BY LastModifiedDate DESC LIMIT 100';
        } else {
            // No filters — return last 100 modified leads
            soql = baseQuery + 'ORDER BY LastModifiedDate DESC LIMIT 100';
        }
        
        return Database.query(soql);
    }
    
    // Lead Status Count 
    public List<Lead> getLeadsForStatusCount(String accountId, String contactId, Date updatedOnFrom, Date updatedOnTo, Boolean isAdmin, Boolean isAgent) {
        List<String> whereClauses = new List<String>();
        
        // Business Logic – Admin, Super Admin, CEO, Owner, Partner, Authorized Signatory Officer: only Account must match
        if (isAdmin) {
            if (!String.isBlank(accountId)) {
                whereClauses.add('BrokerAgency__c = :accountId');
            }
        }
        // Business Logic – Agent: both Account AND Contact must match
        else if (isAgent) {
            if (!String.isBlank(accountId)) {
                whereClauses.add('BrokerAgency__c = :accountId');
            }
            if (!String.isBlank(contactId)) {
                whereClauses.add('BrokerAgent__c = :contactId');
            }
        }
        
        // Always restrict to required statuses
        whereClauses.add('(Status IN (\'New\', \'In Progress\', \'Closed\') OR IsConverted = true)');
        
        
        if (updatedOnFrom != null && updatedOnTo != null) {
            DateTime fromDateTime = DateTime.newInstance(updatedOnFrom, Time.newInstance(0, 0, 0, 0));
            DateTime toDateTime = DateTime.newInstance(updatedOnTo, Time.newInstance(23, 59, 59, 999));
            whereClauses.add('LastModifiedDate >= :fromDateTime AND LastModifiedDate <= :toDateTime');
        }
        
        
        String baseQuery = 'SELECT Id, Status, BrokerAgent__c, BrokerAgency__c, IsConverted, LastModifiedDate FROM Lead';
        String soql;
        
        if (!whereClauses.isEmpty()) {
            soql = baseQuery + ' WHERE ' + String.join(whereClauses, ' AND ');
        } else {
            soql = baseQuery;
        }
        
        soql += ' ORDER BY LastModifiedDate DESC';
        return Database.query(soql);
    }
    
    public static Map<Id, Map<String, Object>> getLeadSummaryData(Set<Id> contactIds, Date updatedOnFrom, Date updatedOnTo) {
        Map<Id, Map<String, Object>> result = new Map<Id, Map<String, Object>>();
        
        String dateFilter = '';
        if (updatedOnFrom != null && updatedOnTo != null) {
            DateTime fromDT = DateTime.newInstance(updatedOnFrom, Time.newInstance(0,0,0,0));
            DateTime toDT   = DateTime.newInstance(updatedOnTo, Time.newInstance(23,59,59,999));
            dateFilter = ' AND LastModifiedDate >= :fromDT AND LastModifiedDate <= :toDT';
        }
        
        String baseQuery =
            'SELECT BrokerAgent__c agentId, IsConverted, Status, COUNT(Id) total ' +
            'FROM Lead WHERE BrokerAgent__c IN :contactIds' +
            dateFilter +
            ' GROUP BY BrokerAgent__c, IsConverted, Status';
        
        for (AggregateResult ar : Database.query(baseQuery)) {
            Id agentId = (Id) ar.get('agentId');
            Boolean isConverted = (Boolean) ar.get('IsConverted');
            String status = (String) ar.get('Status');
            Integer total = (Integer) ar.get('total');
            
            if (!result.containsKey(agentId)) {
                result.put(agentId, new Map<String, Object>{
                    'LeadCreated' => 0,
                        'LeadConverted' => 0,
                        'StatusCounts' => new Map<String, Integer>()
                        });
            }
            
            result.get(agentId).put('LeadCreated', ((Integer) result.get(agentId).get('LeadCreated')) + total);
            if (isConverted) {
                result.get(agentId).put('LeadConverted', ((Integer) result.get(agentId).get('LeadConverted')) + total);
            }
            
            Map<String, Integer> statusMap = (Map<String, Integer>) result.get(agentId).get('StatusCounts');
            statusMap.put(status, statusMap.containsKey(status) ? statusMap.get(status) + total : total);
        }
        
        return result;
    }
    
    public Map<Id, Lead> getLeadSLAByIds(Set<Id> leadIds){
        if(leadIds == null || leadIds.isEmpty()){
            return new Map<Id, Lead>();
        }
        
        //return new Map<Id, Lead>([SELECT Id, LeadTeam__c, ReshuffleCount__c, LeadManagerAssignedDate__c, LeadManagerStatus__c, BusinessHour__c FROM Lead WHERE Id IN :leadIds ]);
        return new Map<Id, Lead>([ SELECT Id, Status, LeadTeam__c, ContactCentreLeadStatus__c, ReshuffleCount__c, LeadManagerAssignedDate__c, LeadManagerStatus__c, BusinessHour__c, Owner.ProfileId, Owner.Profile.Name FROM Lead WHERE Id IN :leadIds ]);
    }
}