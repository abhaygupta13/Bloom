@isTest
public class BCAPP_ConstantsTest {
    @isTest
    static void testConstants() {
        System.assertEquals('Owner', BCAPP_Constants.OWNER, 'OWNER constant mismatch');
        System.assertEquals('Holiday Homes', BCAPP_Constants.HOLIDAY_HOMES, 'HOLIDAY_HOMES constant mismatch');
        System.assertEquals('Tenant', BCAPP_Constants.TENANT, 'TENANT constant mismatch');
        System.assertEquals('Move In', BCAPP_Constants.MOVE_IN, 'MOVE_IN constant mismatch');
        System.assertEquals('Move Out', BCAPP_Constants.MOVE_OUT, 'MOVE_OUT constant mismatch');
        System.assertEquals('Renewal', BCAPP_Constants.RENEWAL, 'RENEWAL constant mismatch');
        System.assertEquals('Community APP', BCAPP_Constants.COMMUNITY_APP, 'COMMUNITY_APP constant mismatch');
        System.assertEquals('Notices', BCAPP_Constants.NOTICES, 'NOTICES constant mismatch');
        System.assertEquals('Access Permit', BCAPP_Constants.ACCESS_PERMIT, 'ACCESS_PERMIT constant mismatch');
        System.assertEquals('Service Request', BCAPP_Constants.SERVICE_REQUEST, 'SERVICE_REQUEST constant mismatch');

        System.assertEquals('Events', BCAPP_Constants.notificationRT.get('events'), 'notificationRT map events key mismatch');
        System.assertEquals('News Letters', BCAPP_Constants.notificationRT.get('news-letters'), 'notificationRT map news-letters key mismatch');
        System.assertEquals('Notices', BCAPP_Constants.notificationRT.get('notices'), 'notificationRT map notices key mismatch');

        System.assert(BCAPP_Constants.eligibleStatus.contains('Approved'), 'eligibleStatus list does not contain Approved');
        System.assertEquals(1, BCAPP_Constants.eligibleStatus.size(), 'eligibleStatus list size mismatch');

        System.assert(BCAPP_Constants.approvedEligibleStatus.contains('Approved'), 'approvedEligibleStatus list does not contain Approved');
        System.assertEquals(1, BCAPP_Constants.approvedEligibleStatus.size(), 'approvedEligibleStatus list size mismatch');

        System.assertEquals('Move In', BCAPP_Constants.MoveInRecrdTypes.get('Tenant'), 'MoveInRecrdTypes map Tenant key mismatch');
        System.assertEquals('Move In Owner', BCAPP_Constants.MoveInRecrdTypes.get('Owner'), 'MoveInRecrdTypes map Owner key mismatch');
        System.assertEquals('Move In Holiday Homes', BCAPP_Constants.MoveInRecrdTypes.get('Holiday Home'), 'MoveInRecrdTypes map Holiday Home key mismatch');
    }
}