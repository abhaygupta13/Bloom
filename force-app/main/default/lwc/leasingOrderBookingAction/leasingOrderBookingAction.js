import { LightningElement, api, wire, track } from 'lwc';
import getAllProjects from '@salesforce/apex/LeasingOrderController.getAllProjectsForLeasing';
import getAllBuildings from '@salesforce/apex/LeasingOrderController.getAllBuildings';
import getUnitDetails from '@salesforce/apex/LeasingOrderController.getUnitDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getsObjectType from '@salesforce/apex/LeasingOrderController.getsObjectType';
import createLeasingOrder from '@salesforce/apex/LeasingOrderController.createLeasingOrder';
import generatePDF from '@salesforce/apex/LeasingOrderController.generatePDF';
import getLeasingoffers from '@salesforce/apex/LeasingOrderController.getLeasingoffers';
import getOfferLineDiscountSum from '@salesforce/apex/LeasingOrderController.getOfferLineDiscountSum';
import saveEscalationSplits from '@salesforce/apex/LeasingOrderController.insertEscalationSchedules';
import hasEditPermission from '@salesforce/apex/LeasingOrderController.hasEditPermission';
import getActiveLeasingContract from '@salesforce/apex/LeasingOrderController.getActiveLeasingContract';
//import getUserProfileName from '@salesforce/apex/LeasingOrderController.getUserProfileName';


export default class LeasingOrderComponent extends NavigationMixin(LightningElement) {
    @track currentStage = 'Select Unit';
    @track isSubmissionLoading = false;
    @track currentStep = 'step1';
    @track hasError = false;
    @track isEditable = false;
    @track relatedPartyBloomHolding = false;
    @track bookingAmount
    @api recordId;
    @track isLoading = true;
    @track projectList = [];
    @track selectedProject = '';
    @track buildingList = [];
    @track selectedBuilding = '';
    @track unitDataTable = [];
    @track unitInventoryDetails = [];
    @track unitBedRoomsSetList = [];
    @track selectedUnits = {};
    @track selectedUnit = null;
    @track leasingContractName = '';
    @track isFamily = false;

    @track leasingEndDate = '';
    @track discountPercentage = 0;
    @track discountAmount = 0;
    @track offerLineDiscountPct = 0;
    @track combinedDiscountPct = 0;
    @track rentalAfterDiscount = null;
    @track isPersonAccount = false;
    @track familyStatusType;

    @track gracePeriod = '0';
    @track gracePeriod_ = 0;
    @track ejariPct;
    @track adminFeePct;
    @track serviceChargePct;
    @track securityDepositPct;
    @track apartmentSecDeposit;
    @track villaSecDeposit;
    @track ejariFee;
    @track adminFee;
    @track serviceCharge;
    familyStatus = '';
    steps = [];
    @track paymentPlans = [];
    @track paymentPlanOptions = [];
    @track selectedPaymentPlanId;

    @track leasingOffers = [];
    @track leasingOfferOptions = [];
    @track selectedLeasingOfferId;
    @track leasingStartDate;
    @track leasingContractMonths;
    @track leasingContractMonths_;
    @track appliedAnnualRent = 0;

    @track selectedProject;
    @track offerValidityDays = 3

    //@track adminFee = 0;
    // @track ejariFee = 0;
    @track extraChequeFee = 0;
    @track guaranteeCheque = 0;
    @track fitOutSecurityDeposit = 0;
    @track remarks;
    accountName;
    @track currentCondition;
    @track handOverCondition
    @track securityDepositType = 'Amount';
    @track securityDepositPercent = 0;
    @track securityDeposit = 0;
    @track isBloomStaff = false;

    @track discountType = 'Amount';
    @track ejari_Tawtheeq; // fallback label
    @track projectLocation; // fallback label
    //isEJari_TawtheeqEligible;
    @track propertyId;
    @track showCountDetails;
    @track adultCount = 0;
    @track childCount = 0;
    @track disableSecurityDeposit = false;
    isBloomEmployeeChecked = false;
    isBloomSisterEmployeeChecked = false;
    actualSecurityDeposite = 0;
    actualsAdminFee = 0;
    securityDepositePrcntg = 0;


