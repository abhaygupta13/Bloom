//============================ BCAPP_Constants =============================
/*
* @Author : Eagles 
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_Constants
* @Description : This class used to declare the Constant Variables
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               21 OCT 2024        Initial draft 
*****************************************************************************************************/
public Class BCAPP_Constants { 
    
    public static final String OWNER = 'Owner';
    public static final String HOLIDAY_HOMES = 'Holiday Homes';
    public static final String TENANT = 'Tenant';
    public static final String MOVE_IN = 'Move In';
    public static final String MOVE_OUT = 'Move Out';
    public static final String AMENITIES = 'Amenities';
    public static final String RENEWAL = 'Renewal';
    public static final String COMMUNITY_APP ='Community APP';
    public static final String NOTICES ='Notices';
    public static final String ACCESS_PERMIT ='Access Permit';
    public static final String GUEST_MGMT ='Guest Management';
    public static final String SERVICE_REQUEST ='Service Request';
    public static final String WITH_LEGAL = 'With Legal';
    public static Map<String, String> notificationRT = new Map<String, String>{
            'events' => 'Events',
            'news-letters' => 'News Letters',
            'notices' => 'Notices'
    };
          public static List<String> eligibleStatus = new List<String>{
              'Approved'
                  };
                      public static List<String> approvedEligibleStatus = new List<String>{
                          'Approved'
                              };
    public static Map<String, String> MoveInRecrdTypes = new Map<String, String>{
            'Tenant' => 'Move In',
            'Owner' => 'Move In Owner',
            'Holiday Home' => 'Move In Holiday Homes'
    };    
        
        
   public static Integer getGuestCount(String unitModel) {
    Map<String, Integer> guestMap = new Map<String, Integer>{
        'Studio' => 3,
        '1BHK' => 4,
        '2BHK' => 6,
        '3BHK' => 9,
        '4BHK' => 12,
        '5BHK' => 15
    };
    return (unitModel!=null && guestMap.containsKey(unitModel)) ? guestMap.get(unitModel) : 3;
}     
}