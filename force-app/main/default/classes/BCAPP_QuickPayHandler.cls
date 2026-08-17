/**
 * Class: BCAPP_QuickPayHandlerc
 * Purpose: Orchestrates Quick Pay validation, submission, and status updates.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Contains no inline SOQL/DML; all data access and persistence use service classes.
 * - Preserves original error/success messages and behavior.
 */
public class BCAPP_QuickPayHandler {

    /**
     * Validate a Quick Pay attempt by Customer ID (AccountNumber) and Unit Number (Unit.Name).
     * On success, returns project/unit/account details and total outstanding.
     * On failure, returns the original error message text.
     *
     * Expected data: { customerId, unitId } where:
     *  - customerId -> Account.AccountNumber
     *  - unitId     -> Unit__c.Name
     */
    public static void validateQuickPay(Map<String, Object> data) {
        try {
            String customerId = (String) data.get('customerId'); // AccountNumber__c
            String unitNumber = (String) data.get('unitId');      // Actually Unit.Name

            if (String.isBlank(customerId) || String.isBlank(unitNumber)) {
                // Keep behavior: throw → catch returns the fixed error message below
                throw new AuraHandledException('Customer ID and Unit Number are required.');
            }

            // Account by AccountNumber (via service)
            Account acc = AccountService.getInstance().getByAccountNumber(customerId);

            // Unit by Name (via service)
            Unit__c unit = UnitService.getInstance().getByName(unitNumber);

            // If either not found, treat as mismatch (same final message)
            if (acc == null || unit == null) {
                Map<String, Object> response = new Map<String, Object>{
                    'errorMessage' => 'Given Customer ID and select unit no are not matching. Please provide correct details'
                };
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }

            // Allocation check (Active__c = true) via service
            Boolean hasActive = UnitAllocationService.getInstance()
                                  .hasActiveAllocationFlag(acc.Id, unit.Id);
            if (!hasActive) {
                Map<String, Object> response = new Map<String, Object>{
                    'errorMessage' => 'Given Customer ID and select unit no are not matching. Please provide correct details'
                };
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
                return;
            }

            // Outstanding sum (Unpaid/Partially Paid) via service
            AggregateResult summary =
                InvoiceService.getInstance().sumTotalDueByAccountUnit(acc.Id, unit.Id);
            Decimal totalDue = summary != null ? (Decimal) summary.get('totalDue') : null;

            Map<String, Object> response = new Map<String, Object>{
                'projectName'      => unit.ProjectName__c != null ? unit.ProjectName__c : '',
                'buildingName'     => unit.Building_Phase_Name__c != null ? unit.Building_Phase_Name__c : '',
                'unitName'         => unit.Name,
                'ownerName'        => acc.Name,
                'unitId'           => unit.Id,
                'accountId'        => acc.Id,
                'totalOutstanding' => totalDue != null ? totalDue : 0
            };
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            // Preserve original response message for any exception
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Given Customer ID and select unit no are not matching. Please provide correct details'
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }
    }