   unitBedRoomsSetList = [
        // { label: 'All', value: 'All' },
        { label: '1', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' },
        { label: '5', value: '5' },
        { label: '6', value: '6' }
    ];
    unitConditionStateValues = [
        { label: 'Shell and Core', value: 'Shell and Core' },
        { label: 'Fitted', value: 'Fitted' }
    ];

    @track paymentPlanOptions = [
        { label: '1 Installment', value: '1 Installment' },
        { label: '2 Installments', value: '2 Installments' },
        { label: '3 Installments', value: '3 Installments' },
        { label: '4 Installments', value: '4 Installments' },
        { label: '6 Installments', value: '6 Installments' },
        { label: '12 Installments', value: '12 Installments' }
    ];

    //pranav
    get options() {
        let nums = [];
        nums.push({label:'0 Months', value:'0'});
        for (let i = 1; i <= 11; i++) {
            nums.push({ label: i.toString() + ' Months', value: i.toString()});
        }
        return nums;
    }

    familyStatusOptions = [
        { label: 'Individual', value: 'Individual' },
        { label: 'Family', value: 'Family' }
    ]
    activeContract
    @wire(getActiveLeasingContract, { opportunityId: '$recordId' })
    wiredContract({ data, error }) {
        if (data) {
            this.activeContract = data;
        } else if (error) {
            console.error('Error fetching active leasing contract:', error);
        }
    }
    navigateToContract() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.activeContract.Id,
                objectApiName: 'LeasingContract__c',
                actionName: 'view'
            }
        });
    }
    connectedCallback() {

        // getUserProfileName()
        // .then(profile => {
        //     this.isBloomStaff = (profile === 'Leasing'); // Bloom staff profile
        //     if (this.isBloomStaff) {
        //         this.securityDeposit = 0;
        //         this.securityDepositPercent = 0;
        //         this.securityDepositType = 'Amount'; // default lock
        //     }
        // })
        // .catch(error => {
        //     console.error('Error fetching user profile:', error);
        // });

        this.getSObjectData();
        hasEditPermission()
            .then(result => {
                this.isEditable = result;
            })
            .catch(error => {
                console.error('Permission check error:', error);
            });
    }

    get isReadOnly() {
        return !this.isEditable;
    }

    handleStepClick(event) {
        const selectedStep = event.target.value;
        this.currentStep = selectedStep;
    }

    get isStage1Selected() {
        // return this.currentStage === 'Select Unit';
        return this.currentStep === 'step1';
    }
    get isStage2Selected() {
        // return this.currentStage === 'Payment Plan';
        return this.currentStep === 'step2';
    }
    get isStage3Selected() {
        // return this.currentStage === 'Escalation Schedule';
        return this.currentStep === 'step3';
    }
    get isStage4Selected() {
        // return this.currentStage === 'Escalation Schedule';
        return this.currentStep === 'step4';
    }
    get serviceChargeHelpText() {
        return `Project Service Charge is ${this.serviceChargePct} per sqm`;
    }
    get adminFeeHelpText() {
        return `Project Admin Fee is ${this.adminFeePct}%, 0 for Bloom or Partner Employee` ;
    }
    get ejariFeeHelpText() {
        return `Applicable only for Dubai location Projects`;
    }
    get securityDepositHelpText() {
        return `Project Security Deposit is ${this.securityDepositPct}%`;
    }




    async loadLeasingOffers() {
        try {
            const offers = await getLeasingoffers();
            this.leasingOffers = offers;
            this.leasingOfferOptions = offers.map(o => ({ label: o.Name, value: o.Id }));
        } catch (error) {
            console.error('Error fetching leasing offers', error);
        }
    }

    handlePaymentPlanChange(event) {
        this.selectedPaymentPlanId = event.detail.value;
        this.loadLeasingOffers();
    }
    async handleLeasingOfferChange(event) {
        this.selectedLeasingOfferId = event.detail.value;
        await this.fetchOfferLineDiscount(this.selectedLeasingOfferId);
        this.computeRentalAfterDiscount();
    }
    async fetchOfferLineDiscount(offerId) {
        if (!offerId) {
            this.offerLineDiscountPct = 0;
            return;
        }
        try {
            const sumPct = await getOfferLineDiscountSum({ leasingOfferId: offerId });
            this.offerLineDiscountPct = sumPct != null ? Number(sumPct) : 0;
        } catch (error) {
            console.error('Error fetching offer‐line discount:', error);
            this.offerLineDiscountPct = 0;
        }
    }


    computeRentalAfterDiscount() {
        if (!this.selectedUnit) {
            this.rentalAfterDiscount = null;
            this.combinedDiscountPct = 0;
            return;
        }
        const userPct = Number(this.discountPercentage) || 0;
        const offerPct = Number(this.offerLineDiscountPct) || 0;
        let totalPct = userPct + offerPct;
        this.combinedDiscountPct = totalPct;

        const baseRent = Number(this.selectedUnit.LeasingAnnualRent__c) || 0;
        const appliedRent = Number(this.appliedAnnualRent) || 0;

        // Take the greater of applied or base rent
       // const finalRent = Math.max(baseRent, appliedRent);
const finalRent = appliedRent;

        const discountAmt = Number(this.discountAmount) || 0;

        let afterDiscount = finalRent;

        if (totalPct > 0) {
            // Apply percentage discount
            const pct = Math.min(totalPct, 100); // Clamp to 100%
            afterDiscount = (finalRent * (100 - pct)) / 100;
        } else if (discountAmt > 0) {
            // Apply flat amount discount
            afterDiscount = finalRent - discountAmt;
        }

        // Prevent negative rent
        this.rentalAfterDiscount = afterDiscount < 0 ? 0 : afterDiscount;
        this.recalcChargesFromApplied();

    }

    get discountValue() {
        return this.discountType === 'Amount'
            ? this.discountAmount
            : this.discountPercentage;
    }

    @track projectName;
    fetchProjects() {
        getAllProjects()
            .then(data => {
                this.projectList = data.map(p => ({
                    label: p.label,
                    value: p.value,
                    ejariPct: parseFloat(p.ejariFee) || 0,
                    adminFeePct: parseFloat(p.adminFee) || 0,
                    serviceChargePct: parseFloat(p.serviceCharge) || 0,
                    securityDepositPct: parseFloat(p.securityDeposit) || 0,
                    apartmentSecDeposit: parseFloat(p.apartmentSecDeposit) || 0,
                    villaSecDeposit: parseFloat(p.villaSecDeposit) || 0,
                    city: p.city
                }));
                console.log('projectList--', JSON.stringify(this.projectList))
                if (this.selectedProject) {
                    this.fetchBuildings();
                } else {
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('Error fetching projects:', error);
                this.projectList = [];
                this.isLoading = false;
            });
    }

    fetchBuildings() {
        getAllBuildings({ projectId: this.selectedProject })
            .then(data => {
                this.buildingList = data || [];
                this.selectedBuilding = data.length ? data[0].value : '';
                console.log('this.selectedBuilding--', this.selectedBuilding);
                console.log('this.recordId--', this.recordId);
            })
            .catch(error => {
                console.error('Error fetching buildings:', error);
                this.buildingList = [];
                this.isLoading = false;
            });
    }
    @track propertyType
    @track unitNumber
    @track bedrooms
    fetchUnitDetails() {


        getUnitDetails({
            buildingsId: this.selectedBuilding,
            bedrooms: this.bedrooms,
            propertyType: this.propertyType,
            unitNumber: this.unitNumber,
            selectedUnitId: null  // passed from @api recordId
        }).then(data => {

            this.unitDataTable = data.unitDetailList || [];
            this.unitInventoryDetails = data.unitDetailList;
            this.isLoading = false;
        })
            .catch(error => {
                console.log('In 107', JSON.stringify(this.unitDataTable));
                console.error('Error fetching unit details:', error);
                this.unitDataTable = [];
                this.isLoading = false;
            });
    }

    get showFamilyStatus() {
        return (
            this.selectedUnit &&
            this.selectedUnit.PropertyUsage__c === 'Residential'
        );
    }



    get isEJari_TawtheeqEligible() {
        return (
            true//this.projectLocation === 'dubai'
        );
    }
    /* Event Handlers */
    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
        const proj = this.projectList.find(p => p.value === this.selectedProject);
        if (proj) {
            this.ejariPct = proj.ejariPct;
            this.adminFeePct = proj.adminFeePct;
            this.serviceChargePct = proj.serviceChargePct;
            //this.securityDepositPct = proj.securityDepositPct;
            this.apartmentSecDeposit = Number(proj.apartmentSecDeposit) || 0;
            this.villaSecDeposit = Number(proj.villaSecDeposit) || 0;
            this.securityDepositePrcntg = Number(proj.securityDepositPct) || 0;

            this.projectLocation = proj?.city?.toLowerCase();
            this.projectName = proj?.label;
            if (proj?.city?.toLowerCase() === 'dubai') {
                this.ejari_Tawtheeq = 'Ejari Fee (AED)';

            } else {
                this.ejari_Tawtheeq = 'Tawtheeq Fee (AED)';
            }


            if (this.selectedUnit) { this.recalcChargesFromApplied(); }
        }
        this.fetchBuildings();

    }

    handleBuildingChange(event) {
        this.selectedBuilding = event.detail.value;
        //this.fetchUnitDetails();
    }


    commercialPropertySearch;
    handleFilterChange(event) {
        const rawValue = event.detail?.value;
        const fieldName = event.target.name;
        if (fieldName === 'propertyType') {
            this.propertyType = rawValue
            this.commercialPropertySearch = this.propertyType === 'Commercial';
            this.isPersonAccount = this.propertyType === 'Residential';
        }
        if (fieldName === 'bedrooms') {
            this.bedrooms = rawValue
        }
        if (fieldName === 'unitNumber') {
            this.unitNumber = rawValue
        }
        console.log('this.propertyType- ', this.propertyType)
        console.log('this.bedrooms- ', this.bedrooms)
        console.log('this.unitNumber- ', this.unitNumber)
        this.unitDataTable = this.unitInventoryDetails;
        if (!this.unitDataTable || this.unitDataTable.length === 0) {
            console.warn('No unit data available to filter.');
            return;
        }

        let filteredData = [];
        let searchFields = this.template.querySelectorAll('.unitFilter');
        this.unitDataTable.forEach(unit => {
            let match = true;
            searchFields.forEach(field => {
                let fieldValue = field.value?.trim();
                let fieldApi = field.dataset.fieldApi;
                if (fieldValue && String(unit.unitDetails[fieldApi]) !== fieldValue) {
                    match = false;
                }
            });

            if (match) {
                let tempUnit = { ...unit };
                tempUnit.isSelected = !!this.selectedUnits[tempUnit.unitDetails.Id]?.selectionStatus;
                filteredData.push(tempUnit);
            }
        });

        this.unitDataTable = filteredData;
        console.log(`Filtered units count: ${filteredData.length}`);
    }

    handleRowSelect(event) {
        const unitId = event.target.dataset.id;
        this.selectedUnits[unitId] = event.target.checked;
        this.selectedUnit = this.unitDataTable.find(unit => unit.unitDetails.Id === unitId)?.unitDetails || null;
        this.isBloomEmployeeChecked = false
        this.isBloomSisterEmployeeChecked = false;

        if (this.selectedUnit.UnitType__c === 'Apartment') {
            this.securityDeposit = this.apartmentSecDeposit;
        } else {
            this.securityDeposit = this.villaSecDeposit;
        }

        if (this.selectedUnit) {
            this.isPersonAccount = !!this.selectedUnit.ActiveTenant__r?.IsPersonAccount;
        }

        // Generate Leasing Contract Name
        if (this.selectedUnit) {
            this.leasingContractName = `${this.accountName} - ${this.selectedUnit.LeasingUnitNumber__c}`;
        }

        this.appliedAnnualRent = Number(this.selectedUnit.LeasingAnnualRent__c);
        if (!this.discountType) {
            this.discountType = 'Amount';
        }
        const sizeSqm = Number(this.selectedUnit.LeasingUnitSizesqm__c) || 0;

        //this.adminFee = (this.adminFeePct * this.appliedAnnualRent) / 100;
        //this.ejariFee = (this.ejariPct * this.appliedAnnualRent) / 100;
        this.serviceCharge = (Number(this.serviceChargePct) || 0) * sizeSqm;
        if (this.selectedUnit.UnitType__c === 'Apartment') {
            this.securityDeposit = this.apartmentSecDeposit;
        } else {
            this.securityDeposit = this.villaSecDeposit;
        }
        this.recalcChargesFromApplied();
        //this.securityDeposit = (this.securityDepositPct * this.appliedAnnualRent) / 100;

    }



    get noDataavailable() {
        return this.unitDataTable.length === 0;
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    @track isPersonAccount
    getSObjectData() {
        getsObjectType({ recordID: this.recordId })
            .then(data => {
                for (var key in data) {
                    this.sObjectRecordType = key;
                    this.sObjectRecord = data[key];
                    if (this.sObjectRecordType == 'Opportunity') {
                        this.accountName = this.sObjectRecord.Account.Name;
                        this.isPersonAccount = this.sObjectRecord.Account.IsPersonAccount;
                    }
                }
                if (this.isPersonAccount === true) {
                    this.propertyValue = [
                        { label: 'Residential', value: 'Residential' }
                    ];
                } else {
                    this.propertyValue = [
                        { label: 'Commercial', value: 'Commercial' },
                        { label: 'Residential', value: 'Residential' }
                    ];
                }
                if (this.sObjectRecordType == 'Opportunity') {
                    this.fetchProjects();
                }

            })
            .catch(error => {
                this.sObjectRecordType = undefined;
                this.sObjectRecord = undefined;
                this.isLoading = false;
            });
    }


    handleNext(event) {
        if (!this.selectedUnit) {
            this.dispatchEvent(new ShowToastEvent({ title: "Error", message: "Please select a unit!", variant: "error" }));
            return;
        }
        if(this.propertyType == 'Residential' && this.bedrooms <= 3 ){
            this.disableSecurityDeposit = true;
            this.securityDepositType = 'Amount';
            this.securityDeposit = 5000;
        }
        if(this.propertyType == 'Residential' && this.bedrooms >= 4 ){
            this.disableSecurityDeposit = true;
            this.securityDepositType = 'Amount';
            this.securityDeposit = 10000;
        }

        if(this.propertyType == 'Commercial'){
            this.disableSecurityDeposit = true;
            this.securityDepositType = 'Amount';
            //this.securityDeposit = this.appliedAnnualRent * 10 / 100;
            this.securityDeposit = this.appliedAnnualRent * this.securityDepositePrcntg / 100;
        }
        console.log('this.currentStep::', this.currentStep);
        this.currentStep = 'step2';
        

    }
    handleBacktStage2(event) {

        this.currentStep = 'step2'
        console.log('showRentSchedule---', this.showRentSchedule)
        console.log('this.isStage3Selected---', this.isStage3Selected)
        
    }
    // handleNextStage3(event) {

    //     const allValid = [...this.template.querySelectorAll('.validate')]
    //         .reduce((validSoFar, inputCmp) => {
    //             return validSoFar && inputCmp.reportValidity();
    //         }, true);

    //     if (allValid) {
    //         this.currentStep = 'step3'
    //     }
    //     console.log('showRentSchedule---', this.showRentSchedule)
    //     console.log('this.isStage3Selected---', this.isStage3Selected)
    //     console.log(`Bloom Employee`,this.isBloomEmployeeChecked,this.isBloomSisterEmployeeChecked);
    //     console.log(`Security deposite>>`,this.securityDeposit);
    //     console.log(`Actual Security deposite>>`,this.actualSecurityDeposite);
        
    // }

    handleNextStage3(event) {
    const allValid = [...this.template.querySelectorAll('.validate')]
        .reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.reportValidity();
        }, true);
    const minRent = Number(this.selectedUnit?.LeasingAnnualRent__c) || 0;
    const appliedRent = Number(this.appliedAnnualRent) || 0;

    if (
        !this.isRentValidationBypassed &&
        appliedRent < minRent
    ) {
        this.showToast(
            'Error',
            `Applied Annual Rent cannot be less than ${minRent}. Please select Bloom Employee or Sister Company checkbox to proceed.`,
            'error'
        );
        return; 
    }
    if (allValid) {
        this.currentStep = 'step3';
    }
}
    handleNextStage4(event) {
        const allValid = [...this.template.querySelectorAll('.validate')]
            .reduce((validSoFar, inputCmp) => {
                return validSoFar && inputCmp.reportValidity();
            }, true);
        if (allValid) {
            this.currentStep = 'step4'
        }
    }
    handleBackStage1(event) {
        this.currentStep = 'step1';
        console.log('1st page');
        this.isBloomEmployeeChecked = false;
        this.isBloomSisterEmployeeChecked = false;
        //Pranav
        this.selectedUnit = [];
        this.isNextDisabled = true;
        
        
    }

    handleFamilyStatusChange(event) {
        this.familyStatus = event.target.value;
        if(this.familyStatus == 'Family'){
            this.showCountDetails = true;
        }else{
            this.showCountDetails = false;
        }
    }
    handleCurrentConditionChange(event) {
        this.currentCondition = event.target.value;
    }
    handleHandOverConditionChange(event) {
        this.handOverCondition = event.target.value;
    }
    handleFieldChange(event) {
        const rawValue = event.detail?.value;
        const fieldName = event.target.name;

        switch (fieldName) {
            case 'leasingStartDate':
                this.leasingStartDate = rawValue;
                if (this.leasingContractMonths) {
        this.computeEndDate();
    }
                break;
            case 'leasingContractMonths':
                this[fieldName] = event.detail.value;
                this.computeEndDate();
                this.leasingContractMonths_ = rawValue - (this.gracePeriod_/30);
                break;
            case 'appliedAnnualRent': {
    this.appliedAnnualRent = Number(event.detail.value) || 0;
    this.recalcChargesFromApplied();
    this.computeRentalAfterDiscount();
    break;
}
            case 'extraChequeFee':
                this.extraChequeFee = rawValue;
                break;

            case 'fitOutSecurityDeposit':
                this.fitOutSecurityDeposit = rawValue;
                break;
            // case 'gracePeriod':
            //     this.gracePeriod = rawValue;
            //     break;
            //Pranav
            case 'gracePeriod':
                this.gracePeriod_ = parseInt(rawValue,10)*30;
                //this.gracePeriod = rawValue*30;
                console.log(`graceperiod>>`,this.gracePeriod_);
                this.leasingContractMonths_ = this.leasingContractMonths - parseInt(rawValue,10);
                this.gracePeriod = rawValue;
                break;
            case 'serviceCharge':
                this.serviceCharge = rawValue;
                break;
            case 'adminFee':
                this.adminFee = rawValue;
                break;

            case 'securityDepositType':
                this.securityDepositType = event.detail.value;
                if (this.securityDepositType === 'Percentage') {
                    this.securityDepositPercent = 0;
                    this.securityDeposit = 0;
                }
                break;

            case 'securityDepositPercent':
                this.securityDepositPercent = Number(rawValue) || 0;
                const rent = Number(this.appliedAnnualRent) || 0;
                this.securityDeposit = (rent * this.securityDepositPercent) / 100;
                break;

            case 'securityDeposit':
                if (rawValue !== undefined && rawValue !== null && rawValue !== '') {
                    this.securityDeposit = Number(rawValue) || 0;
                }
                break;
            case 'ejariFee':
                this.ejariFee = rawValue;
                break;
            case 'offerValidityDays':
                this.offerValidityDays = rawValue;
                break;
            case 'bookingAmount':
                this.bookingAmount = rawValue;
                break;
            case 'PropertyId':
                this.propertyId = rawValue;
                console.log(`propId>>`, this.propertyId)
                break;
            case 'adultCount':
                this.adultCount = rawValue;
                break;
                case 'relatedPartyBloomHolding':
    this.relatedPartyBloomHolding = event.target.checked;
    break;
            case 'childCount':
                this.childCount = rawValue;

            default:
                // any other fields you wired up
                this[fieldName] = event.detail.value;
        }
    }



    async handleSave() {
        if (!this.selectedUnit) {
            this.showToast('Error', 'Please select a unit', 'error');
            return;
        }

        this.isSubmissionLoading = true;

        const leasingData = {
            opportunityId: this.recordId,
            unitId: this.selectedUnit.Id,
            name: this.leasingContractName,
            familyStatus: this.familyStatus,
            currentCondition: this.currentCondition,
            handOverCondition: this.handOverCondition,
            annualRent: this.selectedUnit.LeasingAnnualRent__c,
            appliedAnnualRent: this.appliedAnnualRent,
            leasingStartDate: this.leasingStartDate,
            leasingContractMonths: this.leasingContractMonths,
            leasingEndDate: this.leasingEndDate,
            discountType: this.discountType,
            discountAmount: this.discountAmount,
            discountPercentage: this.combinedDiscountPct,
            rentalAfterDiscount: this.rentalAfterDiscount,
            paymentPlanId: this.selectedPaymentPlanId,
            relatedPartyBloomHolding: this.relatedPartyBloomHolding,
            leasingOfferId: this.selectedLeasingOfferId,
            // securityDeposit: this.securityDeposit,
            securityDeposit: this.securityDeposit,
            securityDepositType: this.securityDepositType,
            securityDepositPercent: this.securityDepositType === 'Percentage' ? this.securityDepositPercent : 0,
            adminFee: this.adminFee,
            ejariFee: this.ejariFee,
            serviceCharge: this.serviceCharge,
            extraChequeFee: this.extraChequeFee,
            fitOutSecurityDeposit: this.fitOutSecurityDeposit,
            remarks: this.remarks,
            // gracePeriod: this.gracePeriod,
            gracePeriod: this.gracePeriod_,
            offerValidityDays: this.offerValidityDays,
            building: this.selectedBuilding,
            project: this.selectedProject,
            projectName: this.projectName,
            bookingAmount : this.bookingAmount,
            propertyId : this.propertyId,
            adultCount : this.adultCount,
            childCount : this.childCount,
            isBloomStaff : this.isBloomEmployeeChecked,
            isBloomPartnerStaff : this.isBloomSisterEmployeeChecked
        };
        console.log('leasingData Idnetation  => ' + JSON.stringify(leasingData, null, 2));

        try {
            const leasingContractId = await createLeasingOrder({ inputData: JSON.stringify(leasingData) });
            console.log('leasingContractId----', leasingContractId);

            const childCmp = this.template.querySelector(
                'c-leasing-offer-discount-calculation'
            );
const startDate = new Date(this.leasingStartDate + 'T00:00:00');

const splits = Array.isArray(childCmp?.getSchedule())
    ? childCmp.getSchedule().map(row => {
        const year = Number(row.year);

        const fromDate = new Date(startDate);
        fromDate.setFullYear(fromDate.getFullYear() + (year - 1));

        const toDate = new Date(startDate);
        toDate.setFullYear(toDate.getFullYear() + year);
        toDate.setDate(toDate.getDate() - 1);

        return {
            Year__c: year,
            AnnualRent__c: row.annualRent,
            Escalation__c: row.escalation,
            TotalRent__c: row.totalRent,
            AfterDiscount__c: row.afterDiscount,
            LeasingStartDate__c: this.formatDateLocal(fromDate),
            LeasingEndDate__c: this.formatDateLocal(toDate)
        };
    })
    : [];

            if (splits.length) {
                await saveEscalationSplits({
                    contractId: leasingContractId,
                    splits
                });
            }
            await generatePDF({ contractId: leasingContractId });
            this.isSubmissionLoading = false;
            this.showToast('Success', 'Leasing Contract Created Successfully!', 'success');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: leasingContractId,
                    objectApiName: 'LeasingContract__c',
                    actionName: 'view'
                }
            });
        } catch (error) {
            this.isSubmissionLoading = false;
            this.showToast('Error', 'Failed to create Leasing Contract.', 'error');
            console.error('Error:', error);
            if (error?.body?.message) {
                console.error('Error message:', error.body.message);
            }
        }
    }


    get showRentSchedule() {
        return Number(this.leasingContractMonths_) > 12;
    }

    get showRentalAfterDiscount() {
        return !this.leasingContractMonths
            || Number(this.leasingContractMonths) <= 12;
    }
    handleLoadUnits() {
        const allFieldsValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((isValidSoFar, field) => {
                field.reportValidity();
                return isValidSoFar && field.checkValidity();
            }, true);

        if (!allFieldsValid) {
            this.showToast('Warning', 'Please fill out all required fields.', 'warning');
            return;
        }

        if (this.selectedBuilding) {
            console.log('selectedBuilding ----' + this.selectedBuilding);
            this.fetchUnitDetails();
        } else {
            this.showToast('Warning', 'Please select a building first', 'warning');
        }
    }
    get isNextDisabled() {
        return !this.selectedUnit;
    }
    handleBack() {
        this.currentStep = 'step3'
    }
    handleCancel() {
        this.selectedUnit = []
        this.currentStep = 'step1'
    }
    computeEndDate() {
        if (!this.leasingStartDate) {
            this.leasingEndDate = '';
            return;
        }
        const startDate = new Date(this.leasingStartDate);
        const contractMonths = parseInt(this.leasingContractMonths, 10) || 0;

        // Clone and add months
        const endDate = new Date(startDate);
        endDate.setMonth(endDate.getMonth() + contractMonths);

        // Subtract one day to make it inclusive
        endDate.setDate(endDate.getDate() - 1);

        // Format to YYYY-MM-DD
        this.leasingEndDate = endDate.toISOString().slice(0, 10);
    }

    get securityDepositTypeOptions() {
        return [
            { label: 'Amount', value: 'Amount' },
            { label: 'Percentage', value: 'Percentage' }
        ];
    }

    get isSecurityDepositPercent() {
        return this.securityDepositType === 'Percentage';
    }

    get familyStatusOptions() {
        return [
            { label: 'Family', value: 'Family' },
            { label: 'Individual', value: 'Individual' }
        ];
    }
    handleToggleValueChange(event) {
        const { name, value, type } = event.detail;
        console.log(`Field: ${name}, Value: ${value}, Type: ${type}`);
        if (name === 'DiscountType') {
            this.discountType = type;
            if (type === 'Amount') {
                console.log('In side 737');
                this.discountAmount = value;
                this.discountPercentage = 0;
                this.computeRentalAfterDiscount();
            } else if (type === 'Percentage') {
                this.discountPercentage = value;
                this.discountAmount = 0;
                this.computeRentalAfterDiscount();
            }
        }
    }

    recalcChargesFromApplied() {
        const rent = Number(this.appliedAnnualRent) || 0;
        const rentAfterdiscount = Number(this.rentalAfterDiscount) || 0;

        console.log('at 816   this.projectLocation  : ', this.projectLocation);
        if (!this.rentalAfterDiscount) {
            console.log('at 825  this.rentalAfterDiscount  : ', rentAfterdiscount);
            this.adminFee = (Number(this.adminFeePct) || 0) * rent / 100;
        } else {
            console.log('at 822  this.rentalAfterDiscount  : ', rentAfterdiscount);
            this.adminFee = (Number(this.adminFeePct) || 0) * rentAfterdiscount / 100;
        }

        this.ejariFee = this.projectLocation == 'dubai' ? (Number(this.ejariPct) || 0) : 0;
        this.serviceCharge = (Number(this.serviceChargePct) || 0) *
            (Number(this.selectedUnit?.LeasingUnitSizesqm__c) || 0);
        if (this.selectedUnit?.UnitType__c === 'Apartment') {
            this.securityDeposit = this.apartmentSecDeposit;
        } else {
            this.securityDeposit = this.villaSecDeposit;
        }
        if (this.propertyType == 'Commercial') {
            // this.disableSecurityDeposit = true;
            // this.securityDepositType = 'Amount';
            // //this.securityDeposit = this.appliedAnnualRent * 10 / 100;
            this.securityDeposit = rentAfterdiscount * this.securityDepositePrcntg / 100;
        }
    }

    handleBECheck(event){
        this.isBloomEmployeeChecked = event.target.checked;

        // Optional safety reset
        if (this.isBloomEmployeeChecked) {
            this.isBloomSisterEmployeeChecked = false;
            this.actualsAdminFee = this.adminFee;
            this.actualSecurityDeposite = this.securityDeposit;
            this.securityDeposit = 0;
            this.adminFee = 0;
        }else{
            this.securityDeposit = this.actualSecurityDeposite;
            this.adminFee = this.actualsAdminFee;
        }
    }
    handleBSECheck(event){
        this.isBloomSisterEmployeeChecked = event.target.checked;

        // Optional safety reset
        if (this.isBloomSisterEmployeeChecked) {
            this.isBloomEmployeeChecked = false;
            this.actualsAdminFee = this.adminFee;
            this.actualSecurityDeposite = this.securityDeposit;
            this.securityDeposit = 0;
            this.adminFee = 0;
        }
        else{
            this.securityDeposit = this.actualSecurityDeposite;
            this.adminFee = this.actualsAdminFee;
        }
    }

        formatDateLocal(date) {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}

get isRentValidationBypassed() {
    return this.isBloomEmployeeChecked ||
           this.isBloomSisterEmployeeChecked;
}

}