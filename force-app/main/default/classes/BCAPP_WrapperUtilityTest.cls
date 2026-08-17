@isTest
public class BCAPP_WrapperUtilityTest {

    @isTest
    static void testWrapperClasses() {
        BCAPP_WrapperUtility.TenantMoveInWrapper tenantWrapper = new BCAPP_WrapperUtility.TenantMoveInWrapper();
        tenantWrapper.request = new BCAPP_WrapperUtility.Request();
        tenantWrapper.documents = new List<BCAPP_WrapperUtility.Document>();

        tenantWrapper.request.srId = 'SR123';
        tenantWrapper.request.firstName = 'John';
        tenantWrapper.request.lastName = 'Doe';
        tenantWrapper.request.nationality = 'American';
        tenantWrapper.request.emailAddress = 'john.doe@example.com';
        tenantWrapper.request.mobileNumber = '1234567890';
        tenantWrapper.request.ejariStartDate = '2024-01-01';
        tenantWrapper.request.ejariEndDate = '2025-01-01';
        tenantWrapper.request.ejariNumber = 'EJ123456';
        tenantWrapper.request.moveInDate = '2024-02-01';
        tenantWrapper.request.emiratesNumber = 'EM123456';
        tenantWrapper.request.emiratesExpDate = '2025-12-31';
        tenantWrapper.request.emergencyContactNumber01 = '0987654321';
        tenantWrapper.request.emergencyContactNumber02 = '1122334455';
        tenantWrapper.request.adultOccupants = 2;
        tenantWrapper.request.childOccupants = 1;
        tenantWrapper.request.occupantsWithSpecialNeeds = true;
        tenantWrapper.request.specialNeedsComments = 'Requires wheelchair access';
        tenantWrapper.request.unitId = 'U123';
        tenantWrapper.request.requestAs = 'Tenant';
        tenantWrapper.request.requestType = 'Move In';
        tenantWrapper.request.hasAgreedTerms = true;

        BCAPP_WrapperUtility.Document tenantDoc = new BCAPP_WrapperUtility.Document();
        tenantDoc.fileName = 'Passport.pdf';
        tenantDoc.fileContent = Blob.valueOf('Sample PDF Content');
        tenantDoc.contentType = 'application/pdf';
        tenantWrapper.documents.add(tenantDoc);

        System.assertEquals('John', tenantWrapper.request.firstName);
        System.assertEquals(2, tenantWrapper.request.adultOccupants);

        // Test HHOMoveInWrapper
        BCAPP_WrapperUtility.HHOMoveInWrapper hhoWrapper = new BCAPP_WrapperUtility.HHOMoveInWrapper();
        hhoWrapper.request = new BCAPP_WrapperUtility.HHORequest();
        hhoWrapper.documents = new List<BCAPP_WrapperUtility.Document>();

        hhoWrapper.request.srId = 'SR456';
        hhoWrapper.request.representativeName = 'Alice';
        hhoWrapper.request.operatorName = 'Operator Inc.';
        hhoWrapper.request.representativeEmail = 'alice@example.com';
        hhoWrapper.request.representativeContactNumber = '9876543210';
        hhoWrapper.request.operatorLicenseNumber = 'LIC123456';
        hhoWrapper.request.operatorOfficeNumber = '101';
        hhoWrapper.request.operatorLicenseExpDate = '2025-06-30';
        hhoWrapper.request.ejariStartDate = '2024-03-01';
        hhoWrapper.request.ejariEndDate = '2025-03-01';
        hhoWrapper.request.moveInDate = '2024-04-01';
        hhoWrapper.request.emiratesIdNumber = 'EM654321';
        hhoWrapper.request.emiratesIdExpDate = '2026-12-31';
        hhoWrapper.request.emergencyContactNumber01 = '1122445566';
        hhoWrapper.request.emergencyContactNumber02 = '2233445566';
        hhoWrapper.request.unitId = 'U456';
        hhoWrapper.request.requestAs = 'Holiday Home';
        hhoWrapper.request.requestType = 'Move In';
        hhoWrapper.request.ejariNumber = 'EJ654321';
        hhoWrapper.request.hasAgreedTerms = true;

        System.assertEquals('Operator Inc.', hhoWrapper.request.operatorName);

        // Test OwnerMoveInWrapper
        BCAPP_WrapperUtility.OwnerMoveInWrapper ownerWrapper = new BCAPP_WrapperUtility.OwnerMoveInWrapper();
        ownerWrapper.srId = 'SR789';
        ownerWrapper.moveInDate = '2024-05-01';
        ownerWrapper.unitId = 'U789';
        ownerWrapper.emergencyContactNumber01 = '5566778899';
        ownerWrapper.emergencyContactNumber02 = '6677889900';
        ownerWrapper.adultOccupants = 3;
        ownerWrapper.childOccupants = 2;
        ownerWrapper.occupantsWithSpecialNeeds = false;
        ownerWrapper.specialNeedsComments = '';

        System.assertEquals(3, ownerWrapper.adultOccupants);

        BCAPP_WrapperUtility.TenantRenewWrapper tenantRenewWrapper = new BCAPP_WrapperUtility.TenantRenewWrapper();
        tenantRenewWrapper.leaseExpDate = '2025-07-01';
        tenantRenewWrapper.srId = 'SR101';
        tenantRenewWrapper.accountId = 'A123';
        tenantRenewWrapper.unitId = 'U101';
        tenantRenewWrapper.serviceCatalogId = 'SC101';
        tenantRenewWrapper.userType = 'Tenant';
        tenantRenewWrapper.hasAgreedTerms = true;
        tenantRenewWrapper.hasOccupantWithSpecialNeeds = true;
        tenantRenewWrapper.occupantWithSpecialNeedsComments = 'Hearing aid required';
        tenantRenewWrapper.adultOccupants = 2;
        tenantRenewWrapper.childOccupants = 1;
        tenantRenewWrapper.documents = new List<BCAPP_WrapperUtility.Document>();

        System.assertEquals('Hearing aid required', tenantRenewWrapper.occupantWithSpecialNeedsComments);

        BCAPP_WrapperUtility.MoveOutWrapper moveOutWrapper = new BCAPP_WrapperUtility.MoveOutWrapper();
        moveOutWrapper.srId = 'SR102';
        moveOutWrapper.moveOutDate = '2025-08-01';
        moveOutWrapper.accountId = 'A456';
        moveOutWrapper.unitId = 'U102';
        moveOutWrapper.serviceCatalogId = 'SC102';
        moveOutWrapper.hasAgreedTerms = true;

        System.assertEquals('SR102', moveOutWrapper.srId);

        BCAPP_WrapperUtility.MyPortFolioResponse portfolio = new BCAPP_WrapperUtility.MyPortFolioResponse();
        portfolio.unitNumber = '105';
        portfolio.floorNumber = '2';
        portfolio.buildingName = 'Tower B';
        portfolio.location = 'Uptown';
        portfolio.unitId = 'U103';
        portfolio.projectId = 'P123';
        portfolio.isChillerEnabled = true;
        portfolio.isLeaseHold = false;
        portfolio.communityImageURL = 'http://example.com/image.jpg';

        System.assertEquals('Tower B', portfolio.buildingName);

        Map<String, Object> responseMap = new Map<String, Object>{'key1' => 'value1'};
        BCAPP_WrapperUtility.Response response = new BCAPP_WrapperUtility.Response(responseMap);
        System.assertEquals('value1', response.response.get('key1'));
    }
}