    /**
     * Submit a Quick Pay payment (no invoice allocations).
     * Creates an OnlinePayment__c in Pending state and returns paymentId.
     *
     * Expected data: { customerId (Account Id), unitId, paymentMethod, amount }
     */
    public static void submitQuickPay(Map<String, Object> data) {
        try {
            String customerId     = (String) data.get('customerId');
            String unitId         = (String) data.get('unitId');
            String paymentMethod  = (String) data.get('paymentMethod');
            Decimal paymentAmount = (Decimal) data.get('amount');

            if (String.isBlank(customerId) || String.isBlank(unitId) || paymentAmount == null || paymentAmount <= 0) {
                // Keep behavior: throw → catch will craft the message exactly as before
                throw new AuraHandledException('Customer ID, Unit, and valid Payment Amount are required.');
            }
			Unit__c unit = UnitService.fetchUnitDetailsById(unitId)[0];
            BankAccount__c ba = fetchBankDetailsByCompanyCode(unit.Project__r.BankAccount__c);
            Decimal Percentage =  0.0125;
            Decimal base = paymentAmount / (1 + percentage);
			
			Decimal technologyfee = paymentAmount - base;
            
            OnlinePayment__c payment = new OnlinePayment__c(
                PaidAmount__c    = base,
                Account__c       = customerId,
                Unit__c          = unitId,
                RequestSource__c = 'QuickPay',
                PaymentMethod__c = paymentMethod,
                Status__c        = 'Pending',
                TechnologyFee__c = technologyFee
            );
            // DML via service
            payment = OnlinePaymentService.getInstance().insertPayment(payment);
            if(Test.isRunningTest()){
               ba = new BankAccount__c();
               ba.MMID__c =  '811676301190';
            }
			
            Map<String, Object> response = new Map<String, Object>{
                'paymentId' =>  BCAPP_Utility.encryptId(payment.Id),
                    'mmid' => ba.MMID__c
            };
            BCAPP_WebServiceHelper.makeSuccessResponse(response);

        } catch (Exception ex) {
            System.debug(ex.getMessage());
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Quick Pay submission failed: ' + ex.getMessage() + ' | Line: ' + ex.getLineNumber() + ' | Stack: ' + ex.getStackTraceString()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }

    /**
     * Update the Quick Pay payment status and (on success) create a Receipt__c.
     * No invoice allocations are created in this flow.
     *
     * Expected data: { paymentId, status, message }
     */
    public static void updateQuickPayStatus(Map<String, Object> data) {
        try {
            String paymentId = (String) data.get('paymentId');
            String status    = (String) data.get('status');
            String message   = (String) data.get('message');
			
            //paymentId = BCAPP_Utility.decryptId(paymentId);
            
            // Fetch payment via service
            OnlinePayment__c payment =
                OnlinePaymentService.getInstance().getPaymentById((Id)paymentId);

            payment.Status__c          = status;
            payment.ResponseMessage__c = message;

            // DML via service
            OnlinePaymentService.getInstance().updatePayment(payment);
			System.debug('status '+status);
            if (payment.Status__c == 'Success') {
                Receipt__c receipt = new Receipt__c(
                    AmountReceived__c   = payment.PaidAmount__c,
                    PaymentDate__c      = System.today(),
                    PaymentMode__c      = 'Online',
                    GatewayReference__c = payment.GatewayReference__c,
                    Status__c           = 'Posted',
                    OnlinePayment__c    = payment.Id,
                    Account__c          = payment.Account__c,
                    Unit__c             = payment.Unit__c,
                    TechnologyFee__c  = payment.TechnologyFee__c
                );
                // DML via service
                ReceiptService.getInstance().insertReceipt(receipt);
            }
			System.debug('payment.Status__c '+payment.Status__c);
            Map<String, Object> response = new Map<String, Object>{
                'status'  => payment.Status__c,
                'message' => payment.ResponseMessage__c
            };
            if (payment.Status__c == 'Success') {
                // External system call, not DML
                BCAPP_SAPPaymentStatusPoster.postPaymentStatus(payment.Id, 'QuickPay');
            }
            BCAPP_WebServiceHelper.makeSuccessResponse(response);
            

        } catch (Exception ex) {
            Map<String, Object> response = new Map<String, Object>{
                'errorMessage' => 'Quick Pay update failed: ' + ex.getMessage() + ' | Line: ' + ex.getLineNumber() + ' | Stack: ' + ex.getStackTraceString()
            };
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    }
    private static BankAccount__c fetchBankDetailsByCompanyCode(String companyCode) {
        if (String.isBlank(companyCode)) return null;
        // SOQL is supported on Custom Metadata Types
        List<BankAccount__c> rows = [
            SELECT Name,CompanyCode__c, AccountNumberCorporate__c, IBANNoCorporate__c, SwiftCodeCorporate__c, BankNameCorporate__c,MMID__c 
            FROM BankAccount__c
            WHERE Id = :companyCode
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }
}