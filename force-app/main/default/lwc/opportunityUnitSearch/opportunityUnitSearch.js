import { LightningElement, api, wire, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import getAllProjects from '@salesforce/apex/OpportunityUnitSearchHandler.getAllProjects';
import getAllBuildings from '@salesforce/apex/OpportunityUnitSearchHandler.getAllBuildings';
import getUnitDetails from '@salesforce/apex/OpportunityUnitSearchHandler.getUnitDetails';
import generateSalesOffer from '@salesforce/apex/OpportunityUnitSearchHandler.generateSalesOffer';
import sendSalesOfferPDF from '@salesforce/apex/OpportunityUnitSearchHandler.sendSalesOfferPDF';
import sendBookingAgreementAttachment from '@salesforce/apex/OpportunityUnitSearchHandler.sendBookingAgreementAttachment';
import getsObjectType from '@salesforce/apex/OpportunityUnitSearchHandler.getsObjectType';

import getWinReasonPickList from "@salesforce/apex/OpportunityUnitSearchHandler.getWinReasonPickList";

import getOfferLinesQuery from "@salesforce/apex/OpportunityUnitSearchHandler.getOfferLinesQuery";

import getRegistrationValidation from '@salesforce/apex/OpportunityUnitSearchHandler.validateRegistrationAllowed';
import provideRegistrationValidation from '@salesforce/apex/Utilities.genericValidationMsgGenerator';
import OppBlackListEirateValidation from '@salesforce/apex/Utilities.OppBlackListEirateValidation';
import reserveUnit from '@salesforce/apex/OpportunityUnitSearchHandler.reserveUnit';
import lockUnits from '@salesforce/apex/OpportunityUnitSearchHandler.lockUnits';
import MemoDirectCommission from '@salesforce/label/c.MemoDirectCommission';
import MemoIndirectCommission from '@salesforce/label/c.MemoIndirectCommission';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import getCustomerInfo from '@salesforce/apex/OpportunityUnitSearchHandler.getCustomerInfo';

import updateUserField from '@salesforce/apex/OpportunityUnitSearchHandler.updateUserField';
import submitforApproval from '@salesforce/apex/OpportunityUnitSearchHandler.submitforApproval';
import UnitBookTimeExtendApproval from '@salesforce/apex/OpportunityUnitSearchHandler.UnitBookTimeExtendApproval';

import UpdateUnitSellingPrice from '@salesforce/apex/OpportunityUnitSearchHandler.UpdateUnitSellingPrice';
import booking_ShowValidation from '@salesforce/label/c.booking_ShowValidation';
import OppBookingTimerStartFromValue from '@salesforce/label/c.OppBookingTimerStartFromValue'
import getPicklistvalue from "@salesforce/apex/Utilities.getPicklistValues";
import OPPORTUNITY_Direct_indirect_Field from '@salesforce/schema/Opportunity.AgentType__c';

const fields = [OPPORTUNITY_Direct_indirect_Field];
import OppwinReasoninfo from '@salesforce/label/c.Booking_Win_Reason';

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import ExternalStyle from "@salesforce/resourceUrl/externalStyle";
import LightningConfirm from "lightning/confirm";
import LightningAlert from "lightning/alert";


const FIELDS = ['Opportunity.AccountId'];



var actions = [
    { label: 'Delete', name: 'delete' }
];

const columns = [
    { label: 'Installment #', fieldName: 'InstallmentNumber', initialWidth: 180 },
    { label: 'Milestone', fieldName: 'Milestone', editable: true },
    {
        label: 'Proposed Installment %', fieldName: 'ProposedInstallmentPercentage', editable: true
    },
    { label: 'Broker Payout %', fieldName: 'ProposedBrokerPercentage', editable: true },
    {
        label: 'Proposed Installment Date', fieldName: 'ProposedInstallmentDate', type: 'date', editable: true,
        typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
        }
    },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class OpportunityUnitSearch extends NavigationMixin(LightningElement) {
    //Get Opportunity or Lead Ids
    label = {
        MemoDirectCommission,
        MemoIndirectCommission
    };
    redirecPageUrl;
    memoIndirectCommissionAlert = 'Int Commission Percentage should be between 0% and ' + MemoIndirectCommission + '%';
    memoDirectCommissionAlert = 'Broker Commission Percentage should be between 0% and ' + MemoDirectCommission + '%';
    showBudgetModal = false;
    @track columns = columns;
    @track sortBy;
    @track sortDirection;
    @track dataInstallmentLineChanges = [];
    @api recordId;
    unitFinishingVals;
    unitFurnishingVals
    mortgageApplicableVals;
    mortgageBankVals;
    sObjectRecord;
    sObjectRecordType;
    steps = [];
    attachedFiles = [];
    membershipValues = [];
    voucherValues = [];
    unitsToLock = [];
    unitsSelectedList = [];
    pageNumber = 1;
    @track selectedUnits = {};
    isExport = false
    isLoading = true;
    projectList;
    selectedProject;
    buildingList;
    selectedBuilding;
    buildingToPaymentMap = {};
    selectedPaymentOptions = [];
    amountValues = [];
    //selectPaymentPlanId; 
    //selectOfferId;
    currentUnit;
    /* static Filters */
    propertyUsageList;
    unitTypesSetList;
    unitModelSetList;
    floorNumberSetList;
    unitBedRoomsSetList;
    //eligibileforMultiPurposeRoom;
    winReasonOptions;
    projectRecord;
    unitViewSetList;
    currentOffer;
    disableDownload;
    lastCreatedBookingMemoId;
    availableEOIs;
    @track
    unitDataTable;
    unitInventoryDetails;
    registrationValidationMessage = 'Not Allowed';
    blackListEmirateValidation;
    selectedAction;
    fullUrl = 'https://bloomholding--bldevoff.sandbox.lightning.force.com/apex/OfferDetailsPDFController';
    customerName;//='Customer';
    pageNumber = 1;

    @track UnitId;
    @track memoFlow = false;
    @track hidePill = false;
    @track reserveMemoFlowButton = false;
    @track reserveFlowButton = false;
    @track reserveFlow = false;
    @track reserveBookingFlow = false;
    @track exportExcel = false;
    @track prfName;
    userId = strUserId;
    @track isloaded = true;
    @track submitted;
    @track downPaymentReceived;
    @track showSelectDateModal = false;
    @track days = 1;
    @track NumDays = [{ label: 1, value: 1 }, { label: 2, value: 2 }, { label: 3, value: 3 }];
    @track showLoading = false;
    @track accountId;

    @track UnitIdList = [];
    @track paymentList = [];
    @track OfferList = [];
    @track offerListtoPass = [];
    @track paymentListtoPass = [];
    @track unitVsPayment = [];
    @track unitVsPaymentUnitmix = {};
    @track hasSearchKey = false;
    @track UnitTypeVsUnitTypeCount = {};
    diectIndirectValue;
    defaultDirectIndirectvalue = '';
    opportunityRecord;
    @track OppWinReason = '';
    @track singlePaymentSelectcheck;
    @track singlePaymentplanid;
    selectedOfferId;
    @track selectedRowCount = 0;
    @track hasError;
    OppBookingTimerStartFrom
    @track showReqExtendTimeBtn=true;



  

    /* Default methods */
    connectedCallback() {
      
        this.OppBookingTimerStartFrom = OppBookingTimerStartFromValue;
        console.log('OppBookingTimerStartFrom'+this.OppBookingTimerStartFrom);
        console.log('Log: I am Connected call');
        this.gesObjectData();

    }
    renderedCallback() {
        Promise.all([
            loadStyle(this, ExternalStyle)
        ])
        if (this.isExport) {
            this.startDownload();
            this.isExport = false;
        }
        if (this.populateSelectedValsFlag) {
            this.populateSelectedVals();
        }

        if (this.isCssLoaded) return
        this.isCssLoaded = true
        if (!this.redirecPageUrl && this.recordId) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view',
                },
            }).then(url => {
                this.redirecPageUrl = url;
            });
        }

        this.getCustomerNamefn(); //standard wired getRecord functionality not working sometimes
    }

    disconnectedCallback() {

    }

    get ICACheckRequired() {
        return (this.sObjectRecord && this.sObjectRecord.CustomerResidentStatus__c && this.sObjectRecord.CustomerResidentStatus__c === 'Non-Resident');
    }
    /* getters */
    get disablPath() {
        return (this.pageNumber == 1 || this.steps == []);
    }
    get paymentOptionsForReservation() {
        return [
            { label: 'Online', value: 'Online' },
            { label: 'Wire Transfer', value: 'Wire Transfer' },
            { label: 'POS', value: 'POS' },
        ];
    }

    get finishingtypeOptions() {
        return [
            { label: 'Standard Price', value: 'Standard Price' },
            { label: 'Premium Price', value: 'Premium Price' }
        ]
    };

    get paymentAmountOptionsForReservation() {
        return [
            { label: 'Down Payment', value: 'Down Payment' },
            { label: 'Default Amount', value: 'Default Amount' },
            { label: 'Custom Amount', value: 'Custom Amount' },
        ];
    }
    get saleOfferInputParam() {
        var param1_unitToOfferMap = [];
        for (var key in this.selectedUnits) {
            if (this.selectedUnits[key].selectionStatus) {
                let selectedPayments = [];
                if (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated) {
                    for (let i = 0; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                        if (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                            selectedPayments.push(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                        }
                    }
                }
                let tempUnitSelectionObj = {
                    'unitId': key,
                    'offerId': this.selectedUnits[key].offerId,// (this.currentUnit == key ? this.currentOffer : undefined),
                    'designId': this.selectedUnits[key].unitDesignRecordId,
                    'selectedPayments': selectedPayments,
                    'finishingtypeValue': this.selectedUnits[key].finishingtypeValue,
                    'admincludedfee':this.selectedUnits[key].admincludedfee,
                    'amount': this.selectedUnits[key].reservationAmount,
                    'amountType': this.selectedUnits[key].reservationAmountType,
                    'paymentMethod': this.selectedUnits[key].paymentMethod,
                    'multiPurposeAmountApplicable': (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable) ? this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable : false,
                    'unitFinishes': this.selectedUnits[key].unitFinishes,
                    'unitFurnishing': this.selectedUnits[key].unitFurnishing,
                    'mortgageApplicable': this.selectedUnits[key].mortgageApplicable,
                    'mortgageBank': this.selectedUnits[key].mortgageBank

                };
                console.log('tempUnitSelectionObj'+JSON.stringify(tempUnitSelectionObj));
                param1_unitToOfferMap.push(tempUnitSelectionObj);
            }
        }
        console.log(param1_unitToOfferMap);
        return param1_unitToOfferMap;
    }
    get disableProceed() {
        return ((this.OfferWizard || this.AgreementWizard || this.ReservationWizard || this.BookingWizard) && this.pageNumber == 3);
    }
    get disableBack() {
        return ((this.OfferWizard || this.AgreementWizard) && this.pageNumber == 2 && this.sObjectRecordType == 'Unit__c');
    }

    get disableOffer() {
        return (this.totalSelectedUnits < 1);
    }
    get disableMemo() {
        return (this.totalSelectedUnits < 1 /*|| this.totalSelectedUnits > 1*/);
    }
    get disableReserve() {
        return (this.totalSelectedUnits < 1 || (this.registrationValidationMessage != undefined && this.registrationValidationMessage != null && this.registrationValidationMessage != ''));
    }
    get disableBooking() {
        return (this.totalSelectedUnits < 1);
    }
    get showPage1() {
        return this.pageNumber == 1;
    }
    get showPage2() {
        return this.pageNumber == 2
    }
    get showPage3() {
        return this.pageNumber == 3
    }
    get unitWizard() {
        return (this.sObjectRecordType == 'Unit__c');
    }
    get OfferWizard() {
        return (this.selectedAction == 'OFFER');
    }

    get AgreementWizard() {
        return (this.selectedAction == 'BOOKINGAGREEMENT');
    }

    get ReservationWizard() {
        return (this.selectedAction == 'RESERVE');
    }
    get BookingWizard() {
        return (this.selectedAction == 'BOOKING');
    }
    get MemoWizard() {
        return (this.selectedAction == 'MEMO');
    }

    get totalSelectedUnits() {
        //console.log('Log: inside totalSelectedUnits');
        var selectedCountToReturn = 0;
        if (this.selectedUnits) {
            for (var key in this.selectedUnits) {
                if (this.selectedUnits[key].selectionStatus) {
                    selectedCountToReturn++;
                }
            }
        }
        return selectedCountToReturn;
    }

    @track UnitIdtobeUpdate = [];
    @track unitInfowithFinishvalue = [];

    handleFinishingTypeChange(event) {
        this.selectedUnits[this.currentUnit].finishingtypeValue = event.target.value;
        console.log('finishvalue' + JSON.stringify(this.selectedUnits[this.currentUnit]));
        this.generateOffer();

    }
    get selectedUnitList() {


        try {
            let unitsToReturn = [];
            for (var key in this.selectedUnits) {
                if (this.selectedUnits[key].selectionStatus) {
                 console.log('admincludedfee'+JSON.stringify(this.selectedUnits[key].admincludedfee));
                    // this.selectedUnits[key].finishingtypeValue='Standard Price';
                    this.selectedUnits[key].calculatedPayment = undefined;
                    unitsToReturn.push(this.selectedUnits[key]);
                }
            }
            console.log('insidegetSelectunit' + JSON.stringify(this.selectedUnits));

            return unitsToReturn;
        } catch (e) {
            console.log(e.message)
        }
    }
    /* get budgetCheckProfileAllowed() {
        return (this.prfName == 'System Administrator' || this.prfName == 'Sales Manager')
    } */

    get totalSelectedUnitProject() {
        var selectedCountToReturn = 0;
        const filteredUnitsProjects = this.selectedUnitList.reduce((acc, current) => {
            const x = acc.find(item => item.ProjectName === current.ProjectName);
            if (!x) {
                return acc.concat([current]);
            } else {
                return acc;
            }
        }, []);
        selectedCountToReturn = filteredUnitsProjects.length;
        return selectedCountToReturn;
    }

    get selectedUnitPaymentList() {
        let unitsToReturn = [];
        for (var key in this.selectedUnits) {
            if (this.selectedUnits[key].selectionStatus) {
                unitsToReturn.push(this.selectedUnits[key]);
            }
        }
        return unitsToReturn;
    }
    disableBookingButton = true;
    tempButtonCheck() {
        // console.log(this.template.querySelector(".icaVerificationConfirm").files);
    }
    fileData;
    handleBookingButtonDisplay(event) {
        // console.log('this.fileData');
        if (event.target.files) {
            const file = event.target.files[0]
            var reader = new FileReader()
            reader.onload = () => {
                var base64 = reader.result.split(',')[1]
                this.fileData = {
                    'filename': file.name,
                    'base64': base64,
                    'recordId': this.recordId
                }
                this.isLoading = true;
            }

            reader.onloadend = () => {
                this.isLoading = false;
                if (this.template.querySelector(".bookingConfirmationWinReason") && this.template.querySelector(".bookingConfirmationWinReason").value && this.template.querySelector(".bookingConfirmationConfirm") && this.template.querySelector(".bookingConfirmationConfirm").checked && (!this.ICACheckRequired || this.fileData)) {
                    this.disableBookingButton = true;
                } else {
                    this.disableBookingButton = true;
                }
            }

            reader.readAsDataURL(file);
        }
        // console.log('this.fileData');
        // console.log(this.fileData);
        if (this.template.querySelector(".bookingConfirmationWinReason") && this.template.querySelector(".bookingConfirmationWinReason").value && this.template.querySelector(".bookingConfirmationConfirm") && this.template.querySelector(".bookingConfirmationConfirm").checked && (!this.ICACheckRequired || this.fileData)) {
            this.disableBookingButton = false;
        } else {
            this.disableBookingButton = false;
        }
    }
    /* Apex Call Methods */

    navigateToBookingMemoRecord() {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.lastCreatedBookingMemoId,
                objectApiName: 'BookingMemo__c',
                actionName: 'view'

            }
        });
    }


    @wire(getRecord, {
        recordId: strUserId,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.prfName = data.fields.Profile.value.fields.Name.value;
        }
    }



    @wire(getWinReasonPickList)
    getWinReasonValues({ error, data }) {
        if (data) {
            this.winReasonOptions = data;
            this.OppWinReason = OppwinReasoninfo;


        } else if (error) {
            this.winReasonOptions = undefined;
        }
    }



    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.showBudgetModal = true;
    }
    closeModal(event) {
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.showBudgetModal = event.detail.isOpen;
    }
    @track uploadedFileNames = [];
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        this.uploadedFileNames = [];
        for (let i = 0; i < uploadedFiles.length; i++) {
            this.uploadedFileNames.push({ 'name': event.detail.files[i].name, 'documentId': event.detail.files[i].documentId });
            this.attachedFiles.push(uploadedFiles[i].documentId);
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: uploadedFiles.length + ' Files uploaded Successfull',
                variant: 'success',
            }),

        );
    }
    @track finishtypeStringvalue;
    handleAttachmentRemove(event) {
        var tempFiles = [];
        this.attachedFiles = [];
        for (let i = 0; i < this.uploadedFiles.length; i++) {
            if (event.target.name != this.uploadedFileNames[i].documentId) {
                tempFiles.push({ 'name': this.uploadedFileNames[i].name, 'documentId': this.uploadedFileNames[i].documentId });
                this.attachedFiles.push(this.uploadedFileNames[i].documentId);
            }
        }
        this.uploadedFileNames = tempFiles;
    }


    async handleMenuAction(event) {



        if (event.target.name == 'OFFER') {



            console.log('Inside Offer selection ' + this.pageNumber);
            this.selectedAction = event.target.name;
            this.memoFlow = false;
            this.hidePill = false;
            this.reserveFlow = false;
            this.reserveBookingFlow = false;
            this.steps = []
            this.steps.push({ label: 'Select Unit', value: 1 });
            this.steps.push({ label: 'Select Plan and Offer', value: 2 });
            this.steps.push({ label: 'Send Offer', value: 3 });
            this.pageNumber = this.pageNumber + 1;
            this.reserveMemoFlowButton = false;

            console.log('Inside Offer selection done');
            console.log(JSON.stringify(this.selectedUnits))

            this.generateOffer();
        }


        else if (event.target.name == 'BOOKINGAGREEMENT') {
            debugger;
            console.log('Inside Offer selection ' + this.pageNumber);
            this.selectedAction = event.target.name;
            this.memoFlow = false;
            this.hidePill = false;
            this.reserveFlow = false;
            this.reserveBookingFlow = false;
            this.steps = []
            this.steps.push({ label: 'Select Unit', value: 1 });
            this.steps.push({ label: 'Select Plan and Offer', value: 2 });
            this.steps.push({ label: 'Send Booking Agreement', value: 3 });
            this.pageNumber = this.pageNumber + 1;
            this.reserveMemoFlowButton = false;

            console.log('Inside Offer selection done');
            console.log(JSON.stringify(this.selectedUnits))
        }


        else if (event.target.name == 'BACK') {

            console.log(this.selectedUnits)
            this.pageNumber = this.pageNumber - 1;
            this.reserveMemoFlowButton = false;
            this.reserveFlowButton = false;
            if (this.pageNumber == 1) {

                this.clearStatisFilters();
                this.handleFilterChange();
            }
        } else if (event.target.name == 'FORWARD') {

         /*    if(this.BookingWizard){
                for (var key in this.selectedUnits) {
                    if (this.selectedUnits[key].salesOfferDetails.unitRecord) {
                        let unitType = this.selectedUnits[key].salesOfferDetails.unitRecord.UnitType__c;
                        console.log('UnitTypeVsUnitTypeCount:', JSON.stringify(unitType));
                        // Check if the unitType is already in the count object
                        if (this.UnitTypeVsUnitTypeCount[unitType]) {
                            // If it exists, increment the count
                            this.UnitTypeVsUnitTypeCount[unitType]++;
                        } else {
                            // If it doesn't exist, initialize the count to 1
                            this.UnitTypeVsUnitTypeCount[unitType] = 1;
                        }
        
                    }
                }
                let paymentPlanTypeMap;
       
       
        
         
        

                console.log('selectedUNitMap:', JSON.stringify(this.UnitTypeVsUnitTypeCount));
                 console.log('selectedUNitMap'+JSON.stringify(this.unitVsPayment));
                const PaymentDetailUnitMix = this.selectedUnits[this.currentUnit].salesOfferDetails.paymentIdvsUnitMixMap;
                for (var key in PaymentDetailUnitMix) {
                    console.log('key' + JSON.stringify(PaymentDetailUnitMix[key]));
                    if(key===this.unitVsPayment[0].paymentId){
                        paymentPlanTypeMap = PaymentDetailUnitMix[key];
                    }
                }
                console.log('paymentplanmap' + JSON.stringify(paymentPlanTypeMap));
                const unitTypeVsCount = new Map();
                
        
                for (const [key, value] of Object.entries(this.UnitTypeVsUnitTypeCount)) {
                   
                    unitTypeVsCount.set(key,value);
                   
                  }
                  console.log('unitTypeVsCount'+unitTypeVsCount);
                  
                  
                    paymentPlanTypeMap.forEach(item => {
                        for (const [key, value] of Object.entries(item)) {
                            console.log('key'+key+'value'+value);
                            if(unitTypeVsCount.get(key)>value){
                                const result = LightningConfirm.open({
                                    message: "UnitMix is not achieved,do you still want to proceed?",
                                    variant: "default",
                                    label: "Unit Mix"
                                });
                            }
                        }
                       
                    }) 
               
                



            }
 */
            let unitInfos = {};

            for (var key in this.selectedUnits) {
                if (this.selectedUnits[key].selectionStatus) {

                    if (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.unitRecord) {
                        unitInfos[this.selectedUnits[key].salesOfferDetails.unitRecord.Id] = this.selectedUnits[key].finishingtypeValue;
                        console.log('unitInfos' + JSON.stringify(unitInfos));

                    }
                }
            }

            if (this.BookingWizard) {

                UpdateUnitSellingPrice({ unitInfo: unitInfos })
                    .then(result => {
                        console.log('result' + JSON.stringify(result));


                    }).catch(error => {
                        this.error = error;
                        console.log('this.error' + JSON.stringify(this.error));

                    })
            }
            this.generateOffer();

            this.disableBookingButton = false;

            this.isLoading = true;


            /*    if ((this.ReservationWizard || this.BookingWizard) && !(await performBudgetCheck({ saleOfferInputParam: this.saleOfferInputParam, opportunityId: this.recordId }))) {
                  
                   const evt = new ShowToastEvent({
                       title: 'Budget Check Failed',
                       message: 'Budget Check Failed',
                       variant: 'error',
                   });
                   this.dispatchEvent(evt);
                   this.isLoading = false;
                   return;
               } */
            console.debug('Proceed with Offer lands here');
            for (var key in this.selectedUnits) {
                if (this.selectedUnits[key].selectionStatus) {
                    var selectedPaymentPlanCounter = 0;
                    if (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated) {
                        for (let i = 0; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                            if (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                                selectedPaymentPlanCounter++;
                            }
                        }
                    }
                    if (selectedPaymentPlanCounter != 1 && (this.ReservationWizard || this.BookingWizard)) {

                        const evt = new ShowToastEvent({
                            title: 'Invalid Payment Plans Selection',
                            message: 'Please select only 1 payment plan for the ' + this.selectedAction + ' process',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading = false;
                        return;







                    } else if (selectedPaymentPlanCounter == 0 && (this.OfferWizard || this.AgreementWizard)) {
                        const evt = new ShowToastEvent({
                            title: 'Invalid Payment Plans Selection',
                            message: 'Please select atleast 1 payment plan for the ' + this.selectedAction + ' process',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading = false;
                        return;
                    }




                }
            }
            // Commented by Sreelakshmi SK
            /*  if(this.reserveFlow && this.selectedAction=='RESERVE'){
                 
                 this.reserveMemoFlowButton = true;
                 this.reserveFlowButton = true;
             }else{
                 this.reserveMemoFlowButton = false;
                 this.reserveFlowButton = false;
             } */

            if (this.pageNumber === 2) {
                this.reserveMemoFlowButton = true;
            } else {
                this.reserveMemoFlowButton = false;
            }

            this.pageNumber = this.pageNumber + 1;


            this.isLoading = false;
        }

        //Commented by Sreelakshmi SK-- START
        /* else if(event.target.name == 'FORWARDMEMO'){

            if(this.MemoWizard){
                //Validations
                var isError =false;
                this.template.querySelectorAll('lightning-input').forEach(element => {
                    element.reportValidity();
                    if((element.required && !element.value) || !element.checkValidity() ){
                        isError =true;
                    }
                });
        
                if(isError){
                    const evt = new ShowToastEvent({
                        title: 'Validation Error',
                        message: 'Please correct all validation errors before proceeding.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return;
                }
                this.isLoading=true;
                await this.memoForward();
            }
        } */
        /*  else if(event.target.name == 'EXPORT'){
             this.isExport=true;
             
         }*/
        else if (event.target.name == 'REQUESTOASSIGN') {
            this.isloaded = false;
            this.unitsSelectedList = [];

            this.selectedUnitList.forEach(element => {
                this.unitsSelectedList.push(element.unitId);

            });

            if (this.unitsSelectedList.length > 1) {
                const evt = new ShowToastEvent({
                    message: 'Please select a single unit',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isloaded = true;
            }

            else {
                this.unitsSelectedList.forEach(element => {
                    this.UnitId = element;
                });

                this.showSelectDateModal = true;

                /* updateUserField({ selectedUnit: this.UnitId })
                     .then(reult => {
                         this.isloaded = true;
                         
 
                     })
                     .catch(error => {
                     });
 
                 let obj = new Object();
                 obj.sobjectType = 'Unit__c';
                 obj.Id = this.UnitId;
 
                 submitforApproval({ selectedUnit: obj })
                     .then(reult => {
                         if (reult == 'Success') {
                             const evt = new ShowToastEvent({
                                 title: 'Submitted for Approval',
                                 message: 'Unit has been submitted for Approval',
                                 variant: 'success',
                             });
                             this.dispatchEvent(evt);
                         }
                        
 
                     })
                     .catch(error => {
                         const evt = new ShowToastEvent({
                             message: 'Unit already submitted for Approval',
                             variant: 'Error',
                         });
                         this.dispatchEvent(evt);
                     });*/
            }

        }
        else if (event.target.name == 'RESERVE' || event.target.name == 'BOOKING') {
            var targetEventName = event.target.name;
            this.isLoading = true;
            if (booking_ShowValidation == 'true')
                await this.validateRegistrationEliginility();
            await this.checkRegistedEmirateBlackList();
            //alert(this.blackListEmirateValidation);
            console.log(this.registrationValidationMessage + ' -' + booking_ShowValidation);
            this.isLoading = false;
            //alert(this.blackListEmirateValidation);
            if ((this.registrationValidationMessage == 'Allowed' || booking_ShowValidation != 'true') && this.blackListEmirateValidation=='Allowed') {

                this.unitsToLock = [];
                this.selectedUnitList.forEach(element => {
                    this.unitsToLock.push(element.unitId);
                });
                var lockSuccess = await lockUnits({ unitIds: this.unitsToLock }).then().catch(error => {
                    console.log(error)

                });

                if (lockSuccess != 'Success') {
                    const evt = new ShowToastEvent({
                        title: 'Unit Unavailable for Booking',
                        message: lockSuccess,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    return;
                }
                this.isLoading = true;
                this.selectedAction = targetEventName;
                this.reserveFlowButton = false;
                this.memoFlow = false;
                this.hidePill = true;
                this.reserveFlow = true;
                this.reserveBookingFlow = true;
                this.steps = []


                //await lockUnits({unitIds: this.unitsToLock});
                this.steps.push({ label: 'Select Unit', value: 1 });
                this.steps.push({ label: 'Select Plan and Offer', value: 2 });
                if (targetEventName == 'RESERVE') {
                    this.steps.push({ label: 'Reserve', value: 3 });
                } else {
                    this.steps.push({ label: 'Book', value: 3 });
                }
                this.pageNumber = this.pageNumber + 1;
            }
        }
        else if (event.target.name == 'BOOKING') {
            this.reserveMemoFlowButton = false;
            this.reserveFlowButton = false;
            this.selectedAction = event.target.name;
            this.memoFlow = false;
            this.hidePill = true;
            this.reserveFlow = false;
            this.reserveBookingFlow = true;
            this.steps = []
            this.steps.push({ label: 'Select Unit', value: 1 });
            this.steps.push({ label: 'Select Plan and Offer', value: 2 });
            this.steps.push({ label: 'Book', value: 3 });
            this.pageNumber = this.pageNumber + 1;
        }
        //Commented by Sreelakshmi SK-- START
        /* else if(event.target.name =='MEMO'){
            this.reserveMemoFlowButton = true;
            this.reserveFlowButton = false;
            this.selectedAction=event.target.name;
            this.memoFlow= true;
            this.hidePill = true;
            this.reserveBookingFlow = false;
            this.reserveFlow = false;
            this.steps=[]
            this.dicrectCommissionUpdate();
            this.populateSelectedVals();
            this.steps.push({ label: 'Unit Selection', value: 1 });
            this.steps.push({ label: 'Booking Memo', value: 2 });
            this.pageNumber = this.pageNumber+1;
        } */ //Commented by Sreelakshmi SK-- END


    }
    //methods for holdpopup
    closeselectDateModal() {
        this.showSelectDateModal = false;
        this.isloaded = true;

    }



    changeHandler(event) {
        const field = event.target.name;
        if (field === 'optionSelect') {
            this.days = event.target.value;
        }
    }

    /* handleDaysEntered(event){
        this.days=event.detail.value;
        console.log('days:'+this.days);
    } */

    submitforHoldApproval() {

        this.showLoading = true;
        if (this.days > 3) {
            const evt = new ShowToastEvent({
                message: 'Number of days to Hold cannot be more than 3.',
                variant: 'Error',
            });

            this.dispatchEvent(evt);
            this.showLoading = false;
        }
        else {

            updateUserField({ selectedUnit: this.UnitId, noDays: this.days })
                .then(reult => {
                    this.isloaded = true;



                })
                .catch(error => {
                });

            let obj = new Object();
            obj.sobjectType = 'Unit__c';
            obj.Id = this.UnitId;
            

            submitforApproval({ selectedUnit: obj })
                .then(reult => {
                    if (reult == 'Success') {
                        const evt = new ShowToastEvent({
                            title: 'Submitted for Approval',
                            message: 'Unit has been submitted for Approval',
                            variant: 'success',
                        });
                        this.dispatchEvent(evt);
                        this.showLoading = false;
                        this.showSelectDateModal = false;

                    }


                })
                .catch(error => {
                    /* const evt = new ShowToastEvent({
                        message: 'Unit already submitted for Approval',
                        variant: 'Error',
                    });
                    this.dispatchEvent(evt); */
                    this.showToast('Something went wrong', error.body.message, 'error');
                    this.showLoading = false;
                    this.showSelectDateModal = false;
                });

        }

    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    startDownload() {
        var htmlBody = this.template.querySelector('table');
        var downloadLink = document.createElement("a");
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,' + htmlBody.outerHTML.replace(/ /g, '%20');
        //downloadLink.download = 'ProtocolRequest_'+date+' '+time+'.xls';
        downloadLink.download = this.sObjectRecord.Project__c + '.xls';
        downloadLink.click();
        this.isExport = false;
    }

    //commented by Sreelakhmi SK
    /* async dicrectCommissionUpdate(){
        let MemoDirectCommissionWithBroker = await getConstant({messageName: 'MemoDirectCommissionWithBroker'});
        let MemoDirectCommissionWithoutBroker =  await getConstant({messageName: 'MemoDirectCommissionWithoutBroker'});
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                let pd = JSON.parse(JSON.stringify(this.selectedUnits[key]));
                let brokerCommissionPercentage;
                if (this.sObjectRecord.BrokerAgencyAccount__c != null) {
                    brokerCommissionPercentage = MemoDirectCommissionWithBroker;
                    pd.intCommissionPercentageField = Number(brokerCommissionPercentage.ConstantValue__c);
                    pd.intCommissionAmountField = Number(pd.unitPrice) * Number(brokerCommissionPercentage.ConstantValue__c) / 100;              
                    this.selectedUnits[key] = pd;
                }
                else{
                    brokerCommissionPercentage = MemoDirectCommissionWithoutBroker;
                    pd.intCommissionPercentageField = Number(brokerCommissionPercentage.ConstantValue__c);
                    pd.intCommissionAmountField = Number(pd.unitPrice) * Number(brokerCommissionPercentage.ConstantValue__c) / 100;              
                    this.selectedUnits[key] = pd;
                }
            }
        }
    } */

    async addProposedInstallmentLineChanges() {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        let newTableData = [];

        let installmentCount = 1;
        this.proposedInstallmentRateField = (this.proposedInstallmentRateField == undefined || this.proposedInstallmentRateField == null || this.proposedInstallmentRateField == '') ? '0' : this.proposedInstallmentRateField;
        //this.buildingNameField !== null && this.buildingNameField !== undefined
        this.proposedBrokerPayoutField = this.proposedBrokerPayoutField ? this.proposedBrokerPayoutField : 0;

        //Validate input Fields
        if (this.proposedMilestoneField !== '' && this.proposedInstallmentRateField !== '' && this.proposedInstallmentDateField !== '' &&
            this.proposedMilestoneField !== null && this.proposedInstallmentRateField !== null && this.proposedInstallmentDateField !== null &&
            this.proposedMilestoneField !== undefined && this.proposedInstallmentRateField !== undefined && this.proposedInstallmentDateField !== undefined && this.proposedInstallmentRateField != 0 &&
            this.proposedInstallmentNumberField !== undefined && this.proposedInstallmentNumberField !== null && this.proposedInstallmentNumberField !== '') {
            let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
            let percentageTotal = 0;
            let brokerPercentageTotal = 0;
            for (let i = 0; i < pd.dataInstallmentLineChanges.length; i++) {
                percentageTotal += pd.dataInstallmentLineChanges[i].ProposedInstallmentPercentage ? Number(pd.dataInstallmentLineChanges[i].ProposedInstallmentPercentage) : 0;
                brokerPercentageTotal += pd.dataInstallmentLineChanges[i].ProposedBrokerPercentage ? Number(pd.dataInstallmentLineChanges[i].ProposedBrokerPercentage) : 0;
            }
            percentageTotal = percentageTotal + Number(this.proposedInstallmentRateField);
            brokerPercentageTotal = brokerPercentageTotal + (this.proposedBrokerPayoutField ? Number(this.proposedBrokerPayoutField) : 0);

            if (Number(percentageTotal) > 100) {
                const evt = new ShowToastEvent({
                    title: 'Installment Lines',
                    message: 'Installment percentage must sum up to 100%',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            } else if (Number(brokerPercentageTotal) > 100) {
                const evt = new ShowToastEvent({
                    title: 'Installment Lines',
                    message: 'Broker Payout percentage must sum up to 100%',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            } else {

                for (let i = 0; i < pd.dataInstallmentLineChanges.length; i++) {

                    if (this.proposedInstallmentNumberField == pd.dataInstallmentLineChanges[i].InstallmentNumber) {
                        installmentCount++;
                        pd.dataInstallmentLineChanges[i].InstallmentNumber = installmentCount;
                        installmentCount++;
                    } else {
                        pd.dataInstallmentLineChanges[i].InstallmentNumber = installmentCount;
                        installmentCount++;
                    }
                    newTableData.push(pd.dataInstallmentLineChanges[i]);
                }
                newTableData.push({ Milestone: this.proposedMilestoneField, InstallmentNumber: this.proposedInstallmentNumberField, ProposedInstallmentPercentage: this.proposedInstallmentRateField, ProposedBrokerPercentage: (this.proposedBrokerPayoutField == 0 ? undefined : this.proposedBrokerPayoutField), ProposedInstallmentDate: this.proposedInstallmentDateField });
                pd.dataInstallmentLineChanges = newTableData;
                this.selectedUnits[this.currentUnit] = pd;
                this.handleSortData();
                this.proposedMilestoneField = '';
                this.proposedInstallmentRateField = '';
                this.proposedInstallmentDateField = '';
                this.proposedInstallmentNumberField = '';
                this.proposedBrokerPayoutField = '';

            }
        } else {
            const evt = new ShowToastEvent({
                title: 'Missing Fields',
                message: 'Kindly fill all fields before adding the installment.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
    }

    draftValues = [];
    handleSave(event) {
        let newTableData = [];
        //let percentageTotal= 0;

        const updatedFields = event.detail.draftValues;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        for (let i = 0; i < pd.dataInstallmentLineChanges.length; i++) {
            //percentageTotal += Number(pd.dataInstallmentLineChanges[i].ProposedInstallmentPercentage);
            newTableData.push(pd.dataInstallmentLineChanges[i]);
        }
        for (let i = 0; i < newTableData.length; i++) {
            for (let j = 0; j < updatedFields.length; j++) {
                if (newTableData[i].InstallmentNumber == updatedFields[j].InstallmentNumber) {

                    if (updatedFields[j].ProposedInstallmentPercentage != null) {
                        if (Number(updatedFields[j].ProposedInstallmentPercentage) == 0) {
                            newTableData.splice(i, 1);
                            break;
                        } else {
                            newTableData[i].ProposedInstallmentPercentage = updatedFields[j].ProposedInstallmentPercentage;
                        }
                    }
                    if (updatedFields[j].ProposedInstallmentDate != null) {
                        newTableData[i].ProposedInstallmentDate = updatedFields[j].ProposedInstallmentDate;
                    }
                    if (updatedFields[j].Milestone != null) {
                        newTableData[i].Milestone = updatedFields[j].Milestone
                    }
                    if (updatedFields[j].ProposedBrokerPercentage != null) {
                        newTableData[i].ProposedBrokerPercentage = updatedFields[j].ProposedBrokerPercentage;
                    }
                }

            }
        }

        pd.dataInstallmentLineChanges = newTableData;
        this.selectedUnits[this.currentUnit] = pd;
        // console.log(pd);

        this.handleSortData();
        this.draftValues = [];
    }

    handleRowAction(event) {
        const recId = event.detail.row;
        const actionName = event.detail.action.name;

        if (actionName === 'delete') {
            let newTableData = [];

            let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));

            for (let i = 0; i < pd.dataInstallmentLineChanges.length; i++) {
                newTableData.push(pd.dataInstallmentLineChanges[i]);
            }
            for (let i = 0; i < newTableData.length; i++) {
                if (newTableData[i].InstallmentNumber == recId.InstallmentNumber) {
                    newTableData.splice(i, 1);
                }
            }
            pd.dataInstallmentLineChanges = newTableData;
            this.selectedUnits[this.currentUnit] = pd;
            this.handleSortData();
        }
    }


    gesObjectData() {
        getsObjectType({ recordID: this.recordId })
            .then(data => {
                console.log('Log: data call');
                for (var key in data) {
                    this.sObjectRecordType = key;
                    this.sObjectRecord = data[key];
                }
                if (this.sObjectRecordType == 'Opportunity') {
                    console.log('Log: calling populateprojects');
                    this.populateProjects();

                    this.voucherMembershipValuesChange();
                    //this.getOpportunityDetails();
                } else if (this.sObjectRecordType == 'Unit__c') {
                    console.log('Log: calling unit population');
                    this.selectedUnits[this.sObjectRecord.Id] = {
                        'selectionStatus': true,
                        'unitId': this.sObjectRecord.Id,
                        'unitName': this.sObjectRecord.Name,
                        'salesOfferDetails': undefined
                    };
                    this.pageNumber = 2;
                    //this.OfferWizard=true;
                    this.selectedAction = 'OFFER';
                    // console.log(' this.selectedUnits '+ this.selectedUnits);
                }

            })
            .catch(error => {
                // console.log('Unable to sObject data ==>'+ JSON.stringify(error));
                this.sObjectRecordType = undefined;
                this.sObjectRecord = undefined;
                this.isLoading = false;
            });
    }//to get accountId from Opportunity
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.accountId = data.fields.AccountId.value;
            this.isOpportunity = true;

        } else if (error) {
            // Handle error
        }
    }
     

    async checkRegistedEmirateBlackList(){
       
    this.blackListEmirateValidation ='Not Allowed';
    await OppBlackListEirateValidation({recordId:this.recordId})
    .then(result=>{
      
        this.result = result;
      
        if(this.result!=null && this.result!=''  && this.result!=undefined){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Warning!',
                message: result,
                variant: 'warning',
                mode: 'sticky'
            })
        );
    }
    else{
        this.blackListEmirateValidation = 'Allowed';
    }
    }).catch(error=>{
        this.error = error;
    })
}


    async validateRegistrationEliginility() {
        
        this.registrationValidationMessage = 'Not Allowed';
        getRecordNotifyChange([{ recordId: this.recordId }]);
        let tempMsg1 = '';
        let tempMsg2 = '';

        await provideRegistrationValidation({ recordId: this.accountId })
            .then(data => {

                if (data) {
                    tempMsg1 = data;
                }

            }).catch(error => {
                tempMsg1 = null;

            });
        await provideRegistrationValidation({ recordId: this.recordId }).then(data => {
            if (data) {
                tempMsg2 = data;
            }

        }).catch(error => {
            tempMsg2 = '';
        });

        if (tempMsg1 || tempMsg2) {
            let msg1 = tempMsg1 ? '#Account# ' + tempMsg1 : '';
            let msg2 = tempMsg2 ? '#Opportunity#: ' + tempMsg2 : '';
            this.registrationValidationMessage = msg1 + '\n' + msg2;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning!',
                    message: 'Please update ' + this.registrationValidationMessage + ' For Booking.',
                    variant: 'warning',
                    mode: 'sticky'
                })
            );

        } else {

            this.registrationValidationMessage = 'Allowed';
        }

       
    }


    /*  validateRegistrationEliginility() {
         getRegistrationValidation({ opportunityId: this.recordId })
             .then(data => {
                 this.registrationValidationMessage = data;
             }).catch(error => {
                 // console.log('Unable to Registration elligibility ==>'+ JSON.stringify(error));
                 this.registrationValidationMessage = 'Not Allowed';
                 this.isLoading = false;
             });
     } */

    populateProjects() {
        getAllProjects()
            .then(data => {
                console.log('Log: calling data of getallprojects');
                this.projectList = data;
                for (let i = 0; i < data.length; i++) {

                    // console.log(this.sObjectRecord.Project__c);
                    // console.log(data[i].label);
                    if (this.sObjectRecord && this.sObjectRecord.Project__c && data[i].label == this.sObjectRecord.Project__c) {
                        console.log('Log: calling populateprojects');
                        this.selectedProject = data[i].value;
                        break;
                    }
                }
                if (this.selectedProject) {
                    this.populateBuildings();
                } else {
                    this.isLoading = false;
                }

            })
            .catch(error => {
                // console.log('Unable to fetch Project data ==>'+ JSON.stringify(error));
                this.projectList = undefined;
                this.isLoading = false;
            });
    }


    async populateBuildings() {


        console.log('Log: calling getAllBuildings');
        getAllBuildings({ projectId: this.selectedProject })
            .then(data => {
                this.buildingList = data;
                console.log('Log: calling selectedBuilding');
                this.selectedBuilding = (data && data[0] && data[0].value) ? data[0].value : '';
                console.log('Log: selectedBuilding ' + this.selectedBuilding);

                console.log('Log: Calling populateUnitData');
                this.populateUnitData();
                this.isLoading = false;
                console.log('Log: Calling populateUnitData done');
            })
            .catch(error => {
                // console.log('Unable to fetch Building data ==>'+ JSON.stringify(error));
                this.buildingList = undefined;
                this.isLoading = false;
            });
    }
    sendSalesOfferEmail(event) {
        this.isLoading = true;
        var buttonName = event.target.name;
        console.log(buttonName);
        var singleUnitIdToSend = event.target.dataset.unitId;
        console.log('this.saleOfferInputParam' + this.saleOfferInputParam);
        sendSalesOfferPDF({ saleOfferInputParam: this.saleOfferInputParam, opportunityId: this.recordId, customerName: this.customerName, singleUnitId: singleUnitIdToSend })
            .then(data => {

                this.isLoading = false;
                const evt = new ShowToastEvent({
                    title: 'Email Confirmation',
                    message: 'Email have been sent successfully.',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                //redirect to opportunity, once user clicks on send All button
                //Else do not redirect
                /* if (singleUnitIdToSend == undefined || singleUnitIdToSend == null || singleUnitIdToSend == '') {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            objectApiName: 'Opportunity',
                            actionName: 'view'

                        }
                    });
                } */
            })
            .catch(error => {
                // console.log('sending email failed'+ JSON.stringify(error));
                this.isLoading = false;
                const evt = new ShowToastEvent({
                    title: 'Email Confirmation',
                    message: 'Sending email failed.',
                    variant: 'error',
                });
                this.dispatchEvent(evt);

            });
    }



    sendBookingAgreementEmail(event) {
        this.isLoading = true;

        sendBookingAgreementAttachment({
            oppId: this.recordId,
            customerName: this.customerName,
            unitlist: this.UnitIdList,
            paymentList: this.paymentListtoPass,
            offerList: this.offerListtoPass,
            paymentjsonString: JSON.stringify(this.unitVsPayment)

        })
            .then(data => {

                this.isLoading = false;
                const evt = new ShowToastEvent({
                    title: 'Email Confirmation',
                    message: 'Email have been sent successfully.',
                    variant: 'success',
                });
                this.dispatchEvent(evt);

            })
            .catch(error => {
                this.isLoading = false;
                const evt = new ShowToastEvent({
                    title: 'Email Confirmation',
                    message: 'Sending email failed.',
                    variant: 'error',
                });
                this.dispatchEvent(evt);

            });
    }


    reserveSelectedUnit() {
        console.log('entered reserveSelectedUnit');
        var winReasonValue = this.template.querySelector(".bookingConfirmationWinReason") ? this.template.querySelector(".bookingConfirmationWinReason").value : '';
        var selectedEOI = this.template.querySelector(".eoi") ? this.template.querySelector(".eoi").value : '';
        getRecordNotifyChange([{ recordId: this.recordId }]);
        reserveUnit({ saleOfferInputParam: this.saleOfferInputParam, opportunityId: this.recordId, action: this.selectedAction, winReason: winReasonValue, selectedEOI: selectedEOI, downPayment: this.downPaymentReceived, SelectedUnitCount: this.selectedRowCount })
            .then(data => {

                var tempActionName = (this.selectedAction == 'BOOKING') ? 'Booking' : 'Reservation';
                if (data && data['result'] && data['result'] == 'success') {
                    console.log('entered if condition');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            objectApiName: 'Opportunity',
                            actionName: 'view'

                        }
                    });
                    //Hard Refresh
                    setTimeout(() => {
                        window.location.href = this.redirecPageUrl;
                    }, 500);
                } else if (data && data['result']) {
                    console.log('entered else if');
                    const evt = new ShowToastEvent({
                        title: tempActionName + ' Failed',
                        message: tempActionName + ' failed ' + data['result'],
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                } else {
                    console.log('entered else');
                    const evt = new ShowToastEvent({
                        title: tempActionName + ' Failed',
                        message: tempActionName + ' failed ' + data,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
                this.isLoading = false;
                //getRecordNotifyChange([{recordId: this.recordId}]);

            })
            .catch(error => {

                console.log('Unable to reserve selected unit ==>' + JSON.stringify(error));
                var tempActionName = (this.selectedAction == 'BOOKING') ? 'Booking' : 'Reservation';
                const evt = new ShowToastEvent({
                    title: tempActionName + ' Failed',
                    message: tempActionName + ' failed ' + error.message,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            });
    }

    generateOffer() {

        console.log('Inside generate Offer');
       console.log('saleOfferInputParam'+JSON.stringify(this.saleOfferInputParam));

        generateSalesOffer({ saleOfferInputParam: this.saleOfferInputParam, opportunityId: this.recordId, SelectedUnitCount: this.selectedRowCount })
            .then(data => {
                console.log('dataoffer' + JSON.stringify(data));

               
                this.selectedUnits[this.currentUnit].salesOfferDetails = data[this.currentUnit];

                console.log('finsivalueinsidegener' + JSON.stringify(this.selectedUnits[this.currentUnit]));

                this.availableEOIs = undefined;
                for (var key in this.selectedUnits) {

                    if (this.selectedUnits[key].selectionStatus) {


                        this.selectedUnits[key].salesOfferDetails = data[key];
                        console.log('availablePaymentplan' + JSON.stringify(this.selectedUnits[key].salesOfferDetails.paymentIdvsUnitMixMap));
                        if (data[key].availableEOIs) {
                            this.availableEOIs = data[key].availableEOIs;
                        }
                    }
                }

                console.log('Inside generate Sales Offer call done');

                console.log(data);
                //this.currentOffer=data[this.currentUnit];
                if (this.memoFlow && this.memoOfferChaage) {
                    this.handleExistingOfferChange();
                    this.memoOfferChaage = false;
                }

                this.isLoading = false;
            })
            .catch(error => {
                console.log('Unable to Payment Plan for given Building/Unit==>' + JSON.stringify(error));
                this.isLoading = false;
            });
    }

    async populateUnitData() {
        console.log('Log: inside populateUnitData');
        this.exportExcel = false;
        console.log('Log: calling getUnitDetails see this.selectedbuilding come or no : ' + this.selectedBuilding);

        await getUnitDetails({ buildingsId: this.selectedBuilding, directIndirectvalue: this.opportunityDirectindirectvalue,opportunityId:this.recordId })
            .then(data => {
                
                console.log('Log: calling getUnitDetails inside data ' + JSON.stringify(data));
                this.propertyUsageList = data.propertyUsageList;
                console.log('Log: calling getUnitDetails propertyUsageList');
                this.unitTypesSetList = data.unitTypesSetList;
                console.log('Log: calling getUnitDetails unitType');
                this.unitModelSetList = data.unitModelSetList;
                this.floorNumberSetList = data.floorNumberSetList;
                this.unitBedRoomsSetList = data.unitBedRoomsSetList;
                this.unitViewSetList = data.unitViewSetList;
                this.unitInventoryDetails = data.unitDetailList;
                console.log('Log: calling clearStatisFilters');
                this.clearStatisFilters();
                console.log('Log: calling handleFilterChange');
                this.handleFilterChange();
                console.log('Log: calling this.unitInventoryDetails.length');
                //this.checkEligiblity();
                if (this.unitInventoryDetails.length > 0) {
                    console.log('Log: calling inside if cond unitInventoryDetails.length' + this.unitInventoryDetails.length);
                    this.exportExcel = true;
                } else {
                    console.log('Log: calling inside elsif cond unitInventoryDetails.length');
                    const evt = new ShowToastEvent({
                        title: 'Units',
                        message: 'No unit available for selected filter criteria ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
                this.isLoading = false;

            })
            .catch(error => {
                console.log('Log: calling getUnitDetails errored');
                console.log('Log: Unable to fetch Unit error is ==>' + JSON.stringify(error));
                console.log('Log: Unable to fetch Unit data is ==>' + JSON.stringify(data));
                this.isLoading = false;

            });
    }


    /* Handler Methods */
    handleProjectChange(event) {
        console.log('Log: inside handleProjectChange');
        this.unitDataTable = undefined;
        this.isLoading = true;
        this.selectedProject = event.detail.value;
        this.unitDataTable = undefined;
        //this.selectedUnits={};
        console.log('Log: call populateBuildings');
        this.populateBuildings();
        console.log('Log: call populateBuildings done');
    }

    async handleBuildingChange(event) {
        console.log('Log: inside handleBuildingChange');
        this.unitDataTable = undefined;
        this.isLoading = true;
        this.selectedBuilding = event.detail.value;
        console.log('Log: handleBuildingChange this.selectedBuilding ' + this.selectedBuilding);
        console.log('Log: handleBuildingChange Calling populateUnitData');
        await this.populateUnitData();
        console.log('Log: handleBuildingChange Calling populateUnitData done');
    }
    clearStatisFilters() {
        let allSearchFields = this.template.querySelectorAll('.unitFilter');
        for (let i = 0; i < allSearchFields.length; i++) {
            allSearchFields[i].value = '';
        }
    }
    handleFilterChange() {
        console.log('Log: inside handleFilterChange');

        this.unitDataTable = undefined;
        this.disableDownload = true;
        var filteredData = [];
        console.log('Log: inside handleFilterChange before if cond');
        if (this.unitInventoryDetails) {
            let allSearchFields = this.template.querySelectorAll('.unitFilter');
            console.log('Log: inside handleFilterChange before for loop');
            for (let k = 0; k < this.unitInventoryDetails.length; k++) {
                console.log('Log: inside handleFilterChange inside for loop');
                var filerCondition = true;
                for (let i = 0; i < allSearchFields.length; i++) {
                    if (allSearchFields[i].value != undefined && allSearchFields[i].value != '') {
                        if (this.unitInventoryDetails[k].unitDetails[allSearchFields[i].dataset.fieldApi] != allSearchFields[i].value) {

                            filerCondition = false;
                            break;
                        }
                    }
                }
                if (filerCondition) {
                    console.log('Log: inside handleFilterChange inside filerCondition');
                    let tempRec = Object.assign({}, this.unitInventoryDetails[k]);
                    tempRec.isSelected = (this.selectedUnits[tempRec.unitDetails.Id]) ? this.selectedUnits[tempRec.unitDetails.Id].selectionStatus : false;
                    filteredData.push(tempRec);
                    this.disableDownload = false;
                }
            }

        }
        this.unitDataTable = filteredData;
        console.log('Log: inside handleFilterChange assigned unitdatatable');
        //return filteredData;
    }
    navigateToRecordPage(event) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                objectApiName: 'Unit__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    handleRowSelect(event) {
        this.isLoading = true;
        let invalidSO = event.target.dataset.hasvalid;

        // let directIndirectUnitvalue = event.target.dataset.directindirect;



        if (invalidSO == 'true') {
            const evt = new ShowToastEvent({
                message: 'This Unit already has a valid Sales Order. Please select another unit',
                variant: 'Warning'
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
            event.target.checked = false;

        }
        /*   if(directIndirectUnitvalue!=this.opportunityDirectindirectvalue  && directIndirectUnitvalue !=null){
              const evt = new ShowToastEvent({
                  message: 'Selected Unit is not able to Mach the Direct/Indirect Sale',
                  variant: 'Warning'
              });
              this.dispatchEvent(evt);
              this.isLoading = false;
                  event.target.checked = false;
             }
       */

        else {
            if (event.target.checked) {
                this.selectedRowCount++;
                this.selectedUnits[event.target.dataset.id] = {
                    'selectionStatus': event.target.checked,
                    'unitId': event.target.dataset.id,
                    'finishingtypeValue': 'Standard Price',
                    'admincludedfee':   event.target.dataset.admincludedfee,
                    'unitName': event.target.dataset.unitName,
                    'ProjectName': event.target.dataset.unitProject,
                    'sCWaiverFee': event.target.dataset.unitAsc,
                    'pMFee': event.target.dataset.unitPmf,
                    'homeMaintenanceFee': event.target.dataset.unitHmf,
                    'unitPrice': event.target.dataset.unitUnitprice,
                    'unittype': event.target.dataset.unitUnittype,
                    'multipurposeamount': event.target.dataset.unitMultipurposeamount,
                    'totalrooms': event.target.dataset.unitTotalrooms,
                    'saleablearea': event.target.dataset.unitSaleablearea,
                    'unitStandardPrice': event.target.dataset.unitStandardPrice,
                    'unitPremiumPrice': event.target.dataset.unitPremiumPrice,
                    'measuredarea': event.target.dataset.unitMeasuredarea,
                    'terracearea': event.target.dataset.unitTerracearea,
                    'standsardPrice': event.target.dataset.StandardPrice__c,
                    'PremiumPrice': event.target.dataset.PremiumPrice__c,
                    'onlinereservationfee': event.target.dataset.unitOnlinereservationfee,
                    'reservationamount': event.target.dataset.unitReservationamount,
                    'intCommissionAmountField': undefined,
                    'intCommissionPercentageField': undefined,
                    'dataInstallmentLineChanges': [],

                    'salesOfferDetails': undefined
                };
                console.log('Log:selected Units:' + JSON.stringify(this.selectedUnits[event.target.dataset.id].admincludedfee))




            } else {
                this.selectedRowCount--;
                this.selectedUnits[event.target.dataset.id].selectionStatus = false;
                if (this.totalSelectedUnits < 1) {
                    this.memoHeaderField = '';
                    this.memoSubjectField = '';
                    this.memoTypeField = '';
                    this.specialNoteField = '';
                }
            }
            this.isLoading = false;

            if (this.selectedUnits[event.target.dataset.id].selectionStatus == true) {
                this.UnitIdList.push(event.target.dataset.id);
            }

            if (this.selectedUnits[event.target.dataset.id].selectionStatus == false) {
                this.UnitIdList = this.UnitIdList.filter(value => value !== event.target.dataset.id);
            }
            console.log('UnitIdList: ' + this.UnitIdList);
            console.log('selectedRowCount' + this.selectedRowCount);


        }
    }
    handlePaymentUnitSelect(event) {
        console.log('Inside Handlepaymentunitselect');

        //GET THE OFFERS
       // this.isLoading = true;
        this.currentUnit = event.target.value;
        console.log(JSON.stringify(this.selectedUnits[this.currentUnit].salesOfferDetails))
        //TODO: PDB gpopulate the UI
        if (!this.selectedUnits[this.currentUnit].salesOfferDetails) {
            console.log('Call to generate Offer');
            this.generateOffer();
        } else {
            //this.currentSalesOfferDetails=undefined;
            this.selectedUnits[this.currentUnit].salesOfferDetails;
        }
        this.populateSelectedValsFlag = true;
    }
    populateSelectedValsFlag = false;

    populateSelectedVals() {

        let selectedOffer = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].selectedOffer");
        let unitFinishingField = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].unitFinishingField");
        let unitFurnishingField = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].unitFurnishingField");
        let multiPurposeRoomField = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].multiPurposeRoomField");
        let unitDesiagnField = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].unitDesiagnField");
        let selectedPaymentPlan = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].selectedPaymentPlan");
        let mortgageApplicableField = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].mortgageApplicableField");
        let mortgageBankField = this.template.querySelector("[data-record-id='" + this.currentUnit + "'].mortgageBankField");
        //let selectedPaymentPlanName = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedPaymentPlanName");
        if (selectedOffer) { selectedOffer.value = this.selectedUnits[this.currentUnit].offerId; }
        if (unitFinishingField) { unitFinishingField.value = this.selectedUnits[this.currentUnit].unitFinishes; }
        if (unitFurnishingField) { unitFurnishingField.value = this.selectedUnits[this.currentUnit].unitFurnishing; }
        if (mortgageApplicableField) { mortgageApplicableField.value = (this.selectedUnits[this.currentUnit].mortgageApplicable == true) ? 'Yes' : (this.selectedUnits[this.currentUnit].mortgageApplicable == false ? 'No' : undefined); }
        if (mortgageBankField) { mortgageBankField.value = this.selectedUnits[this.currentUnit].mortgageBank; }

        if (multiPurposeRoomField) { multiPurposeRoomField.checked = this.selectedUnits[this.currentUnit].salesOfferDetails.multiPurposeAmountApplicable; }
        if (unitDesiagnField) { unitDesiagnField.value = this.selectedUnits[this.currentUnit].unitDesignRecordId; }
        if ((this.ReservationWizard || this.BookingWizard || this.MemoWizard) && selectedPaymentPlan) {
            //for reservation wizard if multiple payment are selected then clear selection if one selected then set default
            let selectedPayments = [];
            if (this.selectedUnits[this.currentUnit].salesOfferDetails && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated) {
                for (let i = 0; i < this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                    if (this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                        selectedPayments.push(this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                        // console.log('---'+this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Name);
                        //if(selectedPaymentPlanName){selectedPaymentPlanName.value=this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Name;}
                    }
                }
            }

            if (selectedPayments.length == 1) {
                selectedPaymentPlan.value = selectedPayments[0];
            } else {
                if (selectedPayments.length > 1) {
                    //Clear selection
                    let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
                    for (let i = 0; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                        pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = false;
                    }
                    this.selectedUnits[this.currentUnit] = pd;
                }
                selectedPaymentPlan.value = '';
            }
        }
        //if ui is refreshed then exit
        if (selectedOffer) {
            this.populateSelectedValsFlag = false;
            this.isLoading = false;
        }

    }
    unselectPaymentPlan(event) {


        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        for (let i = 0; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
            if (pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.name) {
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = false;
                break;
            }
        }
        // console.log(event.target.name);
        this.selectedUnits[this.currentUnit] = pd;
    }

    handleSinglePaymentSelection(event) {
        this.singlePaymentSelectcheck = event.target.checked;
        try {
            if (this.singlePaymentSelectcheck) {

                Object.entries(this.selectedUnits).forEach(item => {
                    const [key, value] = item;                    
                    if (value.selectionStatus && value.salesOfferDetails.applicablePaymentPlansCalculated) {
                        value.salesOfferDetails.applicablePaymentPlansCalculated.forEach(plan => {
                            if (plan.paymentPlanDetails.Id == this.singlePaymentplanid) {
                                plan.isSelected = true;
                            }else{
                                plan.isSelected = false;
                            }
                        });
                    }
                    // offer selection for all units
                    value.offerId = this.selectedOfferId;

                });            
            } 
             //calling generate offer 
             this.generateOffer();

            console.log('outside' + JSON.stringify(this.selectedUnits));
        }
        catch (e) {
            console.log(e.message);
            console.log(e.linenumber);
        }



    }



    selectPaymentPlan(event) {
        console.log('Inside selectPaymentPlan');
        const dataRecordId = event.target.dataset.recordId;
        this.singlePaymentplanid = event.target.value;
        console.log('singlePaymentplanid'+this.singlePaymentplanid);
       // this.isLoading = true;
       // let paymentPlanidforUnitMix = event.target.value;
          
        
      


        /* this.unitVsPaymentUnitmix[event.target.dataset.recordId]=paymentPlanidforUnitMix;
         
         console.log('unitVsPaymentUnitmix'+JSON.stringify(this.unitVsPaymentUnitmix));
         
        
          
         getUnitMixDetails({unitVsPaymentUnitmix:this.unitVsPaymentUnitmix,selcetedUnitCount:this.selectedRowCount})
         .then(result=>{
             console.log('unitmix'+result);
            
          if(result=='red'){
           
                 const result = LightningConfirm.open({
                     message: "UnitMix is not achieved,do you still want to proceed?",
                     variant: "default",
                     label: "Unit Mix"
                 });
                 if (result) {
                    
                    this.hasError = false;
                 } else {
                     this.hasError = true;
                 }
                
             
             
          }
          
         }).catch(error=>{
             this.error=error;
             console.log('error'+this.error);
         })
         */
         if(this.singlePaymentSelectcheck){

            Object.entries(this.selectedUnits).forEach(item => {
                const [key, value] = item;               
                if (value.selectionStatus && value.salesOfferDetails.applicablePaymentPlansCalculated) {
                    value.salesOfferDetails.applicablePaymentPlansCalculated.forEach(plan => {
                        if (plan.paymentPlanDetails.Id == this.singlePaymentplanid) {
                            plan.isSelected = true;
                        }else{
                            plan.isSelected = false;
                        }
                    });
                }
                // offer selection for all units
                value.offerId = this.selectedOfferId;

            });

           console.log('antriksh--'+JSON.stringify(this.selectedUnits));
        }
        else{
            console.log('inside elese of selectpaymentplan')
            this.unitVsPayment.push({ unitId: dataRecordId, paymentId: event.target.value });
       
            let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
            if (this.hidePill) {
                for (let i = 0; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                    pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = false;
                }
            }
    
            for (let i = 0; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
    
                if (pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.value) {
                    pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = true;
                    pd.paymentPlanId = (event.target.value == '') ? undefined : event.target.value;
                    break;
                }
            }
            //this.selectedPaymentPlan=undefined;
            this.selectedUnits[this.currentUnit] = pd;

        }       

        console.log('Call to generate Offer');
        this.generateOffer();
        

       
        this.isLoading=false;
    }
    memoOfferChaage = false;
    handleOfferChange(event) {
        console.log('Inside handleOfferchange');
        this.selectedOfferId = event.detail.value;
        this.isLoading = true;
        if(this.singlePaymentSelectcheck){
            Object.entries(this.selectedUnits).forEach(item => {
                const [key, value] = item;             
                value.offerId = this.selectedOfferId;
            });

        }else{
            let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
            pd.offerId = (event.detail.value == '') ? undefined : event.detail.value;
            this.selectedUnits[this.currentUnit] = pd;        
            console.log('gen offer');
            this.memoOfferChaage = true;

        }  
        console.log('Inside call to Offer');
        this.generateOffer();

    }
    handleDesignChange(event) {
        console.log('Inside handledesignchange');

        this.isLoading = true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitDesignRecordId = (event.detail.value == '') ? undefined : event.detail.value;
        this.selectedUnits[this.currentUnit] = pd;
        //this.currentOffer= (event.detail.value == '') ? undefined : event.detail.value;
        //this.selectOfferId = event.detail.value;
        console.log('Inside call to generateOffer');

        this.generateOffer();

    }

    async handlePDFActive(event) {
        var currentUnit = '';
        var currentOffer = '';
        var selectedDesign = '';
        var otherUnits = '';
        var selectedPayments = '';
        var multiPurposeAmountApplicable = '';
        var finishingtypeValues = '';

        for (var key in this.selectedUnits) {
            if (this.selectedUnits[key].selectionStatus) {
                if (key == event.target.dataset.unitId) {
                    currentUnit = key;
                    if (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated) {
                        for (let i = 0; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                            if (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                                selectedPayments = selectedPayments + (selectedPayments == '' ? '' : '|') + (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                            }
                        }
                    }
                    multiPurposeAmountApplicable = (this.selectedUnits[key].salesOfferDetails) ? this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable : false;
                    currentOffer = (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.offerId) ? this.selectedUnits[key].salesOfferDetails.offerId : '';
                    finishingtypeValues = this.selectedUnits[key].finishingtypeValue;
                    console.log('finishingtypeValues' + finishingtypeValues);
                    selectedDesign = (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.unitDesignRecordId) ? this.selectedUnits[key].salesOfferDetails.unitDesignRecordId : '';
                } else {
                    otherUnits = otherUnits + (otherUnits == '' ? '' : '|') + key;
                }
            }
        }

        if (event.target.dataset.targetType == 'input') {
            this.customerName = event.target.value;
        }
        console.log('finishingtypeValuesaf' + finishingtypeValues);
        //  finishingtypeValues = this.finishingtypeValue;


        this.fullUrl = '/apex/OfferDetailsPDF?id=' + this.recordId + '&currentUnit=' + currentUnit + '&currentOffer=' + currentOffer + '&otherUnits=' + otherUnits + '&selectedPayments=' + selectedPayments + '&customerName=' + this.customerName + '&multiPurposeAmount=' + multiPurposeAmountApplicable + '&selectedDesign=' + selectedDesign + '&finishingtypeValues=' + finishingtypeValues;
console.log('fullUrl'+this.fullUrl);
    }




    async handleAgreementPDF(event) {

        let currentOfferlist = [];
        let selectedPaymentPlans = [];
        var otherUnits = '';
        var selectedPayments = '';

        for (var key in this.selectedUnits) {
            if (this.selectedUnits[key].selectionStatus) {
                if (key == event.target.dataset.unitId) {
                    currentUnit = key;
                    if (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated) {
                        for (let i = 0; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                            if (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                                selectedPayments = selectedPayments + (selectedPayments == '' ? '' : '|') + (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                            }
                        }
                    }
                    multiPurposeAmountApplicable = (this.selectedUnits[key].salesOfferDetails) ? this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable : false;
                    currentOffer = (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.offerId) ? this.selectedUnits[key].salesOfferDetails.offerId : '';
                    selectedDesign = (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.unitDesignRecordId) ? this.selectedUnits[key].salesOfferDetails.unitDesignRecordId : '';

                } else {
                    otherUnits = otherUnits + (otherUnits == '' ? '' : '|') + key;
                }
            }
            if (this.selectedUnits[key].salesOfferDetails.offerId) {

                currentOfferlist.push(this.selectedUnits[key].salesOfferDetails.offerId);
            }

            for (let i = 0; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                console.log('inside for');
                if (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                    console.log('inside if');
                    selectedPaymentPlans = selectedPaymentPlans + (selectedPaymentPlans == '' ? '' : '|') + (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                }
            }

        }

        if (event.target.dataset.targetType == 'input') {
            this.customerName = event.target.value;
        }



        const elementsArray = selectedPaymentPlans.split('|');
        this.offerListtoPass = currentOfferlist;
        this.paymentListtoPass = elementsArray;

        this.fullUrl = '/apex/bookingForm?id=' + this.recordId + '&selectedUnits=' + this.UnitIdList + '&currentOffer=' + currentOfferlist + '&selectedPayments=' + selectedPaymentPlans + '&customerName=' + this.customerName + '&unitVsPaymentMap=' + JSON.stringify(this.unitVsPayment);

    }




    handlePaymentMethodChange(event) {
        var currentUnit = event.target.name;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.paymentMethod = event.target.value;
        this.selectedUnits[currentUnit] = pd;
    }

    handleUnitFinishesChange(event) {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitFinishes = event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
    }
    handleUnitFurnishingChange(event) {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitFurnishing = event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
    }
    handleMortgageChange(event) {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.mortgageApplicable = (event.target.value == 'Yes');
        this.selectedUnits[this.currentUnit] = pd;
    }
    handleMortgageBankChange(event) {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.mortgageBank = event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
    }

    handleMultiPurposeRoomChange(event) {
        this.isLoading = true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.salesOfferDetails.multiPurposeAmountApplicable = event.target.checked;
        this.selectedUnits[this.currentUnit] = pd;
        //this.currentOffer= (event.detail.value == '') ? undefined : event.detail.value;
        this.generateOffer();
    }


    @track homeMaintenanceYearsField;
    @track aDMFeePercentageField;
    @track pMFeeYearsField;
    @track sCWaiverYearsField;

    async handleExistingOfferChange() {

        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));

        var newData = [];
        if (pd.offerId) {
            let query = 'SELECT Id,Name,OfferOn__c,OfferType__c,OfferValue__c,VoucherName__c   FROM OfferLines__c WHERE OfferName__c = \'' + pd.offerId + '\'';
            newData = await getOfferLinesQuery({ query: query });
        }

        //let newData2 = pd.salesOfferDetails.applicableOfferLinesCalculated;
        pd.homeMaintenanceYearsField = undefined;
        pd.homeMaintenanceAmountField = undefined;
        pd.aDMFeePercentageField = undefined;
        pd.aDMFeeAmountField = undefined;
        pd.sCWaiverYearsField = undefined;
        pd.sCWaiverAmountField = undefined;
        pd.rebatePercentageField = undefined;
        pd.rebateAmountField = undefined;
        pd.pMFeeYearsField = undefined;
        pd.pMFeeAmountField = undefined;
        console.log(pd.salesOfferDetails);
        for (let i = 0; i < newData.length; i++) {
            if (newData[i].OfferOn__c == 'Home Maintenance Fees') {
                pd.homeMaintenanceYearsField = newData[i].OfferValue__c;
                // pd.homeMaintenanceAmountField = (pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c && pd.homeMaintenanceYearsField) ? Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c) * Number(pd.homeMaintenanceYearsField) : 0;//await calculateMultiply({ firstValue : Number(pd.homeMaintenanceFee), secondValue: Number(pd.homeMaintenanceYearsField)}); 
            }
            else if (newData[i].OfferOn__c == 'ADM Fees') {
                pd.aDMFeePercentageField = newData[i].OfferValue__c;
                pd.aDMFeeAmountField = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * Number(pd.aDMFeePercentageField) / 100;
            }
            else if (newData[i].OfferOn__c == 'Property Management Fees') {
                pd.pMFeeYearsField = newData[i].OfferValue__c;
                pd.pMFeeAmountField = (pd.salesOfferDetails.unitRecord && pd.salesOfferDetails.unitRecord.BuildingSectionName__c && pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c && pd.salesOfferDetails.unitRecord.MarketLeaseRent__c && pd.pMFeeYearsField) ? ((Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c) / 100) * Number(pd.salesOfferDetails.unitRecord.MarketLeaseRent__c) * Number(pd.pMFeeYearsField)) : 0; //await calculateMultiply({ firstValue : Number(pd.pMFee), secondValue: Number(pd.pMFeeYearsField)}); 
            }
            else if (newData[i].OfferOn__c == 'Service Charges') {
                pd.sCWaiverYearsField = newData[i].OfferValue__c;
                if (pd.salesOfferDetails.unitRecord.MeasuredArea__c !== null && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== '' && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== undefined) {
                    pd.sCWaiverAmountField = ((pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField) ? Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c) * Number(pd.sCWaiverYearsField) : 0) * pd.salesOfferDetails.unitRecord.MeasuredArea__c;//await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.MeasuredArea__c;
                } else {
                    pd.sCWaiverAmountField = ((pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField) ? Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c) * Number(pd.sCWaiverYearsField) : 0) * pd.salesOfferDetails.unitRecord.SaleableArea__c;//await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.SaleableArea__c;
                }
            }
            else if (newData[i].OfferType__c == 'Rebate') {
                pd.rebatePercentageField = newData[i].OfferValue__c;
                pd.rebateAmountField = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * Number(newData[i].OfferValue__c) / 100;
            }

        }
        this.selectedUnits[this.currentUnit] = pd;
        if (pd.salesOfferDetails) {
            this.netValue();
        }


    }

    async voucherMembershipValuesChange() {

        // console.log('voucherMembershipValuesChange');

        let newMembershipTableData = [];
        let newVoucherTableData = [];

        let query = 'SELECT Id,Name,OfferOn__c,OfferType__c,OfferValue__c,VoucherName__c FROM OfferLines__c where OfferType__c = \'Voucher\' and OfferName__r.IsActive__c=true';
        // console.log(query);

        const newData = await getOfferLinesQuery({ query: query });
        // console.log(newData);
        // console.log(JSON.stringify(newData));


        newMembershipTableData.push({ label: '--None--', value: '', amount: 0 });
        newVoucherTableData.push({ label: '--None--', value: '', amount: 0 });

        for (let i = 0; i < newData.length; i++) {
            if (newData[i].OfferType__c == 'Voucher') {
                if (newData[i].OfferOn__c == 'Membership') {
                    if (newData[i].VoucherName__c && newMembershipTableData.findIndex((item) => (item.label === newData[i].VoucherName__c && item.amount === newData[i].OfferValue__c)) === -1) {
                        newMembershipTableData.push({ label: newData[i].VoucherName__c, value: newData[i].Id, amount: newData[i].OfferValue__c });
                    }

                } else {
                    if (newData[i].VoucherName__c && newVoucherTableData.findIndex((item) => (item.label === newData[i].VoucherName__c && item.amount === newData[i].OfferValue__c)) === -1) {
                        newVoucherTableData.push({ label: newData[i].VoucherName__c, value: newData[i].Id, amount: newData[i].OfferValue__c });
                    }
                }
            }
        }

        this.membershipValues = newMembershipTableData;
        this.voucherValues = newVoucherTableData;

    }

    handleReservationAmountTypeChange(event) {
        var currentUnit = event.target.name;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.reservationAmountType = event.target.value;
        if (event.target.value == 'Down Payment') {
            pd.disableAmountInput = true;
            for (let i = 0; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                if (pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                    pd.reservationAmount = pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[0].totalValue;
                    break;
                }
            }
        } else if (event.target.value == 'Default Amount') {
            pd.disableAmountInput = true;
            //  pd.reservationAmount = pd.salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c ? pd.salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c : pd.salesOfferDetails.unitRecord.Project__r.ReservationAmount__c;
        } else if (event.target.value == 'Custom Amount') {
            pd.disableAmountInput = false;
        }
        this.selectedUnits[currentUnit] = pd;
    }

    handlePaymentAmountChange(event) {
        var currentUnit = event.target.name;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.reservationAmount = event.target.value;
        this.selectedUnits[currentUnit] = pd;
    }
    selectedPaymentCalculatedJS;
    handleReserveChoice(event) {
        this.currentUnit = event.target.value;
        var currentUnit = event.target.dataset.unitId;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.disableAmountInput = (pd.disableAmountInput != undefined) ? pd.disableAmountInput : true;
        pd.reservationAmountType = pd.reservationAmountType ? pd.reservationAmountType : '';
        pd.reservationAmount = pd.reservationAmount ? pd.reservationAmount : 0;
        pd.paymentMethod = pd.paymentMethod ? pd.paymentMethod : '';
        this.selectedUnits[currentUnit] = pd;
        for (let i = 0; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
            if (pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                this.selectedPaymentCalculatedJS = pd.salesOfferDetails.applicablePaymentPlansCalculated[i];
                break;
            }
        }
        //this.populateSelectedValsFlag=true;
        this.populateSelectedValsFlag = true;
    }
    handleReservation() {
        this.isLoading = true;
        // console.log('---->handleReservation');
        // console.log('---->handleReservation'+this.validatePaymentDetails());
        if (this.validatePaymentDetails()) {
            // console.log('---->reserveSelectedUnit');
            this.reserveSelectedUnit();
        }

    }
    handleBooking() {
        this.isLoading = true;
        //commmented by Antriksh-
        /* for(var key in this.selectedUnits){
             if(this.selectedUnits[key].selectionStatus){
                 if(this.selectedUnits[key].mortgageApplicable == undefined){
                     const evt = new ShowToastEvent({
                         title: 'Please select Mortgage applicable',
                         message: 'Please select the Mortgage applicable for '+this.selectedUnits[key].unitName+' before submitting ',
                         variant: 'error',
                     });
                     this.dispatchEvent(evt);
                     this.isLoading=false;
                     return false;
                 }
                 if(this.selectedUnits[key].mortgageApplicable && (this.selectedUnits[key].mortgageBank ==undefined || this.selectedUnits[key].mortgageBank ==null) ){
                     const evt = new ShowToastEvent({
                         title: 'Please select the Mortgage Bank',
                         message: 'Please select the Mortgage Bank for '+this.selectedUnits[key].unitName+' before submitting ',
                         variant: 'error',
                     });
                     this.dispatchEvent(evt);
                     this.isLoading=false;
                     return false;
                 }
             }
         }*/
        this.reserveSelectedUnit();
        //commented by Sreelakshmi SK
        /* const {base64, filename, recordId} = this.fileData
        uploadFile({ base64, filename, recordId }).then(result=>{
            this.fileData = null
        }) */

    }
    validatePaymentDetails() {
        // console.log('---->validatePaymentDetails');
        for (var key in this.selectedUnits) {
            if (this.selectedUnits[key].selectionStatus) {
                if (this.selectedUnits[key].reservationAmount == undefined || this.selectedUnits[key].reservationAmount == 0 ||
                    this.selectedUnits[key].paymentMethod == undefined || this.selectedUnits[key].paymentMethod == '') {
                    const evt = new ShowToastEvent({
                        title: 'Payment Option/Amount not selected',
                        message: 'Please select Payment Method and Amont for ' + this.selectedUnits[key].unitName + ' before submitting ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                    return false;
                }
                // console.log('---->validatePaymentDetails222');
                //TODO amount bound check
                if (this.selectedUnits[key].reservationAmountType == 'Custom Amount') {
                    var upperBound = 0;
                    for (let i = 0; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
                        if (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected) {
                            upperBound = this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[0].totalValue;
                            break;
                        }
                    }
                    // console.log('---->validatePaymentDetails333');
                    // console.log(upperBound+ 'Bound Check' + lowerBound);
                    var lowerBound = 0;//this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c : this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.ReservationAmount__c;
                    // console.log(upperBound+ 'Bound Check' + lowerBound);
                    if (upperBound < this.selectedUnits[key].reservationAmount || this.selectedUnits[key].reservationAmount < lowerBound) {
                        const evt = new ShowToastEvent({
                            title: 'Invalid Custom Amount',
                            message: 'Reservation amount should be greater than ' + lowerBound + ' for ' + this.selectedUnits[key].unitName + ' before submitting ',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading = false;
                        return false;
                    }

                }
            }
        }
        // console.log('---->Exit');
        return true;

    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
    }


    doneTypingInterval = 0;

    handleKeyUp(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let name = event.target.name;

        this.typingTimer = setTimeout(() => {
            this[name] = value;
        }, this.doneTypingInterval);
    }

    @track discountAmountField;
    @track rebateAmountField;
    @track sCWaiverAmountField;
    @track pMFeeAmountField;
    @track homeMaintenanceAmountField;
    @track aDMFeeAmountField;
    @track intCommissionAmountField;
    @track brokerCommissionField;
    @track additionalDiscountAmountField;
    @track subsidyAmountField;
    @track netOfferValueField;
    @track netImpactField;


    caltculateValue(event) {
        //This will work only for selected tab
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        //Calculate the Membership for selcted tab
        if (event.target.name == 'membershipTypeField') {
            pd.membershipTypeField = event.target.value;
            this.membershipValues.forEach(element => {
                if (element.value == event.target.value) {
                    pd.membershipAmountField = element.amount;
                }
            });
        }
        //Calculate the Voucher for selcted tab
        else if (event.target.name == 'voucherNameField') {
            pd.voucherNameField = event.target.value;
            this.voucherValues.forEach(element => {
                if (element.value == event.target.value) {
                    pd.voucherAmountField = element.amount;
                }
            });
        }
        //Calculate other values
        else {
            let value = event.target.value;
            let name = event.target.name;
            //clearTimeout(this.typingTimer);
            //Absolute value
            if (value < 0) {
                value = value * -1;
            }
            /*
            this.typingTimer = setTimeout(() => {
                this[name] = value;
            }, this.doneTypingInterval);
            */
            let calculatedValue = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * Number(value) / 100;
            let calculatedValueWithDiscount = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c - (pd.discountAmountField ? pd.discountAmountField : 0)) * Number(value) / 100;

            if (name && value < 100) {

                if (name == 'discountPercentageField') {
                    pd.discountPercentageField = value;
                    pd.discountAmountField = calculatedValue;
                    //calculate based on net selling price
                    calculatedValueWithDiscount = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c - (pd.discountAmountField ? pd.discountAmountField : 0));
                    if (pd.intCommissionPercentageField) { pd.intCommissionAmountField = calculatedValueWithDiscount * Number(pd.intCommissionPercentageField) / 100; }
                    if (pd.brokerCommissionPercentageField) { pd.brokerCommissionField = calculatedValueWithDiscount * Number(pd.brokerCommissionPercentageField) / 100; }

                } else if (name == 'rebatePercentageField') {
                    pd.rebatePercentageField = value;
                    pd.rebateAmountField = calculatedValue;
                } else if (name == 'sCWaiverYearsField') {
                    if (value < 11) {
                        pd.sCWaiverYearsField = value;
                        if (pd.salesOfferDetails.unitRecord.MeasuredArea__c !== null && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== '' && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== undefined) {
                            pd.sCWaiverAmountField = ((pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField) ? Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c) * Number(pd.sCWaiverYearsField) : 0) * pd.salesOfferDetails.unitRecord.MeasuredArea__c; //await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.MeasuredArea__c;
                        } else {
                            pd.sCWaiverAmountField = ((pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField) ? Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c) * Number(pd.sCWaiverYearsField) : 0) * pd.salesOfferDetails.unitRecord.SaleableArea__c; // await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.SaleableArea__c;
                        }
                    }
                } else if (name == 'pMFeeYearsField') {
                    if (value < 11) {
                        pd.pMFeeYearsField = value;
                        pd.pMFeeAmountField = (pd.salesOfferDetails.unitRecord && pd.salesOfferDetails.unitRecord.BuildingSectionName__c && pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c && pd.salesOfferDetails.unitRecord.MarketLeaseRent__c && pd.pMFeeYearsField) ? ((Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c) / 100) * Number(pd.salesOfferDetails.unitRecord.MarketLeaseRent__c) * Number(pd.pMFeeYearsField)) : 0; //await calculateMultiply({ firstValue : Number(pd.pMFee), secondValue: Number(pd.pMFeeYearsField)}); 
                    }
                } else if (name == 'homeMaintenanceYearsField') {
                    if (value < 11) {
                        pd.homeMaintenanceYearsField = value;
                        // pd.homeMaintenanceAmountField = (pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c && pd.homeMaintenanceYearsField) ? Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c) * Number(pd.homeMaintenanceYearsField) : 0; //await calculateMultiply({ firstValue : Number(pd.homeMaintenanceFee), secondValue: Number(pd.homeMaintenanceYearsField)}); 
                    }
                } else if (name == 'aDMFeePercentageField') {
                    if (value < 3) {
                        pd.aDMFeeAmountField = calculatedValue;
                        pd.aDMFeePercentageField = value;
                    }
                } else if (name == 'intCommissionPercentageField') {
                    if (value <= Number(MemoDirectCommission)) {
                        pd.intCommissionAmountField = calculatedValueWithDiscount;
                        pd.intCommissionPercentageField = value;
                    }
                } else if (name == 'brokerCommissionPercentageField') {
                    if (value < Number(MemoIndirectCommission)) {
                        pd.brokerCommissionField = calculatedValueWithDiscount;
                        pd.brokerCommissionPercentageField = value;
                    }
                }/*else if (name == 'additionalDiscountPercentageField'){
                    pd.additionalDiscountAmountField = calculatedValue;
                    pd.additionalDiscountPercentageField=value;
                }*/else if (name == 'subsidyPercentageField') {
                    pd.subsidyAmountField = (Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * 80 / 100) * Number(value) / 100;
                    pd.subsidyPercentageField = value;
                }

            }
        }
        this.selectedUnits[this.currentUnit] = pd;
        this.netValue();

    }

    netValue() {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        var unitSellingPrice = pd.salesOfferDetails.unitRecord.SellingPrice__c;
        this.amountValues = [];

        this.amountValues.push(pd.discountAmountField ? Number(pd.discountAmountField) : 0);
        this.amountValues.push(pd.rebateAmountField ? Number(pd.rebateAmountField) : 0);
        this.amountValues.push(pd.sCWaiverAmountField ? Number(pd.sCWaiverAmountField) : 0);
        this.amountValues.push(pd.pMFeeAmountField ? Number(pd.pMFeeAmountField) : 0);
        this.amountValues.push(pd.homeMaintenanceAmountField ? Number(pd.homeMaintenanceAmountField) : 0);
        this.amountValues.push(pd.aDMFeeAmountField ? Number(pd.aDMFeeAmountField) : 0);
        this.amountValues.push(pd.intCommissionAmountField ? Number(pd.intCommissionAmountField) : 0);
        this.amountValues.push(pd.brokerCommissionField ? Number(pd.brokerCommissionField) : 0);
        this.amountValues.push(pd.subsidyAmountField ? Number(pd.subsidyAmountField) : 0);
        this.amountValues.push(pd.membershipAmountField ? Number(pd.membershipAmountField) : 0);
        this.amountValues.push(pd.voucherAmountField ? Number(pd.voucherAmountField) : 0);

        //let netOffer = await calculateNetValue({amountValues: this.amountValues});
        var netOffer = 0;
        for (let i = 0; i < this.amountValues.length; i++) {
            if (this.amountValues[i] && this.amountValues[i] != undefined && this.amountValues[i] != null) {
                netOffer += this.amountValues[i];
            }
        }
        let netImpact = (Number(netOffer) / unitSellingPrice * 100)//await calculateNetImpact({netOfferValue: Number(netOffer), unitSellingPrice: unitSellingPrice});

        if (netImpact > 50) {
            const evt = new ShowToastEvent({
                title: 'Net Impact',
                message: 'Summation for all percentage fields should not be more than 50%',
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
        pd.netImpactField = netImpact.toFixed(2) + ' %';
        pd.netOfferValueField = netOffer;

        this.selectedUnits[this.currentUnit] = pd;
    }

    cloneInstallmentLines() {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        let newTableData = [];

        for (let i = 0; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length; i++) {
            if (pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected == true) {
                for (let j = 0; j < pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails.length; j++) {
                    newTableData.push({ Milestone: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.Description__c, InstallmentNumber: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentNumber__c, ProposedInstallmentPercentage: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentPercentage__c, ProposedBrokerPercentage: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.BrokerPayoutPercentage__c, ProposedInstallmentDate: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentDate__c });
                }
                pd.dataInstallmentLineChanges = newTableData;
                this.selectedUnits[this.currentUnit] = pd;
            }

        }
    }

    handleSortData() {
        this.sortBy = 'InstallmentNumber';
        this.sortDirection = 'asc';
        this.sortAccountData(this.sortBy);
    }

    sortAccountData(fieldname) {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));

        let parseData = JSON.parse(JSON.stringify(pd.dataInstallmentLineChanges));

        let keyValue = (a) => {
            return a[fieldname];
        };

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return ((x > y) - (y > x));
        });

        pd.dataInstallmentLineChanges = parseData;
        this.selectedUnits[this.currentUnit] = pd;
    }

    getCustomerNamefn() {
        getCustomerInfo(
            {
                recId: this.recordId
            }
        )
            .then(result => {

                result.forEach(item => {
                    this.customerName = item.Account.Name;
                });

            })
            .catch(error => {
                console.log(error);
            });
    }

    handleCheckboxChange(event) {
        this.downPaymentReceived = event.target.checked;

    }

    handleUnitSearch(event) {
        let key = event.target.value;

        window.clearTimeout(this.timer)
        this.timer = setTimeout(() => {
            this.handleUnitSearchHandler(key);
        }, 500)
    }

    handleUnitSearchHandler(keyword) {
        console.log(keyword);
        if (keyword)
            this.unitDataTable = this.unitInventoryDetails.filter(ele => ele.unitDetails.Name.toLowerCase().includes(keyword.toLowerCase()));

        else
            this.handleFilterChange();
        if (this.unitDataTable.length == 0) {
            this.noDataavailable = true;
        }
        else {
            this.noDataavailable = false;
        }
    }

    @wire(getPicklistvalue, {
        objName: 'Opportunity',
        fieldName: 'AgentType__c'
    })
    wiredDirectIndirectValues({ data, error }) {
        if (data) {
            let temp = [];

            for (var key in data) {
                temp.push({ label: key, value: data[key] });
            }
            this.diectIndirectValue = temp;
            console.log(JSON.stringify(this.diectIndirectValue));
        } else if (error) {
            console.log('error' + JSON.stringify(error));
            this.error = error;
            this.diectIndirectValue = undefined;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId', fields
    })
    wiredRecorddefaultdirectindirect({ error, data }) {
        if (data) {

            this.opportunityRecord = data;
            this.opportunityDirectindirectvalue = this.opportunityRecord.fields.AgentType__c.value;

            // this.opportunityDirectindirectvalue=this.defaultDirectIndirectvalue;

            console.log(JSON.stringify(this.opportunityRecord));
        } else if (error) {
            console.error(error);
        }
    }

    /*  handleDirectIndirectChange(event){
         this.defaultDirectIndirectvalue=event.target.value;
         console.log(this.defaultDirectIndirectvalue);
         this.populateUnitData();
     } */

    /*  handleDirectIndirectChange(event) {
    let key = event.target.value;
    alert(key);
    console.log('unitInventoryDetails' + JSON.stringify(this.unitInventoryDetails));
    
    this.unitDataTable = this.unitInventoryDetails.filter(item => {
      if (item.unitDetails.hasOwnProperty('Direct_Indirect__c')) {
        return [key, ''].includes(item.unitDetails.Direct_Indirect__c);
      }
      return false;
    });
  } */

  timeAddedResult(event){

 this.showReqExtendTimeBtn=false;
}

  handeExtendTime(event){
   

    UnitBookTimeExtendApproval({ OpportunityId: this.recordId, unitIds: this.unitsToLock })
        .then(reult => {
            if (reult == 'Success') {
                const evt = new ShowToastEvent({
                    title: 'Submitted for Approval',
                    message: 'Unit Booking Time Extend Request has been submitted for Approval',
                    variant: 'success',
                });
                this.dispatchEvent(evt);

                this.showLoading = false;
                this.showRequestForExtension=false;
                this.showSelectDateModal = false;

            }


        })
        .catch(error => {
            /* const evt = new ShowToastEvent({
                message: 'Unit already submitted for Approval',
                variant: 'Error',
            });
            this.dispatchEvent(evt); */
            this.showToast('Something went wrong', error.body.message, 'error');
            this.showLoading = false;
            this.showSelectDateModal = false;
        });

    
  }








}