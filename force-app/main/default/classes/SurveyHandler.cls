public inherited sharing class SurveyHandler {
    private static final string SALES_CUSTOMER_SURVEY_TYPE { get { return 'Sales Customer Survey'; } }
    private static final string SALES_BROKER_SURVEY_TYPE { get { return 'Sales Broker Survey'; } }
    private static final string HANDOVER_SURVEY_TYPE { get { return 'Handover Survey'; } }
    private static final string BFM_SURVEY_TYPE { get { return 'BFM Customer Survey'; } }

    public static void sendSalesCustomerSurvey(Set<Id> soldSalesOrderIds){
        SalesOrderService orderServiceObj = SalesOrderService.getInstance();
        List<SalesOrder__c> salesOrderList = orderServiceObj.getNewSalesOrdersByIds(soldSalesOrderIds);

        List<Survey__c> svListToInsert = new List<Survey__c>();
        for(SalesOrder__c soRec : salesOrderList){
            Survey__c svRec1 = new Survey__c();
            svRec1.SalesOrder__c = soRec.Id;
            svRec1.Account__c = soRec.Account__c;
            svRec1.BookingDate__c = soRec.BookingDate__c;
            svRec1.Email__c = soRec.Account__r.PersonEmail;
            svRec1.FirstName__c = soRec.Account__r.FirstName;
            svRec1.LastName__c = soRec.Account__r.LastName;
            svRec1.Project__c = soRec.Project__c;
            svRec1.ProjectName__c = soRec.ProjectName__c;
            svRec1.SalesManager__c = soRec.SalesManager__c;
            svRec1.SalesType__c = soRec.Direct_Indirect__c;
            svRec1.SurveyType__c = SALES_CUSTOMER_SURVEY_TYPE;
            svRec1.Unit__c = soRec.Unit__c;
            svRec1.UnitNumber__c = soRec.Unit__r.UnitNumber__c;
            svListToInsert.add(svRec1);
            if(soRec.Sale_Type__c == 'Resale' && soRec.Resale__c && soRec.ResaleBrokerAgency__c != NULL && soRec.ResaleBrokerAgent__c != NULL
                    && soRec.ResaleBrokerAgent__r.Email != NULL){
                Survey__c svRec2 = new Survey__c();
                svRec2.SalesOrder__c = soRec.Id;
                svRec2.Account__c = soRec.ResaleBrokerAgency__c;
                svRec2.BookingDate__c = soRec.BookingDate__c;
                svRec2.Email__c = soRec.ResaleBrokerAgent__r.Email;
                svRec2.AgencyName__c = soRec.ResaleBrokerAgency__r.Name;
                svRec2.Project__c = soRec.Project__c;
                svRec2.ProjectName__c = soRec.ProjectName__c;
                svRec2.SalesManager__c = soRec.SalesManager__c;
                svRec2.SalesType__c = soRec.Direct_Indirect__c;
                svRec2.SurveyType__c = SALES_BROKER_SURVEY_TYPE;
                svRec2.Unit__c = soRec.Unit__c;
                svRec2.UnitNumber__c = soRec.Unit__r.UnitNumber__c;
                svListToInsert.add(svRec2);
            }
            else if(soRec.Opportunity__c != NULL && soRec.Opportunity__r.BrokerAgencyAccount__c != NULL && soRec.Opportunity__r.BrokerAgentContact__c != NULL
                    && soRec.Opportunity__r.BrokerAgentContact__r.Email != NULL){
                Survey__c svRec2 = new Survey__c();
                svRec2.SalesOrder__c = soRec.Id;
                svRec2.Account__c = soRec.Opportunity__r.BrokerAgencyAccount__c;
                svRec2.BookingDate__c = soRec.BookingDate__c;
                svRec2.Email__c = soRec.Opportunity__r.BrokerAgentContact__r.Email;
                svRec2.AgencyName__c = soRec.Opportunity__r.BrokerAgencyAccount__r.Name;
                svRec2.Project__c = soRec.Project__c;
                svRec2.ProjectName__c = soRec.ProjectName__c;
                svRec2.SalesManager__c = soRec.SalesManager__c;
                svRec2.SalesType__c = soRec.Direct_Indirect__c;
                svRec2.SurveyType__c = SALES_BROKER_SURVEY_TYPE;
                svRec2.Unit__c = soRec.Unit__c;
                svRec2.UnitNumber__c = soRec.Unit__r.UnitNumber__c;
                svListToInsert.add(svRec2);
            }
        }
        SurveyService surveyServiceInstance = SurveyService.getInstance();
        surveyServiceInstance.insertSurveys(svListToInsert);
    }

    public static void sendBrokerSurvey(){
        
    }

    public static void sendHandoverSurvey(Set<Id> completedHandoverIdsSet){
        HandoverService handoverServiceObj = HandoverService.getInstance();
        List<Handover__c> handoverList = handoverServiceObj.getHandoverWithProjectAndUnit(completedHandoverIdsSet);

        List<Survey__c> svListToInsert = new List<Survey__c>();
        for(Handover__c hoRec : handoverList){
            Survey__c svRec1 = new Survey__c();
            svRec1.Handover__c = hoRec.Id;
            svRec1.Account__c = hoRec.Account__c;
            //svRec1.BookingDate__c = soRec.BookingDate__c;
            svRec1.Email__c = hoRec.Account__r.PersonEmail;
            svRec1.FirstName__c = hoRec.Account__r.FirstName;
            svRec1.LastName__c = hoRec.Account__r.LastName;
            svRec1.Project__c = hoRec.Project__c;
            svRec1.ProjectName__c = hoRec.Project_Name__c;
            svRec1.Handover_Name__c = hoRec.Name;
            svRec1.Handover_Date__c = hoRec.Date__c;
            //svRec1.SalesManager__c = soRec.SalesManager__c;
            //svRec1.SalesType__c = soRec.Direct_Indirect__c;
            svRec1.SurveyType__c = HANDOVER_SURVEY_TYPE;
            svRec1.Unit__c = hoRec.Unit__c;
            svRec1.UnitNumber__c = hoRec.Unit__r.UnitNumber__c;
            svListToInsert.add(svRec1);
        }
        SurveyService surveyServiceInstance = SurveyService.getInstance();
        surveyServiceInstance.insertSurveys(svListToInsert);
    }

    public static void sendBFMCaseSurvey(Set<Id> caseIds){
        if(caseIds == null || caseIds.isEmpty()){
            return;
        }
        CaseService objCaseService = CaseService.getInstance();
        SurveyService objSurveyService = SurveyService.getInstance();
        List<Case> caseList = objCaseService.getCaseByIds(new Set<Id>(caseIds));

        List<Survey__c> svListToInsert = new List<Survey__c>();

        for(Case caseObj : caseList){
            Survey__c svRec = new Survey__c();
            svRec.Case__c = caseObj.Id;
            svRec.Account__c = caseObj.AccountId;
            svRec.Email__c = caseObj.RequesterEmail__c;
            svRec.Unit__c = caseObj.Unit__c;
            svRec.SurveyType__c = BFM_SURVEY_TYPE;
            svRec.FirstName__c = caseObj.RequesterName__c;
            svRec.Project__c = caseObj.Unit__r.Project__c;
            svListToInsert.add(svRec);
        }

        if(!svListToInsert.isEmpty()){
            objSurveyService.insertSurveys(svListToInsert);
        }
    }
}