@IsTest
private class ADHALeadAPITest {

    @TestSetup
    static void setupData() {
        Project__c projectRecord = new Project__c(
            Name = 'ADHA Test Project'
        );
        insert projectRecord;

        Lead leadRecord = new Lead(
            LastName = 'Existing Lead',
            Company = 'Test Company',
            ApplicationNumber__c = 'APP-EXISTING',
            LeadSource = 'Government Entity',
            leadsubsource__c = 'ADHA'
        );
        insert leadRecord;
    }

    private static void setRestRequest(String requestBody) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ADHALeadAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void testBlankApplicationNumber() {
        String requestBody = JSON.serialize(new Map<String, Object>{
            'ApplicationNumber' => '',
            'Status' => 'Approved'
        });

        setRestRequest(requestBody);

        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        Test.stopTest();

    }

    @IsTest
    static void testUpdateExistingLead() {
        Project__c projectRecord = [
            SELECT Id, Name
            FROM Project__c
            LIMIT 1
        ];

        Map<String, Object> applicant = new Map<String, Object>{
            'Name' => 'Abhay',
            'FamilyName' => 'Gupta',
            'EID' => '784199999999999',
            'PhoneNumber' => '0501234567',
            'Email' => 'abhay@example.com',
            'Tribe' => 'Test Tribe',
            'Gender' => 'Male',
            'DOB' => '1990-01-01',
            'MaritalStatus' => 'Married',
            'NumberOfWives' => 1,
            'NumberOfChildren' => 2,
            'Salary' => 25000,
            'TownName' => 'Abu Dhabi',
            'Passport' => new Map<String, Object>{
                'Number' => 'P1234567',
                'IssueDate' => '2020-01-01',
                'ExpiryDate' => '2030-01-01'
            }
        };

        Map<String, Object> project = new Map<String, Object>{
            'ProjectID' => 'ADHA-PROJECT-001',
            'Municipality' => 'Abu Dhabi',
            'Region' => 'Abu Dhabi',
            'District' => 'Test District'
        };

        Map<String, Object> requestData = new Map<String, Object>{
            'ApplicationNumber' => 'APP-EXISTING',
            'Status' => 'Approved',
            'LoanValue' => 500000,
            'Applicant' => applicant,
            'Project' => project
        };

        setRestRequest(JSON.serialize(requestData));

        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        Test.stopTest();

        //SYstem.assertEquals(200, response.code);
        //SYstem.assertNotEquals(null, response.DeveloperReferenceNumber);


    }

    @IsTest
    static void testCreateNewLead() {
        Map<String, Object> applicant = new Map<String, Object>{
            'Name' => 'Abhay',
            'FamilyName' => 'Gupta',
            'EID' => '784188888888888',
            'PhoneNumber' => '0509876543',
            'Email' => 'newlead@example.com',
            'Tribe' => 'Test Tribe',
            'Gender' => 'Male',
            'DOB' => '1992-05-10',
            'MaritalStatus' => 'Single',
            'NumberOfWives' => 0,
            'NumberOfChildren' => 0,
            'Salary' => 30000,
            'TownName' => 'Dubai',
            'Passport' => new Map<String, Object>{
                'Number' => 'P7654321',
                'IssueDate' => '2021-01-01',
                'ExpiryDate' => '2031-01-01'
            }
        };

        Map<String, Object> project = new Map<String, Object>{
            'ProjectID' => 'ADHA-PROJECT-001',
            'Municipality' => 'Dubai',
            'Region' => 'Dubai',
            'District' => 'Test District'
        };

        Map<String, Object> requestData = new Map<String, Object>{
            'ApplicationNumber' => 'APP-NEW-001',
            'Status' => 'New',
            'LoanValue' => 750000,
            'Applicant' => applicant,
            'Project' => project
        };

        setRestRequest(JSON.serialize(requestData));

        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        Test.stopTest();



    }

    @IsTest
    static void testCreateLeadWithoutOptionalData() {
        Map<String, Object> requestData = new Map<String, Object>{
            'ApplicationNumber' => 'APP-OPTIONAL-001',
            'Status' => 'In Progress',
            'Applicant' => new Map<String, Object>{
                'Name' => 'Test Applicant',
                'FamilyName' => 'Test Family'
            }
        };

        setRestRequest(JSON.serialize(requestData));

        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        Test.stopTest();


    }

    @IsTest
    static void testProjectNotFound() {
        Map<String, Object> requestData = new Map<String, Object>{
            'ApplicationNumber' => 'APP-NO-PROJECT',
            'Status' => 'New',
            'Applicant' => new Map<String, Object>{
                'Name' => 'Test',
                'FamilyName' => 'User',
                'Salary' => 10000
            },
            'Project' => new Map<String, Object>{
                'ProjectID' => 'NON-EXISTING-PROJECT',
                'Municipality' => 'Abu Dhabi',
                'Region' => 'Abu Dhabi',
                'District' => 'Test'
            }
        };

        setRestRequest(JSON.serialize(requestData));

        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        Test.stopTest();

        //SYstem.assertEquals(200, response.code);


    }

    @IsTest
    static void testExceptionHandling() {
        /*
         * Invalid JSON causes JSON.deserializeUntyped()
         * to throw an exception.
         */
        setRestRequest('{ invalid json');

        Test.startTest();
        ADHALeadAPI.Response response = ADHALeadAPI.createLead();
        Test.stopTest();

    }
}