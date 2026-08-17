@isTest
public class BCAPP_TestDataFactory {
    public static Service_Catalog__c createServiceCatalog() {
        
        Service_Catalog__c sobj = new Service_Catalog__c(
            Name = 'Service Request',                     // Service Name
            Active__c = true,                               // Active
            Access_To__c = 'Holiday Homes; Owner; Tenant',  // Available To
            Service_Available_on_Mobile__c = true,          // Service Available on Mobile
            Permit_Terms_and_Conditions__c = ''          // Permit Terms and Conditions
        );
        return sobj;
        }
    
    public static Customer_Document__c createCustomerDocument() {
        
        Customer_Document__c sobj = new Customer_Document__c(
            Name = 'Unit permit issued by government'       // Customer Document Name
           // Service_Catolog_Documents__c = 'a2yKF000000E3JS',  // Service Catolog Documents
           // Case__c = '500FW000005egk1'                       // Case
        );
        return  sobj;
    }
    
    public static Service_Catalog_Fields__c createserviceCatalogFields() {
        
        Service_Catalog_Fields__c sobj = new Service_Catalog_Fields__c(
            Name = 'unitId',                              // Service Catalog Fields Name
            is_Date__c = false,                             // is Date
            FIeld_API_Name__c = 'Unit__c',                  // FIeld API Name
            User_Type__c = 'Holiday Homes; Owner; Tenant',  // User Type
            is_Decimal__c = false                          // is Decimal
        );
    return sobj;
        }
    public static Service_Catolog_Documents__c createServiceCatalogDocuments() {
        Service_Catolog_Documents__c sobj = new Service_Catolog_Documents__c(
            Name = 'Unit permit issued by government',            // Service Catolog Documents Name
            Required_For__c = 'Holiday Homes',                      // Required For
            Document_Name__c = 'Unit permit issued by government',  // Document Name
            Document_Type__c = 'application/pdf',                   // Document Type
            Document_Size__c = '2',                                 // Document Size
            is_Chiller_Enabled__c = false                          // is Chiller Enabled
        );
        return sobj;
    }
    
    // Method to create a sample Case
    public static Case createCase() {
        
         
        Round_Robins__c rr=new Round_Robins__c(
            Name='Service/Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
        );
        insert rr;
        
        Round_Robins__c Reseller=new Round_Robins__c(
            Name='Service/Resale Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
            
        );
        insert Reseller;
          Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
        User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                    TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.id
            
        );
        insert rrUser;
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=10,
            User__c=userRecord2.id
        );
        insert rrUser1;
        
        Case sobj = new Case();
        sobj.Last_Name__c='last Name';
        sobj.Origin = 'Community APP';
        sobj.Operator_Name__c = 'sameee';
        sobj.Representative_Name__c = 'same';
        sobj.Representative_Email__c = 'same@gmail.com';
        sobj.Representative_Contact_Number__c = '971521394512';
        sobj.Operator_License_Number__c = '33447883';
        sobj.Operator_Office_Number__c = '971551316794';
        sobj.Status = 'Draft';
        sobj.User_Type__c = 'Holiday Homes';
        sobj.Emirates_ID_number__c = '784-8465-6554123-6';
        sobj.Emirates_ID_expiry_date__c = System.today();
        sobj.Move_In_Date__c = System.today();
        sobj.Emergency_contact_01__c = '971541231464';
        sobj.Priority = 'Medium';
        return sobj;
    }
    public static Account createAccount(String accountName) {
        Account acc = new Account(
            Name = accountName,
            Azure_UserPrincipal_Id__c = 'testAzureId'
        );
        return acc;
    }
    
    
    public static Notifications__c createNotifications() {
        Notifications__c sobj = new Notifications__c(
            Name = 'Event on Jan 06',                                          // Name
            //Project__c = 'a0QKF000002TOG9',                                      // Project
            Description__c = 'Event at adudabhi',                                // Description
            Event_Venue__c = 'UAI',                                              // Event Venue
            Publish_Date_Time__c = system.today(),  // Publish Date/Time
            Status__c = 'Published'                                             // Status
        );
    return sobj;
    }
    
      public static BuildingSection__c createBuildingSection(string name) {
   
    BuildingSection__c testBuilding=new BuildingSection__c(
        Name=name,
        BuildingSectionCode__c='BL-CAS'        
    );
    return testBuilding;
      }
    
     public static Project__c createProject() {
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        return testProject;
    }
    
    
           

    public static Contact createContact(Id accountId, String email) {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = email,
            AccountId = accountId
        );
        return con;
    }

    public static Unit__c createUnit() {
        Unit__c unit = new Unit__c(
            Name = 'Test Unit'        );
        return unit;
    }

    public static Service_Contract__c createServiceContract() {
        Service_Contract__c contract = new Service_Contract__c(
            Move_Out_Date__c = Date.today().addMonths(1)
        );
        return contract;
    }

    public static Id createCase(Id accountId, Id unitId, String status, String serviceName) {
        Case caseRecord = new Case(
            AccountId = accountId,
            Unit__c = unitId,
            Status = status,
            Service_Catalog__r = new Service_Catalog__c(Name = serviceName),
            EJARI_Tawteeq_end_date__c = Date.today().addMonths(6),
            Move_Out_Date__c = Date.today().addDays(30),
            Representative_Email__c = 'test@example.com',
            Email_Address__c = 'customer@example.com'
        );
        insert caseRecord;
        return caseRecord.Id;
    }

    public static Id createCustomerDocument(Id caseId) {
        Customer_Document__c doc = new Customer_Document__c(
            Case__c = caseId,
            Name = 'Test Document'
        );
        insert doc;
        return doc.Id;
    }
    public static User__c createUser(string azureId) {
        
        User__c sobj = new User__c(
            Username__c = 'Lucas',                                                                      // User Name
            User_Type__c = 'Holiday Homes',                                                               // User Type
            Azure_UserId__c = azureId,                                     // Azure UserId
            Is_Azure_Active__c = true,                                                                    // Is Azure Active
            User_Principal_Name__c = '1f6ee734-7928-4a25-b007-1850f0103812@bloomdevb2c.onmicrosoft.com',  // User Principal Name
            isActive__c = false                                                                          // isActive
        );
        return sobj;
        
    }
    
    public static Unit_Allocation__c createUnitAllocation() {
        
        Unit_Allocation__c sobj = new Unit_Allocation__c(
            //       Unit__c = 'a0bKF000002fJmC',               // Unit
            //     User__c = 'a2qFW0000004MLJ',                 // User
            Active__c = true,                            // Active
            Start_Date__c = system.today(),  // Start Date
            End_Date__c = system.today().addDays(3434),    // End Date
            //   Account__c = '001FW000007vFzJ',              // Account
            User_Type__c = 'Tenant',                     // User Type
            Is_Favourite_Unit__c = false                // Is Favourite Unit
        );
        return sobj;
    }
    public static Id createContentDocumentLink(Id customerDocumentId) {
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = customerDocumentId,
            ContentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id,
            ShareType = 'V'
        );
        insert link;
        return link.Id;
    }

}